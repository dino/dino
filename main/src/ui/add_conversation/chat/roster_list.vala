using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.AddConversation.Chat {

protected class RosterList : FilterableList {

    public signal void conversation_selected(Conversation? conversation);
    private StreamInteractor stream_interactor;

    private HashMap<Jid, ListRow> rows = new HashMap<Jid, ListRow>(Jid.hash_func, Jid.equals_func);

    public RosterList(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        stream_interactor.get_module(RosterManager.IDENTITY).removed_roster_item.connect( (account, jid, roster_item) => {
            Idle.add(() => { on_removed_roster_item(account, jid, roster_item); return false;});});
        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect( (account, jid, roster_item) => {
            Idle.add(() => { on_updated_roster_item(account, jid, roster_item); return false;});});

        foreach (Account account in stream_interactor.get_accounts()) {
            foreach (Roster.Item roster_item in stream_interactor.get_module(RosterManager.IDENTITY).get_roster(account)) {
                on_updated_roster_item(account, new Jid(roster_item.jid), roster_item);
            }
        }
    }

    private void on_removed_roster_item(Account account, Jid jid, Roster.Item roster_item) {
        if (rows.has_key(jid)) {
            remove(rows[jid]);
            rows.unset(jid);
        }
    }

    private void on_updated_roster_item(Account account, Jid jid, Roster.Item roster_item) {
        on_removed_roster_item(account, jid, roster_item);
        ListRow row = new ListRow.from_jid(stream_interactor, new Jid(roster_item.jid), account);
        rows[jid] = row;
        add(row);
        invalidate_sort();
        invalidate_filter();
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private bool filter(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ListRow))) {
            ListRow row = r as ListRow;
            if (filter_values != null) {
                foreach (string filter in filter_values) {
                    if (!(row.name_label.label.down().contains(filter.down()) ||
                            row.jid.to_string().down().contains(filter.down()))) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    public override int sort(ListBoxRow row1, ListBoxRow row2) {
        ListRow c1 = (row1 as ListRow);
        ListRow c2 = (row2 as ListRow);
        return c1.name_label.label.collate(c2.name_label.label);
    }
}

}