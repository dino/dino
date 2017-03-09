using Gee;
using Gtk;
using Pango;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/org/dino-im/conversation_summary/view.ui")]
public class View : Box {

    public Conversation? conversation { get; private set; }
    public HashMap<Entities.Message, MergedMessageItem> message_items = new HashMap<Entities.Message, MergedMessageItem>(Entities.Message.hash_func, Entities.Message.equals_func);

    [GtkChild]
    private ScrolledWindow scrolled;

    [GtkChild]
    private Box main;

    private StreamInteractor stream_interactor;
    private MergedMessageItem? last_message_item;
    private StatusItem typing_status;
    private Entities.Message? earliest_message;
    double? was_value;
    double? was_upper;
    double? was_page_size;
    Object reloading_lock = new Object();
    bool reloading = false;

    public View(StreamInteractor stream_interactor) {
        Object(homogeneous : false, spacing : 0);
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["value"].connect(on_value_notify);

        CounterpartInteractionManager.get_instance(stream_interactor).received_state.connect((account, jid, state) => {
            Idle.add(() => { on_received_state(account, jid, state); return false; });
        });
        MessageManager.get_instance(stream_interactor).message_received.connect((message, conversation) => {
            Idle.add(() => { show_message(message, conversation, true); return false; });
        });
        MessageManager.get_instance(stream_interactor).message_sent.connect((message, conversation) => {
            Idle.add(() => { show_message(message, conversation, true); return false; });
        });
        PresenceManager.get_instance(stream_interactor).show_received.connect((show, jid, account) => {
            Idle.add(() => { on_show_received(show, jid, account); return false; });
        });
        Timeout.add_seconds(60, () => {
            foreach (MergedMessageItem message_item in message_items.values) {
                message_item.update();
            }
            return true;
        });
    }

    public void initialize_for_conversation(Conversation? conversation) {
        this.conversation = conversation;
        clear();
        message_items.clear();
        was_upper = null;
        was_page_size = null;
        last_message_item = null;

        ArrayList<Object> objects = new ArrayList<Object>();
        Gee.List<Entities.Message>? messages = MessageManager.get_instance(stream_interactor).get_messages(conversation);
        if (messages != null && messages.size > 0) {
            earliest_message = messages[0];
            objects.add_all(messages);
        }
        HashMap<Jid, ArrayList<Show>>? shows = PresenceManager.get_instance(stream_interactor).get_shows(conversation.counterpart, conversation.account);
        if (shows != null) {
            foreach (Jid jid in shows.keys) objects.add_all(shows[jid]);
        }
        objects.sort((a, b) => {
            DateTime? dt1 = null;
            DateTime? dt2 = null;
            Entities.Message m1 = a as Entities.Message;
            if (m1 != null) dt1 = m1.time;
            Show s1 = a as Show;
            if (s1 != null) dt1 = s1.datetime;
            Entities.Message m2 = b as Entities.Message;
            if (m2 != null) dt2 = m2.time;
            Show s2 = b as Show;
            if (s2 != null) dt2 = s2.datetime;
            return dt1.compare(dt2);
        });
        foreach (Object o in objects) {
            Entities.Message message = o as Entities.Message;
            Show show = o as Show;
            if (message != null) {
                show_message(message, conversation);
            } else if (show != null) {
                on_show_received(show, conversation.counterpart, conversation.account);
            }
        }
        update_chat_state();
    }

    private void on_received_state(Account account, Jid jid, string state) {
        if (conversation != null && conversation.account.equals(account) && conversation.counterpart.equals_bare(jid)) {
            update_chat_state(state);
        }
    }

    private void update_chat_state(string? state = null) {
        string? state_ = state;
        if (state_ == null) {
            state_ = CounterpartInteractionManager.get_instance(stream_interactor).get_chat_state(conversation.account, conversation.counterpart);
        }
        if (typing_status != null) {
            main.remove(typing_status);
        }
        if (state_ != null) {
            if (state_ == Xep.ChatStateNotifications.STATE_COMPOSING || state_ == Xep.ChatStateNotifications.STATE_PAUSED) {
                if (state_ == Xep.ChatStateNotifications.STATE_COMPOSING) {
                    typing_status = new StatusItem(stream_interactor, conversation, "is typing...");
                } else if (state_ == Xep.ChatStateNotifications.STATE_PAUSED) {
                    typing_status = new StatusItem(stream_interactor, conversation, "has stoped typing");
                }
                main.add(typing_status);
            }
        }
    }

