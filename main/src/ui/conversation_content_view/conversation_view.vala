using Gee;
using Gtk;
using Gdk;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/Dino/conversation_content_view/view.ui")]
public class ConversationView : Box, Plugins.ConversationItemCollection, Plugins.NotificationCollection {

    public Conversation? conversation { get; private set; }

    [GtkChild] public ScrolledWindow scrolled;
    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Box message_menu_box;
    [GtkChild] private Button button1;
    [GtkChild] private Image button1_icon;
    [GtkChild] private Box notifications;
    [GtkChild] private Box main;
    [GtkChild] private EventBox main_event_box;
    [GtkChild] private EventBox main_wrap_event_box;
    [GtkChild] private Stack stack;

    private StreamInteractor stream_interactor;
    private Gee.TreeSet<Plugins.MetaConversationItem> content_items = new Gee.TreeSet<Plugins.MetaConversationItem>(compare_meta_items);
    private Gee.TreeSet<Plugins.MetaConversationItem> meta_items = new TreeSet<Plugins.MetaConversationItem>(compare_meta_items);
    private Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton> item_item_skeletons = new Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton>();
    private Gee.HashMap<Plugins.MetaConversationItem, Widget> widgets = new Gee.HashMap<Plugins.MetaConversationItem, Widget>();
    private Gee.List<ConversationItemSkeleton> item_skeletons = new Gee.ArrayList<ConversationItemSkeleton>();
    private ContentProvider content_populator;
    private SubscriptionNotitication subscription_notification;

    private double? was_value;
    private double? was_upper;
    private double? was_page_size;

    private Mutex reloading_mutex = Mutex();
    private bool animate = false;
    private bool firstLoad = true;
    private bool at_current_content = true;
    private bool reload_messages = true;
    ConversationItemSkeleton currently_highlighted = null;
    ContentMetaItem? current_meta_item = null;
    int last_y_root = -1;

    public ConversationView init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["value"].connect(on_value_notify);

        content_populator = new ContentProvider(stream_interactor);
        subscription_notification = new SubscriptionNotitication(stream_interactor);

        add_meta_notification.connect(on_add_meta_notification);
        remove_meta_notification.connect(on_remove_meta_notification);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_conversation_addition_populator(new ChatStatePopulator(stream_interactor));
        app.plugin_registry.register_conversation_addition_populator(new DateSeparatorPopulator(stream_interactor));

        // Rather than connecting to the leave event of the main_event_box directly,
        // we connect to the parent event box that also wraps the overlaying message_menu_box.
        // This eliminates the unwanted leave events emitted on the main_event_box when hovering
        // the overlaying menu buttons.
        main_wrap_event_box.events = EventMask.ENTER_NOTIFY_MASK;
        main_wrap_event_box.events = EventMask.LEAVE_NOTIFY_MASK;
        main_wrap_event_box.leave_notify_event.connect(on_leave_notify_event);
        main_wrap_event_box.enter_notify_event.connect(on_enter_notify_event);
        // The buttons of the overlaying message_menu_box may partially overlap the adjacent
        // conversation items. We connect to the main_event_box directly to avoid emitting
        // the pointer motion events as long as the pointer is above the message menu.
        // This ensures that the currently highlighted item remains unchanged when the pointer
        // reaches the overlapping part of a button.
        main_event_box.events = EventMask.POINTER_MOTION_MASK;
        main_event_box.motion_notify_event.connect(on_motion_notify_event);

        button1.clicked.connect(() => {
            current_meta_item.get_item_actions(Plugins.WidgetType.GTK)[0].callback(button1, current_meta_item, currently_highlighted.widget);
            update_message_menu();
        });

