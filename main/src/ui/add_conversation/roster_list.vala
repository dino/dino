using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

protected class RosterList {

    public signal void conversation_selected(Conversation? conversation);
    private StreamInteractor stream_interactor;
    private Gee.List<Account> accounts;
    private ulong[] handler_ids = new ulong[0];

    private ListBox list_box = new ListBox();
    private HashMap<Account, HashMap<Jid, ListBoxRow>> rows = new HashMap<Account, HashMap<Jid, ListBoxRow>>(Account.hash_func, Account.equals_func);

    public RosterList(StreamInteractor stream_interactor, Gee.List<Account> accounts) {
        this.stream_interactor = stream_interactor;
        this.accounts = accounts;

        handler_ids += stream_interactor.get_module(RosterManager.IDENTITY).removed_roster_item.connect( (account, jid, roster_item) => {
            if (accounts.contains(account)) {
                on_removed_roster_item(account, jid, roster_item);
            }
        });
        handler_ids += stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect( (account, jid, roster_item) => {
            if (accounts.contains(account)) {
                on_updated_roster_item(account, jid, roster_item);
            }
        });
        list_box.destroy.connect(() => {
            foreach (ulong handler_id in handler_ids) stream_interactor.get_module(RosterManager.IDENTITY).disconnect(handler_id);
        });

        foreach (Account a in accounts) {
            ListRow own_account_row = new ListRow.from_jid(stream_interactor, a.bare_jid, a, accounts.size > 1);
            ListBoxRow own_account_lbrow = new ListBoxRow() { child = own_account_row };
            list_box.append(own_account_lbrow);

            fetch_roster_items(a);
        }
    }

    private void on_removed_roster_item(Account account, Jid jid, Roster.Item roster_item) {
        if (rows.has_key(account) && rows[account].has_key(jid)) {
            list_box.remove(rows[account][jid]);
            rows[account].unset(jid);
        }
    }

    private void on_updated_roster_item(Account account, Jid jid, Roster.Item roster_item) {
        on_removed_roster_item(account, jid, roster_item);
        ListRow row = new ListRow.from_jid(stream_interactor, roster_item.jid, account, accounts.size > 1);
        ListBoxRow list_box_row = new ListBoxRow() { child = row };
        rows[account][jid] = list_box_row;
        list_box.append(list_box_row);
        list_box.invalidate_sort();
        list_box.invalidate_filter();
    }

    private void fetch_roster_items(Account account) {
        rows[account] = new HashMap<Jid, ListBoxRow>(Jid.hash_func, Jid.equals_func);
        foreach (Roster.Item roster_item in stream_interactor.get_module(RosterManager.IDENTITY).get_roster(account)) {
            on_updated_roster_item(account, roster_item.jid, roster_item);
        }
    }

    public ListBox get_list_box() {
        return list_box;
    }
}

}
