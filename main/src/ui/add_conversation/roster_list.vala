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

    public RosterList(StreamInteractor stream_interactor, Gee.List<Account> accounts, bool notes_mode = false) {
        this.stream_interactor = stream_interactor;
        this.accounts = accounts;

        handler_ids += stream_interactor.get_module(RosterManager.IDENTITY).removed_roster_item.connect( (account, jid) => {
            if (accounts.contains(account)) {
                remove_row(account, jid);
            }
        });
        handler_ids += stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect( (account, jid) => {
            if (accounts.contains(account)) {
                update_row(account, jid);
            }
        });
        list_box.destroy.connect(() => {
            foreach (ulong handler_id in handler_ids) stream_interactor.get_module(RosterManager.IDENTITY).disconnect(handler_id);
        });

        foreach (Account a in accounts) fetch_roster_items(a, notes_mode);
    }

    private void remove_row(Account account, Jid jid) {
        if (rows.has_key(account) && rows[account].has_key(jid)) {
            list_box.remove(rows[account][jid]);
            rows[account].unset(jid);
        }
    }

    private void update_row(Account account, Jid jid) {
        remove_row(account, jid);
        ListRow row = new ListRow.from_jid(stream_interactor, jid, account, accounts.size > 1);
        ListBoxRow list_box_row = new ListBoxRow() { child=row };
        rows[account][jid] = list_box_row;
        list_box.append(list_box_row);
        list_box.invalidate_sort();
        list_box.invalidate_filter();
    }

    private void fetch_roster_items(Account account, bool notes_mode = false) {
        if (!notes_mode){
          rows[account] = new HashMap<Jid, ListBoxRow>(Jid.hash_func, Jid.equals_func);
          foreach (Roster.Item roster_item in stream_interactor.get_module(RosterManager.IDENTITY).get_roster(account)) {
            update_row(account, roster_item.jid);
          }
        }
        else {
          ListRow own_account_row = new ListRow.from_jid(stream_interactor, account.bare_jid, account, accounts.size > 1);
          ListBoxRow own_account_lbrow = new ListBoxRow() { child=own_account_row };
          list_box.append(own_account_lbrow);
        }
    }

    public ListBox get_list_box() {
        return list_box;
    }
}

}