        return this;
    }

    public void activate_last_message_correction() {
        Gee.BidirIterator<Plugins.MetaConversationItem> iter = content_items.bidir_iterator();
        iter.last();
        for (int i = 0; i < 10 && content_items.size > i; i++) {
            Plugins.MetaConversationItem item = iter.get();
            MessageMetaItem message_item = item as MessageMetaItem;
            if (message_item != null) {
                if ((conversation.type_ == Conversation.Type.CHAT && message_item.jid.equals_bare(conversation.account.bare_jid)) ||
                        (conversation.type_ == Conversation.Type.GROUPCHAT &&
                        message_item.jid.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account)))) {
                    message_item.in_edit_mode = true;
                    break;
                }
            }
            iter.previous();
        }
    }

    private bool on_enter_notify_event(Gdk.EventCrossing event) {
        update_highlight((int)event.x_root, (int)event.y_root);
        return false;
    }

    private bool on_leave_notify_event(Gdk.EventCrossing event) {
        if (currently_highlighted != null) {
            currently_highlighted.unset_state_flags(StateFlags.PRELIGHT);
            currently_highlighted = null;
        }
        message_menu_box.visible = false;
        return false;
    }

    private bool on_motion_notify_event(Gdk.EventMotion event) {
        update_highlight((int)event.x_root, (int)event.y_root);
        return false;
    }

    private void update_highlight(int x_root, int y_root) {
        if (currently_highlighted != null && (last_y_root - y_root).abs() <= 2) {
            return;
        }

        last_y_root = y_root;

        int toplevel_window_pos_x, toplevel_window_pos_y, dest_x, dest_y;
        Widget toplevel_widget = this.get_toplevel();
        // Obtain the position of the main application window relative to the root window
        toplevel_widget.get_window().get_origin(out toplevel_window_pos_x, out toplevel_window_pos_y);
        // Get the pointer location relative to the `main` box
        toplevel_widget.translate_coordinates(main, x_root - toplevel_window_pos_x, y_root - toplevel_window_pos_y, out dest_x, out dest_y);

        // Get widget under pointer
        int h = 0;
        ConversationItemSkeleton? w = null;
        foreach (Widget widget in main.get_children()) {
            h += widget.get_allocated_height();
            if (h >= dest_y) {
                w = widget as ConversationItemSkeleton;
                break;
            }
        };

        if (currently_highlighted != null) currently_highlighted.unset_state_flags(StateFlags.PRELIGHT);

        if (w == null) {
            currently_highlighted = null;
            current_meta_item = null;
            update_message_menu();
            return;
        }

        // Get widget coordinates in main
        int widget_x, widget_y;
        w.translate_coordinates(main, 0, 0, out widget_x, out widget_y);

        // Get MessageItem
        foreach (Plugins.MetaConversationItem item in item_item_skeletons.keys) {
            if (item_item_skeletons[item] == w) {
                current_meta_item = item as ContentMetaItem;
            }
        }

        update_message_menu();

        if (current_meta_item != null) {
            // Highlight widget
            w.set_state_flags(StateFlags.PRELIGHT, true);
            currently_highlighted = w;

            // Move message menu
            message_menu_box.margin_top = widget_y - 10;
        }
    }

    private void update_message_menu() {
        if (current_meta_item == null) {
            message_menu_box.visible = false;
            return;
        }

        var actions = current_meta_item.get_item_actions(Plugins.WidgetType.GTK);
        message_menu_box.visible = actions != null && actions.size > 0;
        if (actions != null && actions.size == 1) {
            button1.visible = true;
            button1_icon.set_from_icon_name(actions[0].icon_name, IconSize.SMALL_TOOLBAR);
        }
    }

    public void initialize_for_conversation(Conversation? conversation) {
        // Workaround for rendering issues
        if (firstLoad) {
            main.visible = false;
            Idle.add(() => {
                main.visible=true;
                return false;
            });
            firstLoad = false;
        }
        stack.set_visible_child_name("void");
        clear();
        initialize_for_conversation_(conversation);
        display_latest();
        stack.set_visible_child_name("main");
    }

    public void initialize_around_message(Conversation conversation, ContentItem content_item) {
        stack.set_visible_child_name("void");
        clear();
        initialize_for_conversation_(conversation);
        Gee.List<ContentMetaItem> before_items = content_populator.populate_before(conversation, content_item, 40);
        foreach (ContentMetaItem item in before_items) {
            do_insert_item(item);
        }
        ContentMetaItem meta_item = content_populator.get_content_meta_item(content_item);
        meta_item.can_merge = false;
        Widget w = insert_new(meta_item);
        content_items.add(meta_item);
        meta_items.add(meta_item);

        Gee.List<ContentMetaItem> after_items = content_populator.populate_after(conversation, content_item, 40);
        foreach (ContentMetaItem item in after_items) {
            do_insert_item(item);
        }
        if (after_items.size == 40) {
            at_current_content = false;
        }

        // Compute where to jump to for centered message, jump, highlight.
        reload_messages = false;
        Timeout.add(700, () => {
            int h = 0, i = 0;
            bool @break = false;
            main.@foreach((widget) => {
                if (widget == w || @break) {
                    @break = true;
                    return;
                }
                h += widget.get_allocated_height();
                i++;
            });
            scrolled.vadjustment.value = h - scrolled.vadjustment.page_size * 1/3;
            w.get_style_context().add_class("highlight-once");
            reload_messages = true;
            stack.set_visible_child_name("main");
            return false;
        });
    }

    private void initialize_for_conversation_(Conversation? conversation) {
        // Deinitialize old conversation
        Dino.Application app = Dino.Application.get_default();
        if (this.conversation != null) {
            foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_addition_populators) {
                populator.close(conversation);
            }
            foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
                populator.close(conversation);
            }
        }

        // Clear data structures
        clear_notifications();
        this.conversation = conversation;

        // Init for new conversation
        foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_addition_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK);
        }
        content_populator.init(this, conversation, Plugins.WidgetType.GTK);
        subscription_notification.init(conversation, this);

        animate = false;
        Timeout.add(20, () => { animate = true; return false; });
    }

    private void display_latest() {
        Gee.List<ContentMetaItem> items = content_populator.populate_latest(conversation, 40);
        foreach (ContentMetaItem item in items) {
            do_insert_item(item);
        }
        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK);
        }
        Idle.add(() => { on_value_notify(); return false; });
    }

    public void insert_item(Plugins.MetaConversationItem item) {
        if (meta_items.size > 0) {
            bool after_last = meta_items.last().sort_time.compare(item.sort_time) <= 0;
            bool within_range = meta_items.last().sort_time.compare(item.sort_time) > 0 && meta_items.first().sort_time.compare(item.sort_time) < 0;
            bool accept = within_range || (at_current_content && after_last);
            if (!accept) {
                return;
            }
        }
        do_insert_item(item);
    }

    public void do_insert_item(Plugins.MetaConversationItem item) {
        lock (meta_items) {
            insert_new(item);
            if (item as ContentMetaItem != null) {
                content_items.add(item);
            }
            meta_items.add(item);
        }

        inserted_item(item);
    }

    private void remove_item(Plugins.MetaConversationItem item) {
        ConversationItemSkeleton? skeleton = item_item_skeletons[item];
        if (skeleton != null) {
            widgets[item].destroy();
            widgets.unset(item);
            skeleton.destroy();
            item_skeletons.remove(skeleton);
            item_item_skeletons.unset(item);

            content_items.remove(item);
            meta_items.remove(item);
        }

        removed_item(item);
    }

    public void on_add_meta_notification(Plugins.MetaConversationNotification notification) {
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK);
        if (widget != null) {
            add_notification(widget);
        }
    }

    public void on_remove_meta_notification(Plugins.MetaConversationNotification notification){
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK);
        if (widget != null) {
            remove_notification(widget);
        }
    }

    public void add_notification(Widget widget) {
        notifications.add(widget);
        Timeout.add(20, () => {
            notification_revealer.transition_duration = 200;
            notification_revealer.reveal_child = true;
            return false;
        });
    }

    public void remove_notification(Widget widget) {
        notification_revealer.reveal_child = false;
        widget.destroy();
    }

    private Widget insert_new(Plugins.MetaConversationItem item) {
        Plugins.MetaConversationItem? lower_item = meta_items.lower(item);

        // Fill datastructure
        ConversationItemSkeleton item_skeleton = new ConversationItemSkeleton(stream_interactor, conversation, item, !animate) { visible=true };
        item_item_skeletons[item] = item_skeleton;
        int index = lower_item != null ? item_skeletons.index_of(item_item_skeletons[lower_item]) + 1 : 0;
        item_skeletons.insert(index, item_skeleton);

        // Insert widget
        widgets[item] = item_skeleton;
        main.add(item_skeleton);
        main.reorder_child(item_skeleton, index);

        if (lower_item != null) {
            if (can_merge(item, lower_item)) {
                ConversationItemSkeleton lower_skeleton = item_item_skeletons[lower_item];
                item_skeleton.show_skeleton = false;
                lower_skeleton.last_group_item = false;
            } else {
                item_skeleton.show_skeleton = true;
            }
        } else {
            item_skeleton.show_skeleton = true;
        }

        Plugins.MetaConversationItem? upper_item = meta_items.higher(item);
        if (upper_item != null) {
            if (!can_merge(upper_item, item)) {
                ConversationItemSkeleton upper_skeleton = item_item_skeletons[upper_item];
                upper_skeleton.show_skeleton = true;
            }
        }

        // If an item from the past was added, add everything between that item and the (post-)first present item
        if (index == 0) {
            Dino.Application app = Dino.Application.get_default();
            if (item_skeletons.size == 1) {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.sort_time, new DateTime.now_utc());
                }
            } else {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.sort_time, meta_items.higher(item).sort_time);
                }
            }
        }
        return item_skeleton;
    }

    private bool can_merge(Plugins.MetaConversationItem upper_item /*more recent, displayed below*/, Plugins.MetaConversationItem lower_item /*less recent, displayed above*/) {
        return upper_item.display_time != null && lower_item.display_time != null &&
            upper_item.display_time.difference(lower_item.display_time) < TimeSpan.MINUTE &&
            upper_item.jid.equals(lower_item.jid) &&
            upper_item.encryption == lower_item.encryption &&
            (upper_item.mark == Message.Marked.WONTSEND) == (lower_item.mark == Message.Marked.WONTSEND);
    }

    private void on_upper_notify() {
        if (was_upper == null || scrolled.vadjustment.value >  was_upper - was_page_size - 1) { // scrolled down or content smaller than page size
            if (at_current_content) {
                scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size; // scroll down
            }
        } else if (scrolled.vadjustment.value < scrolled.vadjustment.upper - scrolled.vadjustment.page_size - 1) {
            scrolled.vadjustment.value = scrolled.vadjustment.upper - was_upper + scrolled.vadjustment.value; // stay at same content
        }
        was_upper = scrolled.vadjustment.upper;
        was_page_size = scrolled.vadjustment.page_size;
        was_value = scrolled.vadjustment.value;
        reloading_mutex.trylock();
        reloading_mutex.unlock();
    }

    private void on_value_notify() {
        if (scrolled.vadjustment.value < 400) {
            load_earlier_messages();
        } else if (scrolled.vadjustment.upper - (scrolled.vadjustment.value + scrolled.vadjustment.page_size) < 400) {
            load_later_messages();
        }
    }

    private void load_earlier_messages() {
        was_value = scrolled.vadjustment.value;
        if (!reloading_mutex.trylock()) return;
        if (content_items.size > 0) {
            Gee.List<ContentMetaItem> items = content_populator.populate_before(conversation, (content_items.first() as ContentMetaItem).content_item, 20);
            foreach (ContentMetaItem item in items) {
                do_insert_item(item);
            }
        } else {
            reloading_mutex.unlock();
        }
    }

    private void load_later_messages() {
        if (!reloading_mutex.trylock()) return;
        if (content_items.size > 0 && !at_current_content) {
            Gee.List<ContentMetaItem> items = content_populator.populate_after(conversation, (content_items.last() as ContentMetaItem).content_item, 20);
            if (items.size == 0) {
                at_current_content = true;
            }
            foreach (ContentMetaItem item in items) {
                do_insert_item(item);
            }
        } else {
            reloading_mutex.unlock();
        }
    }

    private static int compare_meta_items(Plugins.MetaConversationItem a, Plugins.MetaConversationItem b) {
        int cmp1 = a.sort_time.compare(b.sort_time);
        if (cmp1 == 0) {
            double cmp2 = a.seccondary_sort_indicator - b.seccondary_sort_indicator;
            if (cmp2 == 0) {
                return (int) (a.tertiary_sort_indicator - b.tertiary_sort_indicator);
            }
            return (int) cmp2;
        }
        return cmp1;
    }

    private void clear() {
        was_upper = null;
        was_page_size = null;
        content_items.clear();
        meta_items.clear();
        item_skeletons.clear();
        item_item_skeletons.clear();
        widgets.clear();
        main.@foreach((widget) => { widget.destroy(); });
    }

    private void clear_notifications() {
        notifications.@foreach((widget) => { widget.destroy(); });
        notification_revealer.transition_duration = 0;
        notification_revealer.set_reveal_child(false);
    }
}

}
