using Gee;
using Gtk;
using Gdk;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/Dino/conversation_content_view/view.ui")]
public class ConversationView : Widget, Plugins.ConversationItemCollection, Plugins.NotificationCollection {
    private const int MESSAGE_MENU_BOX_OFFSET = -20;

    public Conversation? conversation { get; private set; }

    [GtkChild] public unowned ScrolledWindow scrolled;
    [GtkChild] private unowned Revealer notification_revealer;
    [GtkChild] private unowned Box message_menu_box;
    [GtkChild] private unowned Box notifications;
    [GtkChild] private unowned Box main;
    [GtkChild] private unowned Box main_wrap_box;

    private ArrayList<Widget> action_buttons = new ArrayList<Widget>();
    private Gee.List<Dino.Plugins.MessageAction>? message_actions = null;

    private StreamInteractor stream_interactor;
    private Gee.TreeSet<ContentMetaItem> content_items = new Gee.TreeSet<ContentMetaItem>(compare_content_meta_items);
    private Gee.TreeSet<Plugins.MetaConversationItem> meta_items = new TreeSet<Plugins.MetaConversationItem>(compare_meta_items);
    private Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton> item_item_skeletons = new Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton>();
    private Gee.HashMap<Plugins.MetaConversationItem, Widget> widgets = new Gee.HashMap<Plugins.MetaConversationItem, Widget>();
    private Gee.List<Widget> widget_order = new Gee.ArrayList<Widget>();
    private ContentProvider content_populator;
    private SubscriptionNotitication subscription_notification;

    private double? was_value;
    private double? was_upper;
    private double? was_page_size;

    private Mutex reloading_mutex = Mutex();
    private bool firstLoad = true;
    private bool at_current_content = true;
    private bool reload_messages = true;
    Widget currently_highlighted = null;
    ContentMetaItem? current_meta_item = null;
    double last_y = -1;

    construct {
        this.layout_manager = new BinLayout();
    }

    public ConversationView init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["page-size"].connect(on_upper_notify);
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
        EventControllerMotion main_wrap_motion_events = new EventControllerMotion();
        main_wrap_box.add_controller(main_wrap_motion_events);
        main_wrap_motion_events.leave.connect(on_leave_notify_event);
        main_wrap_motion_events.enter.connect(update_highlight);
        // The buttons of the overlaying message_menu_box may partially overlap the adjacent
        // conversation items. We connect to the main_event_box directly to avoid emitting
        // the pointer motion events as long as the pointer is above the message menu.
        // This ensures that the currently highlighted item remains unchanged when the pointer
        // reaches the overlapping part of a button.
        EventControllerMotion main_motion_events = new EventControllerMotion();
        main.add_controller(main_motion_events);
        main_motion_events.motion.connect(update_highlight);

