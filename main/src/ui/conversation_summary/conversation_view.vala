using Gee;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/Dino/conversation_summary/view.ui")]
public class ConversationView : Box, Plugins.ConversationItemCollection, Plugins.NotificationCollection {

    public Conversation? conversation { get; private set; }

    [GtkChild] private ScrolledWindow scrolled;
    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Box notifications;
    [GtkChild] private Box main;
    [GtkChild] private Stack stack;

    private StreamInteractor stream_interactor;
    private Gee.TreeSet<Plugins.MetaConversationItem> meta_items = new TreeSet<Plugins.MetaConversationItem>(sort_meta_items);
    private Gee.Map<Plugins.MetaConversationItem, Gee.List<Plugins.MetaConversationItem>> meta_after_items = new Gee.HashMap<Plugins.MetaConversationItem, Gee.List<Plugins.MetaConversationItem>>();
    private Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton> item_item_skeletons = new Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton>();
    private Gee.HashMap<Plugins.MetaConversationItem, Widget> widgets = new Gee.HashMap<Plugins.MetaConversationItem, Widget>();
    private Gee.List<ConversationItemSkeleton> item_skeletons = new Gee.ArrayList<ConversationItemSkeleton>();
    private MessagePopulator message_item_populator;
    private SubscriptionNotitication subscription_notification;

    private double? was_value;
    private double? was_upper;
    private double? was_page_size;

    private Mutex reloading_mutex = Mutex();
    private bool animate = false;
    private bool firstLoad = true;

    public ConversationView(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["value"].connect(on_value_notify);

        message_item_populator = new MessagePopulator(stream_interactor);
        subscription_notification = new SubscriptionNotitication(stream_interactor);

        insert_item.connect(on_insert_item);
        remove_item.connect(on_remove_item);
        add_meta_notification.connect(on_add_meta_notification);
        remove_meta_notification.connect(on_remove_meta_notification);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_conversation_item_populator(new ChatStatePopulator(stream_interactor));
        app.plugin_registry.register_conversation_item_populator(new FilePopulator(stream_interactor));
        app.plugin_registry.register_conversation_item_populator(new DateSeparatorPopulator(stream_interactor));

        Timeout.add_seconds(60, () => {
            foreach (ConversationItemSkeleton item_skeleton in item_skeletons) {
                item_skeleton.update_time();
            }
            return true;
        });

        Util.force_base_background(this);
    }

    // Workaround GTK TextView issues: Delay first load of contents
    public void initialize_for_conversation(Conversation? conversation) {
        if (firstLoad) {
            int timeout = firstLoad ? 1000 : 0;
            Timeout.add(timeout, () => {
                initialize_for_conversation_(conversation);
                return false;
            });
            firstLoad = false;
        } else {
            initialize_for_conversation_(conversation);
        }

    }

