using Gee;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/Dino/conversation_summary/view.ui")]
public class ConversationView : Box, Plugins.ConversationItemCollection {

    public Conversation? conversation { get; private set; }

    [GtkChild] public ScrolledWindow scrolled;
    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Box notifications;
    [GtkChild] private Box main;
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

    public ConversationView init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["value"].connect(on_value_notify);

        content_populator = new ContentProvider(stream_interactor);
        subscription_notification = new SubscriptionNotitication(stream_interactor);

        insert_item.connect(filter_insert_item);
        remove_item.connect(do_remove_item);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_conversation_addition_populator(new ChatStatePopulator(stream_interactor));
        app.plugin_registry.register_conversation_addition_populator(new DateSeparatorPopulator(stream_interactor));

        Timeout.add_seconds(60, () => {
            foreach (ConversationItemSkeleton item_skeleton in item_skeletons) {
                item_skeleton.update_time();
            }
            return true;
        });

        return this;
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
        {
            int h = 0, i = 0;
            main.@foreach((widget) => {
                if (i >= before_items.size) return;
                ConversationItemSkeleton? sk = widget as ConversationItemSkeleton;
                i += sk != null ? sk.items.size : 1;
                int minimum_height, natural_height;
                widget.get_preferred_height_for_width(main.get_allocated_width() - 2 * main.margin, out minimum_height, out natural_height);
                h += minimum_height + 15;
            });
        }

        reload_messages = false;
        Timeout.add(700, () => {
            int h = 0, i = 0;
            main.@foreach((widget) => {
                if (i >= before_items.size) return;
                ConversationItemSkeleton? sk = widget as ConversationItemSkeleton;
                i += sk != null ? sk.items.size : 1;
                h += widget.get_allocated_height() + 15;
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
        clear();

        Gee.List<ContentMetaItem> items = content_populator.populate_latest(conversation, 40);
        foreach (ContentMetaItem item in items) {
            do_insert_item(item);
        }
        Idle.add(() => { on_value_notify(); return false; });
    }

    public void filter_insert_item(Plugins.MetaConversationItem item) {
        if (meta_items.size > 0) {
            bool after_last = meta_items.last().sort_time.compare(item.sort_time) < 0;
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
            if (!item.can_merge || !merge_back(item)) {
                insert_new(item);
            }
        }
        if (item as ContentMetaItem != null) {
            content_items.add(item);
        }
        meta_items.add(item);
    }

    private void do_remove_item(Plugins.MetaConversationItem item) {
        ConversationItemSkeleton? skeleton = item_item_skeletons[item];
        if (skeleton != null) {
            if (skeleton.items.size > 1) {
                skeleton.remove_meta_item(item);
            } else {
                widgets[item].destroy();
                widgets.unset(item);
                skeleton.destroy();
                item_skeletons.remove(skeleton);
                item_item_skeletons.unset(item);
            }
            content_items.remove(item);
            meta_items.remove(item);
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

                widgets[item] = widgets[lower_start_item];
                item_item_skeletons[item] = lower_skeleton;

                return true;
            }
        }
        return false;
    }

    private Widget insert_new(Plugins.MetaConversationItem item) {
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
        main.reorder_child(insert, index);

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
        return insert;
    }

    private void split_at_time(ConversationItemSkeleton split_skeleton, DateTime time) {
        bool already_divided = false;
        int i = 0;
        while(i < split_skeleton.items.size) {
            Plugins.MetaConversationItem meta_item = split_skeleton.items[i];
            if (time.compare(meta_item.display_time) < 0) {
                do_remove_item(meta_item);
                if (!already_divided) {
                    insert_new(meta_item);
                    already_divided = true;
                } else {
                    do_insert_item(meta_item);
                }
            }
            i++;
        }
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
        if (meta_items.size > 0) {
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
        if (meta_items.size > 0 && !at_current_content) {
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
        int res = a.sort_time.compare(b.sort_time);
        if (res == 0) {
            if (a.seccondary_sort_indicator < b.seccondary_sort_indicator) {
                res = -1;
            } else if (a.seccondary_sort_indicator > b.seccondary_sort_indicator) {
                res = 1;
            }
        }
        return res;
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