        // Process touch events and capture phase to allow highlighting a message without cursor
        GestureClick click_controller = new GestureClick();
        click_controller.touch_only = true;
        click_controller.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        main_wrap_box.add_controller(click_controller);
        click_controller.pressed.connect_after((n, x, y) => {
            update_highlight(x, y);
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

    private bool is_highlight_fixed() {
        foreach (Widget widget in action_buttons) {
            MenuButton? menu_button = widget as MenuButton;
            if (menu_button != null && menu_button.popover.visible) return true;

            ToggleButton? toggle_button = widget as ToggleButton;
            if (toggle_button != null && toggle_button.active) return true;
        }
        return false;
    }

    private void on_leave_notify_event() {
        if (is_highlight_fixed()) return;

        if (currently_highlighted != null) {
            currently_highlighted.remove_css_class("highlight");
            currently_highlighted = null;
        }
        message_menu_box.visible = false;
    }

    private void update_highlight(double x, double y) {
        if (is_highlight_fixed()) return;

        if (currently_highlighted != null && (last_y - y).abs() <= 2) {
            return;
        }

        last_y = y;

        // Get widget under pointer
        int h = 0;
        Widget? w = null;
        foreach (Plugins.MetaConversationItem item in meta_items) {
            Widget widget = widgets[item];
            h += widget.get_allocated_height() + widget.margin_top + widget.margin_bottom;
            if (h >= y) {
                w = widget;
                break;
            }
        };

        if (currently_highlighted != null) currently_highlighted.remove_css_class("highlight");

        currently_highlighted = null;
        current_meta_item = null;

        if (w == null) {
            update_message_menu();
            return;
        }

        // Get widget coordinates in main
        double widget_x, widget_y;
        w.translate_coordinates(main, 0, 0, out widget_x, out widget_y);

        // Get MessageItem
        foreach (Plugins.MetaConversationItem item in item_item_skeletons.keys) {
            if (item_item_skeletons[item].get_widget() == w) {
                current_meta_item = item as ContentMetaItem;
            }
        }

        update_message_menu();

        if (current_meta_item != null) {
            // Highlight widget
            currently_highlighted = w;
            currently_highlighted.add_css_class("highlight");

            // Move message menu
            message_menu_box.margin_top = (int)(widget_y + MESSAGE_MENU_BOX_OFFSET);
        }
    }

    private void update_message_menu() {
        if (current_meta_item == null) {
            message_menu_box.visible = false;
            return;
        }

        foreach (Widget widget in action_buttons) {
            message_menu_box.remove(widget);
        }
        action_buttons.clear();

        message_actions = current_meta_item.get_item_actions(Plugins.WidgetType.GTK4);

        if (message_actions != null) {
            message_menu_box.visible = true;

            // Configure as many buttons as we need with the actions for the current meta item
            for (int i = 0; i < message_actions.size; i++) {
                if (message_actions[i].popover != null) {
                    MenuButton button = new MenuButton();
                    button.icon_name = message_actions[i].icon_name;
                    button.set_popover(message_actions[i].popover as Popover);
                    button.tooltip_text = Util.string_if_tooltips_active(message_actions[i].tooltip);
                    action_buttons.add(button);
                }

                if (message_actions[i].callback != null) {
                    var message_action = message_actions[i];
                    Button button = new Button();
                    button.icon_name = message_action.icon_name;
                    button.clicked.connect(() => {
                        message_action.callback(button, current_meta_item, currently_highlighted);
                    });
                    button.tooltip_text = Util.string_if_tooltips_active(message_actions[i].tooltip);
                    action_buttons.add(button);
                }
            }

            foreach (Widget widget in action_buttons) {
                message_menu_box.append(widget);
            }
        } else {
            message_menu_box.visible = false;
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
        if (conversation == this.conversation && at_current_content) {
            // Just make sure we are scrolled down
            if (scrolled.vadjustment.value != scrolled.vadjustment.upper) {
                scroll_animation(scrolled.vadjustment.upper).play();
            }
            return;
        }
        clear();
        initialize_for_conversation_(conversation);
        display_latest();
        at_current_content = true;
        // Scroll to end
        scrolled.vadjustment.value = scrolled.vadjustment.upper;
    }

    private void scroll_and_highlight_item(Plugins.MetaConversationItem target, uint duration = 500) {
        Widget widget = null;
        int h = 0;
        foreach (Plugins.MetaConversationItem item in meta_items) {
            widget = widgets[item];
            if (target == item) {
                break;
            }
            h += widget.get_allocated_height();
        }
        if (widget != widgets[target]) {
            warning("Target item widget not reached");
            return;
        }
        double target_height = h - scrolled.vadjustment.page_size * 1/3;
        Adw.Animation animation = scroll_animation(target_height);
        animation.done.connect(() => {
            widget.remove_css_class("highlight-once");
            widget.add_css_class("highlight-once");
            Timeout.add(5000, () => {
                widget.remove_css_class("highlight-once");
                return false;
            });
        });
        animation.play();
    }

    private Adw.Animation scroll_animation(double target) {
#if ADW_1_2
        return new Adw.TimedAnimation(scrolled, scrolled.vadjustment.value, target, 500,
                new Adw.PropertyAnimationTarget(scrolled.vadjustment, "value")
        );
#else
        return new Adw.TimedAnimation(scrolled, scrolled.vadjustment.value, target, 500,
                new Adw.CallbackAnimationTarget(value => {
                    scrolled.vadjustment.value = value;
                })
        );
#endif

    }

    public void initialize_around_message(Conversation conversation, ContentItem content_item) {
        if (conversation == this.conversation) {
            ContentMetaItem? matching_item = content_items.first_match(it => it.content_item.id == content_item.id);
            if (matching_item != null) {
                scroll_and_highlight_item(matching_item);
                return;
            }
        }
        clear();
        initialize_for_conversation_(conversation);
        Gee.List<ContentMetaItem> before_items = content_populator.populate_before(conversation, content_item, 40);
        foreach (ContentMetaItem item in before_items) {
            do_insert_item(item);
        }
        ContentMetaItem meta_item = content_populator.get_content_meta_item(content_item);
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
            scroll_and_highlight_item(meta_item, 300);
            reload_messages = true;
            return false;
        });
    }

    private void initialize_for_conversation_(Conversation? conversation) {
        if (this.conversation == conversation) {
            print("Re-initialized for %s\n", conversation.counterpart.bare_jid.to_string());
        }
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
            populator.init(conversation, this, Plugins.WidgetType.GTK4);
        }
        content_populator.init(this, conversation, Plugins.WidgetType.GTK4);
        subscription_notification.init(conversation, this);
    }

