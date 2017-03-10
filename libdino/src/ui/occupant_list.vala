using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui{

[GtkTemplate (ui = "/org/dino-im/occupant_list.ui")]
public class OccupantList : Box {

    public signal void conversation_selected(Conversation? conversation);
    private StreamInteractor stream_interactor;

    [GtkChild] private ListBox list_box;
    [GtkChild] private SearchEntry search_entry;

    private Conversation? conversation;
    private string[]? filter_values;
    private HashMap<Jid, OccupantListRow> rows = new HashMap<Jid, OccupantListRow>(Jid.hash_func, Jid.equals_func);

    public OccupantList(StreamInteractor stream_interactor, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        list_box.set_header_func(header);
        list_box.set_sort_func(sort);
        list_box.set_filter_func(filter);
        search_entry.search_changed.connect(search_changed);

        PresenceManager.get_instance(stream_interactor).show_received.connect((show, jid, account) => {
            Idle.add(() => { on_show_received(show, jid, account); return false; });
        });
        RosterManager.get_instance(stream_interactor).updated_roster_item.connect(on_updated_roster_item);

        initialize_for_conversation(conversation);
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
        ArrayList<Jid>? occupants = MucManager.get_instance(stream_interactor).get_occupants(conversation.counterpart, conversation.account);
        if (occupants != null) {
            foreach (Jid occupant in occupants) {
                add_occupant(occupant);
            }
        }
    }

    private void refilter() {
        string[]? values = null;
        string str = search_entry.get_text ();
        if (str != "") values = str.split(" ");
        if (filter_values == values) return;
        filter_values = values;
        list_box.invalidate_filter();
    }

    private void search_changed(Editable editable) {
        refilter();
    }

    public void add_occupant(Jid jid) {
        rows[jid] = new OccupantListRow(stream_interactor, conversation.account, jid);
        list_box.add(rows[jid]);
        list_box.invalidate_filter();
        list_box.invalidate_sort();
    }

    public void remove_occupant(Jid jid) {
        list_box.remove(rows[jid]);
        rows.unset(jid);
    }

    private void on_updated_roster_item(Account account, Jid jid, Xmpp.Roster.Item roster_item) {

    }

    private void on_show_received(Show show, Jid jid, Account account) {
        if (conversation != null && conversation.counterpart.equals_bare(jid)) {
            if (show.as == Show.OFFLINE && rows.has_key(jid)) {
                remove_occupant(jid);
            } else if (show.as != Show.OFFLINE && !rows.has_key(jid)) {
                add_occupant(jid);
            }
        }
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private bool filter(ListBoxRow r) {
        if (r.get_type().is_a(typeof(OccupantListRow))) {
            OccupantListRow row = r as OccupantListRow;
            foreach (string filter in filter_values) {
                return row.name_label.label.down().contains(filter.down());
            }
        }
        return true;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        if (row1.get_type().is_a(typeof(OccupantListRow)) && row2.get_type().is_a(typeof(OccupantListRow))) {
            OccupantListRow c1 = row1 as OccupantListRow;
            OccupantListRow c2 = row2 as OccupantListRow;
            return c1.name_label.label.collate(c2.name_label.label);
        }
        return 0;
    }
}

}