    private void initialize_for_conversation_(Conversation? conversation) {
        Dino.Application app = Dino.Application.get_default();
        if (this.conversation != null) {
            foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_item_populators) {
                populator.close(conversation);
            }
            foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
                populator.close(conversation);
            }
        }
        this.conversation = conversation;
        stack.set_visible_child_name("void");
        clear();
        was_upper = null;
        was_page_size = null;
        animate = false;
        Timeout.add(20, () => { animate = true; return false; });

        foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_item_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK);
        }
        foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK);
        }
        message_item_populator.init(conversation, this);
        message_item_populator.populate_latest(conversation, 40);
        Idle.add(() => { on_value_notify(); return false; });

        subscription_notification.init(conversation, this);

        stack.set_visible_child_name("main");
    }

    public void on_insert_item(Plugins.MetaConversationItem item) {
        lock (meta_items) {
            if (!item.can_merge || !merge_back(item)) {
                insert_new(item);
            }
        }
    }

    public void on_remove_item(Plugins.MetaConversationItem item) {
        lock (meta_items) {
            ConversationItemSkeleton? skeleton = item_item_skeletons[item];
            if (skeleton.items.size > 1) {
                skeleton.remove_meta_item(item);
            } else {
                widgets[item].destroy();
                widgets.unset(item);
                skeleton.destroy();
                item_skeletons.remove(skeleton);
                item_item_skeletons.unset(item);
            }
            meta_items.remove(item);
        }
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

    private bool merge_back(Plugins.MetaConversationItem item) {
        Plugins.MetaConversationItem? lower_item = meta_items.lower(item);
        if (lower_item != null) {
            ConversationItemSkeleton lower_skeleton = item_item_skeletons[lower_item];
            Plugins.MetaConversationItem lower_start_item = lower_skeleton.items[0];
            if (lower_start_item.can_merge &&
                    item.display_time.difference(lower_start_item.display_time) < TimeSpan.MINUTE &&
                    lower_start_item.jid.equals(item.jid) &&
                    lower_start_item.encryption == item.encryption &&
                    (item.mark == Message.Marked.WONTSEND) == (lower_start_item.mark == Message.Marked.WONTSEND)) {
                lower_skeleton.add_meta_item(item);
                force_alloc_width(lower_skeleton, main.get_allocated_width());

                item_item_skeletons[item] = lower_skeleton;
                meta_items.add(item);

                return true;
            }
        }
        return false;
    }

    private void insert_new(Plugins.MetaConversationItem item) {
        Plugins.MetaConversationItem? lower_item = meta_items.lower(item);

        // Does another skeleton need to be split?
        if (lower_item != null) {
            ConversationItemSkeleton lower_skeleton = item_item_skeletons[lower_item];
            if (lower_skeleton.items.size > 1) {
                Plugins.MetaConversationItem lower_end_item = lower_skeleton.items[lower_skeleton.items.size - 1];
                if (item.sort_time.compare(lower_end_item.sort_time) < 0) {
                    split_at_time(lower_skeleton, item.sort_time);
                }
            }
        }

        // Fill datastructure
        ConversationItemSkeleton item_skeleton = new ConversationItemSkeleton(stream_interactor, conversation, item) { visible=true };
        item_item_skeletons[item] = item_skeleton;
        int index = lower_item != null ? item_skeletons.index_of(item_item_skeletons[lower_item]) + 1 : 0;
        item_skeletons.insert(index, item_skeleton);
        meta_items.add(item);

        // Insert widget
        Widget insert = item_skeleton;
        if (animate) {
            Revealer revealer = new Revealer() {transition_duration = 200, transition_type = RevealerTransitionType.SLIDE_UP, visible = true};
            revealer.add(item_skeleton);
            insert = revealer;
            main.add(insert);
            revealer.reveal_child = true;
        } else {
            main.add(insert);
        }
        widgets[item] = insert;
        force_alloc_width(insert, main.get_allocated_width());
        main.reorder_child(insert, index);

        // If an item from the past was added, add everything between that item and the (post-)first present item
        if (index == 0) {
            Dino.Application app = Dino.Application.get_default();
            if (item_skeletons.size == 1) {
                foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_item_populators) {
                    populator.populate_timespan(conversation, item.sort_time, new DateTime.now_utc());
                }
            } else {
                foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_item_populators) {
                    populator.populate_timespan(conversation, item.sort_time, meta_items.higher(item).sort_time);
                }
            }
        }
    }

    private void split_at_time(ConversationItemSkeleton split_skeleton, DateTime time) {
        bool already_divided = false;
        int i = 0;
        while(i < split_skeleton.items.size) {
            Plugins.MetaConversationItem meta_item = split_skeleton.items[i];
            if (time.compare(meta_item.display_time) < 0) {
                remove_item(meta_item);
                if (!already_divided) {
                    insert_new(meta_item);
                    already_divided = true;
                } else {
                    insert_item(meta_item);
                }
            }
            i++;
        }
    }

    private void on_upper_notify() {
        if (was_upper == null || scrolled.vadjustment.value >  was_upper - was_page_size - 1 ||
                scrolled.vadjustment.value >  was_upper - was_page_size - 1) { // scrolled down or content smaller than page size
            scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size; // scroll down
        } else if (scrolled.vadjustment.value < scrolled.vadjustment.upper - scrolled.vadjustment.page_size - 1) {
            scrolled.vadjustment.value = scrolled.vadjustment.upper - was_upper + scrolled.vadjustment.value; // stay at same content
        }
        was_upper = scrolled.vadjustment.upper;
        was_page_size = scrolled.vadjustment.page_size;
        reloading_mutex.trylock();
        reloading_mutex.unlock();
    }

    private void on_value_notify() {
        if (scrolled.vadjustment.value < 200) {
            load_earlier_messages();
        }
    }

    private void load_earlier_messages() {
        was_value = scrolled.vadjustment.value;
        if (!reloading_mutex.trylock()) return;
        if (meta_items.size > 0) message_item_populator.populate_before(conversation, meta_items.first(), 20);
    }

    private static int sort_meta_items(Plugins.MetaConversationItem a, Plugins.MetaConversationItem b) {
        int res = a.sort_time.compare(b.sort_time);
        if (res == 0) {
            if (a.seccondary_sort_indicator < b.seccondary_sort_indicator) res = -1;
            else if (a.seccondary_sort_indicator > b.seccondary_sort_indicator) res = 1;
        }
        return res;
    }

    // Workaround GTK TextView issues
    private void force_alloc_width(Widget widget, int width) {
        Allocation alloc = Allocation();
        widget.get_preferred_width(out alloc.width, null);
        widget.get_preferred_height(out alloc.height, null);
        alloc.width = width;
        widget.size_allocate(alloc);
    }

    private void clear() {
        meta_items.clear();
        meta_after_items.clear();
        item_skeletons.clear();
        item_item_skeletons.clear();
        widgets.clear();
        main.@foreach((widget) => { widget.destroy(); });
        notifications.@foreach((widget) => { widget.destroy(); });
        notification_revealer.transition_duration = 0;
        notification_revealer.set_reveal_child(false);
    }
}

}
