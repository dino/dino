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

        stream_interactor.get_module(ChatInteraction.IDENTITY).conversation_read.connect((conversation) => {
            Idle.add(() => {if (rows.has_key(conversation)) rows[conversation].mark_read(); return false;});
        });
        stream_interactor.get_module(ChatInteraction.IDENTITY).conversation_unread.connect((conversation) => {
            Idle.add(() => {if (rows.has_key(conversation)) rows[conversation].mark_unread(); return false;});
        });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect((conversation) => {
            Idle.add(() => {add_conversation(conversation); return false;});
        });
        stream_interactor.get_module(MessageManager.IDENTITY).message_received.connect((message, conversation) => {
            Idle.add(() => {on_message_received(message, conversation); return false;});
        });
        stream_interactor.get_module(MessageManager.IDENTITY).message_sent.connect((message, conversation) => {
            Idle.add(() => {on_message_received(message, conversation); return false;});
        });
        stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect((show, jid, account) => {
            Idle.add(() => {
                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
                if (conversation != null && rows.has_key(conversation)) rows[conversation].on_show_received(show);
                return false;
            });
        });
        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
            Idle.add(() => {
                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
                if (conversation != null && rows.has_key(conversation)) {
                    ChatRow row = rows[conversation] as ChatRow;
                    if (row != null) row.on_updated_roster_item(roster_item);
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
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            Idle.add(() => {
                foreach (ConversationRow row in rows.values) {
                    if (row.conversation.account.equals(account)) row.network_connection(state == ConnectionManager.ConnectionState.CONNECTED);
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
            } else {
                row = new ChatRow(stream_interactor, conversation);
            }
            rows[conversation] = row;
            add(row);
            row.closed.connect(() => { select_next_conversation(conversation); });
            row.disappeared.connect(() => { remove_conversation(conversation); });
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
                    row_activated(index_p1);
                }
            }
        }
    }

    private void remove_conversation(Conversation conversation) {
        if (rows.has_key(conversation) && !conversation.active) {
            remove(rows[conversation]);
            rows.unset(conversation);
        }
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