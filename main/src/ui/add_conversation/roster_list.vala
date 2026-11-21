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

        foreach (Account a in accounts) fetch_roster_items(a);
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

    private void fetch_roster_items(Account account) {
        rows[account] = new HashMap<Jid, ListBoxRow>(Jid.hash_func, Jid.equals_func);
        bool has_self = false;
        foreach (Roster.Item roster_item in stream_interactor.get_module(RosterManager.IDENTITY).get_roster(account)) {
            if (roster_item.jid == account.bare_jid) { has_self = true; }
            update_row(account, roster_item.jid);
        }

        if (!has_self) {
            // Inject a virtual "Note to Self" contact.
            // XMPP technically allows people to be on their own contact lists but
            // in practice it's rarely allowed, in fact there's an embarrassed mention of this in:
            // https://www.rfc-editor.org/rfc/rfc6121.html#section-2.3.3:
            // >  Interoperability Note: Some servers return a <not-allowed/> stanza
            // > error to the client if the value of the <item/> element's 'jid'
            // > attribute matches the bare JID <localpart@domainpart> of the
            // > user's account.
            update_row(account, account.bare_jid);
        }
    }

    public ListBox get_list_box() {
        return list_box;
    }
}

}
