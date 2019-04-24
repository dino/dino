using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui {

public class ConversationSelector : ListBox {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private string[]? filter_values;
    private HashMap<Conversation, ConversationSelectorRow> rows = new HashMap<Conversation, ConversationSelectorRow>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Account, ConversationSelectorAccountSep> seps = new HashMap<Account, ConversationSelectorAccountSep>(Account.hash_func, Account.equals_func);

    public ConversationSelector init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(add_conversation);
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(remove_conversation);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(on_message_received);
        stream_interactor.account_added.connect(add_account);
        stream_interactor.account_removed.connect(remove_account);
        Timeout.add_seconds(60, () => {
            foreach (ConversationSelectorRow row in rows.values) row.update();
            return true;
        });

        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations()) {
            add_conversation(conversation);
        }

        foreach (Account acc in stream_interactor.get_accounts()) {
            add_account(acc);
            stdout.printf("Added account : %s\n", acc.display_name);
        }
        return this;
    }

    construct {
        get_style_context().add_class("sidebar");
        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        realize.connect(() => {
            int i = 0;
            ListBoxRow? list_row = get_row_at_index(i++);
            while (list_row != null) {
                ConversationSelectorRow? first_row = list_row as ConversationSelectorRow;
                if (first_row != null) {
                    select_row(first_row);
                    row_activated(first_row);
                    return;
                }
                list_row = get_row_at_index(i++);
            }
        });
    }

    public override void row_activated(ListBoxRow r) {
        ConversationSelectorRow? row = r as ConversationSelectorRow;
        if (row != null) {
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
            invalidate_sort();
        }
    }

    private void add_conversation(Conversation conversation) {
        ConversationSelectorRow row;
        if (!rows.has_key(conversation)) {
            row = new ConversationSelectorRow(stream_interactor, conversation);
            rows[conversation] = row;
            add(row);
            row.closed.connect(() => { select_fallback_conversation(conversation); });
            row.main_revealer.set_reveal_child(true);
        }
        invalidate_sort();
    }

    private void add_account(Account account) {
        ConversationSelectorAccountSep sep;
        if (!seps.has_key(account)) {
            sep = new ConversationSelectorAccountSep(stream_interactor, account);
            seps[account] = sep;
            add(sep);
            sep.main_revealer.set_reveal_child(true);
        }
        invalidate_sort(); // FIXME check that this works with accounts
    }

    private void select_fallback_conversation(Conversation conversation) {
        if (get_selected_row() == rows[conversation]) {
            int index = rows[conversation].get_index();
            ListBoxRow? next_select_row = get_row_at_index(index + 1);
            if (next_select_row == null) {
                next_select_row = get_row_at_index(index - 1);
            }
            if (next_select_row != null) {
                select_row(next_select_row);
                row_activated(next_select_row);
            }
        }
    }

    private void remove_conversation(Conversation conversation) {
        select_fallback_conversation(conversation);
        if (rows.has_key(conversation) && !conversation.active) {
            remove(rows[conversation]);
            rows.unset(conversation);
        }
    }

    private void remove_account(Account account) {
        if (seps.has_key(account)) {
            remove(seps[account]);
            seps.unset(account);
        }
    }

    public void loop_conversations(bool backwards) {
        int index = get_selected_row().get_index();
        int new_index = ((index + (backwards ? -1 : 1)) + rows.size) % rows.size;
        ListBoxRow? next_select_row = get_row_at_index(new_index);
        if (next_select_row != null) {
            select_row(next_select_row);
            row_activated(next_select_row);
        }
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        } else if (row.get_header() != null && before_row == null) {
            row.set_header(null);
        }
    }

    private bool filter(ListBoxRow r) {
        ConversationSelectorRow? row = r as ConversationSelectorRow;
        if (row != null) {
            if (filter_values != null && filter_values.length != 0) {
                foreach (string filter in filter_values) {
                    if (!(Util.get_conversation_display_name(stream_interactor, row.conversation).down().contains(filter.down()) ||
                            row.conversation.counterpart.to_string().down().contains(filter.down()))) {
                        return false;
                    }
                }
            }
        }
        // ConversationSelectorAccountSep? sep = r as ConversationSelectorAccountSep;
        // if (sep != null) {
        //     return false;
        // }
        return true;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ConversationSelectorRow cr1 = row1 as ConversationSelectorRow;
        ConversationSelectorRow cr2 = row2 as ConversationSelectorRow;
        ConversationSelectorAccountSep s1 = row1 as ConversationSelectorAccountSep;
        ConversationSelectorAccountSep s2 = row2 as ConversationSelectorAccountSep;
        if (cr1 != null && cr2 != null) {
            Conversation c1 = cr1.conversation;
            Conversation c2 = cr2.conversation;
            int comp = c1.account.display_name.collate(c2.account.display_name);
            if (comp != 0) return comp;
            if (c1.last_active == null) return -1;
            if (c2.last_active == null) return 1;
            comp = c2.last_active.compare(c1.last_active);
            if (comp == 0) {
                return Util.get_conversation_display_name(stream_interactor, c1)
                    .collate(Util.get_conversation_display_name(stream_interactor, c2));
            } else {
                return comp;
            }
        } else if (s1 != null && s2 != null) {
            return s1.account.display_name.collate(s2.account.display_name);
        } else if (s1 != null && cr2 != null) {
            int comp = s1.account.display_name.collate(cr2.conversation.account.display_name);
            if (comp == 0) return -1;
            return comp;
        } else if (cr1 != null && s2 != null) {
            int comp = cr1.conversation.account.display_name.collate(s2.account.display_name);
            if (comp == 0) return 1;
            return comp;
        }
        return 0;
    }
}

}
