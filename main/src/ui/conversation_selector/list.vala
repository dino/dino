using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class List : ListBox {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private string[]? filter_values;
    private HashMap<Conversation, ConversationRow> rows = new HashMap<Conversation, ConversationRow>(Conversation.hash_func, Conversation.equals_func);

    public List(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        get_style_context().add_class("sidebar");
        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect((conversation) => {
            Idle.add(() => { add_conversation(conversation); return false; });
        });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect((conversation) => {
            Idle.add(() => { remove_conversation(conversation); return false; });
        });
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect((message, conversation) => {
            Idle.add(() => { on_message_received(message, conversation); return false; });
        });
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect((message, conversation) => {
            Idle.add(() => { on_message_received(message, conversation); return false; });
        });
        stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect((show, jid, account) => {
            Idle.add(() => {
                foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_conversations_for_presence(show, account)) {
                    if (rows.has_key(conversation)) rows[conversation].on_show_received(show);
                }
                return false;
            });
        });
        stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect((avatar, jid, account) => {
            Idle.add(() => {
                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
                if (conversation != null && rows.has_key(conversation)) {
                    ChatRow row = rows[conversation] as ChatRow;
                    if (row != null) row.update_avatar();
                }
                return false;
            });
        });
        Timeout.add_seconds(60, () => {
            foreach (ConversationRow row in rows.values) row.update();
            return true;
        });

        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations()) {
            add_conversation(conversation);
        }
        realize.connect(() => {
            ListBoxRow? first_row = get_row_at_index(0);
            if (first_row != null) {
                select_row(first_row);
                row_activated(first_row);
            }
        });

        Util.Shortcuts.singleton.enable_action("close_conversation").activate.connect(() => {
            ((ConversationRow) get_selected_row()).close_conversation();
        });
        Util.Shortcuts.singleton.enable_action("switch_conversations_down").activate.connect(() => {
            ListBoxRow selected = get_selected_row();
            bool found = false;
            foreach (ListBoxRow row in get_visible_rows()) {
                if (found) {
                    row.activate();
                    return;
                }
                if (row == selected)
                    found = true;
            }
        });
        Util.Shortcuts.singleton.enable_action("switch_conversations_up").activate.connect(() => {
            ListBoxRow selected = get_selected_row();
            ListBoxRow previous = null;
            foreach (ListBoxRow row in get_visible_rows()) {
                if (row == selected) {
                    if (previous != null)
                        previous.activate();
                    return;
                }
                previous = row;
            }
        });
        Util.Shortcuts.singleton.enable_action("switch_conversations_1").activate.connect(() => { select_visible_row(1); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_2").activate.connect(() => { select_visible_row(2); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_3").activate.connect(() => { select_visible_row(3); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_4").activate.connect(() => { select_visible_row(4); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_5").activate.connect(() => { select_visible_row(5); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_6").activate.connect(() => { select_visible_row(6); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_7").activate.connect(() => { select_visible_row(7); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_8").activate.connect(() => { select_visible_row(8); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_9").activate.connect(() => { select_visible_row(9); });
        Util.Shortcuts.singleton.enable_action("switch_conversations_0").activate.connect(() => {
            unowned GLib.List<ListBoxRow> first = get_visible_rows().first();
            if (first != null)
                first.data.activate();
        });
    }

    public override void row_activated(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ConversationRow))) {
            ConversationRow row = r as ConversationRow;
            conversation_selected(row.conversation);
        }
    }

    public void set_filter_values(string[]? values) {
        if (filter_values == values) {
            return;
        }
        filter_values = values;
        invalidate_filter();
    }

    public void on_conversation_selected(Conversation conversation) {
        if (!rows.has_key(conversation)) {
            add_conversation(conversation);
        }
        this.select_row(rows[conversation]);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (rows.has_key(conversation)) {
            rows[conversation].message_received(message);
            invalidate_sort();
        }
    }

    private void add_conversation(Conversation conversation) {
        ConversationRow row;
        if (!rows.has_key(conversation)) {
            if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                row = new GroupchatRow(stream_interactor, conversation);
            } else if (conversation.type_ == Conversation.Type.GROUPCHAT_PM){
                row = new GroupchatPmRow(stream_interactor, conversation);
            } else {
                row = new ChatRow(stream_interactor, conversation);
            }
            rows[conversation] = row;
            add(row);
            row.closed.connect(() => { select_next_conversation(conversation); });
            row.main_revealer.set_reveal_child(true);
        }
        invalidate_sort();
    }

    private void select_next_conversation(Conversation conversation) {
        if (get_selected_row() == rows[conversation]) {
            int index = rows[conversation].get_index();
            ListBoxRow? index_p1 = get_row_at_index(index + 1);
            if (index_p1 != null) {
                select_row(index_p1);
                row_activated(index_p1);
            } else if (index > 0) {
                ListBoxRow? index_m1 = get_row_at_index(index - 1);
                if (index_m1 != null) {
                    select_row(index_m1);
                    row_activated(index_m1);
                }
            }
        }
    }

    private void remove_conversation(Conversation conversation) {
        select_next_conversation(conversation);
        if (rows.has_key(conversation) && !conversation.active) {
            remove(rows[conversation]);
            rows.unset(conversation);
        }
    }

    private GLib.List<ListBoxRow> get_visible_rows() {
        GLib.List<ListBoxRow> visible_rows = new GLib.List<ListBoxRow>();
        foreach (Widget row in get_children()) {
            if (filter((ListBoxRow) row))
                visible_rows.append((ListBoxRow) row);
        }
        return visible_rows;
    }

    private void select_visible_row(uint nr) {
        GLib.List<ListBoxRow> rows = get_visible_rows();
        if (rows.length() >= nr)
            rows.nth(rows.length() - nr).data.activate();
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private bool filter(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ConversationRow))) {
            ConversationRow row = r as ConversationRow;
            if (filter_values != null && filter_values.length != 0) {
                foreach (string filter in filter_values) {
                    if (!(Util.get_conversation_display_name(stream_interactor, row.conversation).down().contains(filter.down()) ||
                            row.conversation.counterpart.to_string().down().contains(filter.down()))) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ConversationRow cr1 = row1 as ConversationRow;
        ConversationRow cr2 = row2 as ConversationRow;
        if (cr1 != null && cr2 != null) {
            Conversation c1 = cr1.conversation;
            Conversation c2 = cr2.conversation;
            if (c1.last_active == null) return -1;
            if (c2.last_active == null) return 1;
            int comp = c2.last_active.compare(c1.last_active);
            if (comp == 0) {
                return Util.get_conversation_display_name(stream_interactor, c1)
                    .collate(Util.get_conversation_display_name(stream_interactor, c2));
            } else {
                return comp;
            }
        }
        return 0;
    }
}

}