    private void display_latest() {
        Gee.List<ContentMetaItem> items = content_populator.populate_latest(conversation, 40);
        foreach (ContentMetaItem item in items) {
            do_insert_item(item);
        }
        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK4);
        }
        Idle.add(() => { on_value_notify(); return false; });
    }

    public void insert_item(Plugins.MetaConversationItem item) {
        if (meta_items.size > 0) {
            bool after_last = meta_items.last().time.compare(item.time) <= 0;
            bool within_range = meta_items.last().time.compare(item.time) > 0 && meta_items.first().time.compare(item.time) < 0;
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
            if (item is ContentMetaItem) {
                content_items.add((ContentMetaItem)item);
            }
            meta_items.add(item);
        }

        inserted_item(item);
    }

    private void remove_item(Plugins.MetaConversationItem item) {
        ConversationItemSkeleton? skeleton = item_item_skeletons[item];
        if (skeleton != null) {
            main.remove(skeleton.get_widget());
            widgets.unset(item);
            widget_order.remove(skeleton.get_widget());
            item_item_skeletons.unset(item);

            if (item is ContentMetaItem) {
                content_items.remove((ContentMetaItem)item);
            }
            meta_items.remove(item);
        }

        removed_item(item);
    }

    public void on_add_meta_notification(Plugins.MetaConversationNotification notification) {
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK4);
        if (widget != null) {
            add_notification(widget);
        }
    }

    public void on_remove_meta_notification(Plugins.MetaConversationNotification notification){
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK4);
        if (widget != null) {
            remove_notification(widget);
        }
    }

    public void add_notification(Widget widget) {
        notifications.append(widget);
        Timeout.add(20, () => {
            notification_revealer.transition_duration = 200;
            notification_revealer.reveal_child = true;
            return false;
        });
    }

    public void remove_notification(Widget widget) {
        notification_revealer.reveal_child = false;
        notifications.remove(widget);
    }

    private Widget insert_new(Plugins.MetaConversationItem item) {
        Plugins.MetaConversationItem? lower_item = meta_items.lower(item);

        // Fill datastructure
        ConversationItemSkeleton item_skeleton = new ConversationItemSkeleton(stream_interactor, conversation, item);
        item_item_skeletons[item] = item_skeleton;
        int index = lower_item != null ? widget_order.index_of(item_item_skeletons[lower_item].get_widget()) + 1 : 0;
        widget_order.insert(index, item_skeleton.get_widget());

        // Insert widget
        widgets[item] = item_skeleton.get_widget();
        widgets[item].insert_after(main, item_item_skeletons.has_key(lower_item) ? item_item_skeletons[lower_item].get_widget() : null);

        if (lower_item != null) {
            if (can_merge(item, lower_item)) {
                item_skeleton.show_skeleton = false;
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
            if (widget_order.size == 1) {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.time, new DateTime.now_utc());
                }
            } else {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.time, meta_items.higher(item).time);
                }
            }
        }
        return item_skeleton.get_widget();
    }

    private bool can_merge(Plugins.MetaConversationItem upper_item /*more recent, displayed below*/, Plugins.MetaConversationItem lower_item /*less recent, displayed above*/) {
        return upper_item.time != null && lower_item.time != null &&
            upper_item.time.difference(lower_item.time) < TimeSpan.MINUTE &&
            upper_item.jid != null && lower_item.jid != null &&
            upper_item.jid.equals(lower_item.jid) &&
            upper_item.encryption == lower_item.encryption &&
            (upper_item.mark == Message.Marked.WONTSEND) == (lower_item.mark == Message.Marked.WONTSEND);
    }

    private void on_action_button_clicked(ToggleButton button) {
        int button_idx = action_buttons.index_of(button);
        print(button_idx.to_string() + "\n");
        Plugins.MessageAction message_action = message_actions[button_idx];
        if (message_action.callback != null) {
            message_action.callback(button, current_meta_item, currently_highlighted);
        }
    }

    private void on_upper_notify() {
        if (was_upper == null || scrolled.vadjustment.value >  was_upper - was_page_size - 1) { // scrolled down or content smaller than page size
            if (at_current_content) {
                Idle.add(() => {
                    // If we do this directly without Idle.add, scrolling down doesn't work properly
                    scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size; // scroll down
                    return false;
                });
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
            Gee.List<ContentMetaItem> items = content_populator.populate_before(conversation, ((ContentMetaItem) content_items.first()).content_item, 20);
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
            Gee.List<ContentMetaItem> items = content_populator.populate_after(conversation, ((ContentMetaItem) content_items.last()).content_item, 20);
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

    private static int compare_content_meta_items(ContentMetaItem a, ContentMetaItem b) {
        return compare_meta_items(a, b);
    }

    private static int compare_meta_items(Plugins.MetaConversationItem a, Plugins.MetaConversationItem b) {
        int cmp1 = a.time.compare(b.time);
        if (cmp1 != 0) return cmp1;

        return a.secondary_sort_indicator - b.secondary_sort_indicator;
    }

    private void clear() {
        was_upper = null;
        was_page_size = null;
        content_items.clear();
        meta_items.clear();
        widget_order.clear();
        item_item_skeletons.clear();
        foreach (Widget widget in widgets.values) {
            main.remove(widget);
        }
        widgets.clear();
    }

    private void clear_notifications() {
//        notifications.@foreach((widget) => { notifications.remove(widget); });
        notification_revealer.transition_duration = 0;
        notification_revealer.set_reveal_child(false);
    }
}

}