    private void on_show_received(Show show, Jid jid, Account account) {

    }

    private void on_upper_notify() {
        if (was_upper == null || scrolled.vadjustment.value >  was_upper - was_page_size - 1 ||
                scrolled.vadjustment.value >  was_upper - was_page_size - 1) { // scrolled down or content smaller than page size
            scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size; // scroll down
        } else if (scrolled.vadjustment.value < scrolled.vadjustment.upper - scrolled.vadjustment.page_size - 1){
            scrolled.vadjustment.value = scrolled.vadjustment.upper - was_upper + scrolled.vadjustment.value; // stay at same content
        }
        was_upper = scrolled.vadjustment.upper;
        was_page_size = scrolled.vadjustment.page_size;
        lock(reloading_lock) {
            reloading = false;
        }
    }

    private void on_value_notify() {
        if (scrolled.vadjustment.value < 200) {
            load_earlier_messages();
        }
    }

    private void load_earlier_messages() {
        was_value = scrolled.vadjustment.value;
        lock(reloading_lock) {
            if(reloading) return;
            reloading = true;
        }
        Gee.List<Entities.Message>? messages = MessageManager.get_instance(stream_interactor).get_messages_before(conversation, earliest_message);
        if (messages != null && messages.size > 0) {
            earliest_message = messages[0];
            MergedMessageItem? current_item = null;
            int items_added = 0;
            for (int i = 0; i < messages.size; i++) {
                if (current_item != null && should_merge_message(current_item, messages[i])) {
                    current_item.add_message(messages[i]);
                } else {
                    current_item = new MergedMessageItem(stream_interactor, conversation, messages[i]);
                    force_alloc_width(current_item, main.get_allocated_width());
                    main.add(current_item);
                    message_items[messages[i]] = current_item;
                    main.reorder_child(current_item, items_added);
                    items_added++;
                }
            }
            return;
        }
        reloading = false;
    }

    private void show_message(Entities.Message message, Conversation conversation, bool animate = false) {
        if (this.conversation != null && this.conversation.equals(conversation)) {
            if (should_merge_message(last_message_item, message)) {
                last_message_item.add_message(message);
            } else {
                MergedMessageItem message_item = new MergedMessageItem(stream_interactor, conversation, message);
                if (animate) {
                    Revealer revealer = new Revealer() {transition_duration = 200, transition_type = RevealerTransitionType.SLIDE_UP, visible = true};
                    revealer.add(message_item);
                    force_alloc_width(revealer, main.get_allocated_width());
                    main.add(revealer);
                    revealer.set_reveal_child(true);
                } else {
                    force_alloc_width(message_item, main.get_allocated_width());
                    main.add(message_item);
                }
                last_message_item = message_item;
            }
            message_items[message] = last_message_item;
            update_chat_state();
        }
    }

    private bool should_merge_message(MergedMessageItem? message_item, Entities.Message message) {
        return message_item != null &&
            message_item.from.equals(message.from) &&
            message_item.messages.get(0).encryption == message.encryption &&
            message.time.difference(message_item.initial_time) < TimeSpan.MINUTE &&
            (message_item.messages.get(0).marked == Entities.Message.Marked.WONTSEND) == (message.marked == Entities.Message.Marked.WONTSEND);
    }

    private void force_alloc_width(Widget widget, int width) {
        Allocation alloc = Allocation();
        widget.get_preferred_width(out alloc.width, null);
        widget.get_preferred_height(out alloc.height, null);
        alloc.width = width;
        widget.size_allocate(alloc);
    }

    private void clear() {
        main.@foreach((widget) => { main.remove(widget); });
    }
}
}
