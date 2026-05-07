using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public delegate Gee.List<Jid> SuggestJids(string str, Account account);

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/select_jid_fragment.ui")]
public class SelectJidFragment : Gtk.Box {

    public signal void add_jid();
    public signal void remove_jid(ListRow row);
    public bool done {
        get { return list.get_selected_row() != null; }
        private set {}
    }

    public SuggestJids suggest_jids = null;

    [GtkChild] private unowned Entry entry;
    [GtkChild] private unowned Box box;
    [GtkChild] private unowned Button add_button;
    [GtkChild] private unowned Button remove_button;

    private StreamInteractor stream_interactor;
    private Gee.List<Account> accounts;
    private ArrayList<Widget> added_rows = new ArrayList<Widget>();

    private ListBox list;
    private string[]? filter_values;

    public SelectJidFragment(StreamInteractor stream_interactor, ListBox list, Gee.List<Account> accounts) {
        this.stream_interactor = stream_interactor;
        this.list = list;
        this.accounts = accounts;

        list.activate_on_single_click = false;
        list.vexpand = true;
        box.append(list);

        list.set_sort_func(sort);
        list.set_filter_func(filter);
        list.set_header_func(header);
        list.row_selected.connect(check_buttons_active);
        list.row_selected.connect(() => { done = true; }); // just for notifying
        entry.changed.connect(() => { set_filter(entry.text); });
        add_button.clicked.connect(() => { add_jid(); });
        remove_button.clicked.connect(() => {
            var list_row = list.get_selected_row();
            if (list_row == null) return;
            remove_jid(list_row.child as ListRow);
        });
    }

    public void set_filter(string str) {
        if (entry.text != str) entry.text = str;

        foreach (Widget row in added_rows) list.remove(row);
        added_rows.clear();

        filter_values = str == "" ? null : str.split(" ");
        list.invalidate_filter();

        // Add suggested JIDs from our owner as synthetic ListBox rows.
        //
        // First build a set of existing JIDs to avoid dupes.
        // XXX this is medium-expensive to do on each keystroke;
        // can we make add/remove signals on the ListBox to hook?
        var present = new Gee.HashMap<Account, Gee.HashSet<Jid>>(Account.hash_func, Account.equals_func);
        for (var child = list.get_first_child(); child != null; child = child.get_next_sibling()) {
            var row = child as Gtk.ListBoxRow;
            if (row == null) continue;
            var list_row = row.get_child() as ListRow;
            if (list_row == null || list_row.jid == null || list_row.account == null) continue;
            if (!present.has_key(list_row.account)) {
                present[list_row.account] = new Gee.HashSet<Jid>(Jid.hash_func, Jid.equals_func);
            }
            present[list_row.account].add(list_row.jid);
        }

        // Then actually add them
        foreach (Account account in accounts) {
            Gee.List<Jid> suggestions = suggest_jids(str, account);
            foreach (Jid jid in suggestions) {
                if (present.has_key(account) && present[account].contains(jid)) continue;
                if (!present.has_key(account)) {
                    present[account] = new Gee.HashSet<Jid>(Jid.hash_func, Jid.equals_func);
                }
                present[account].add(jid);
                var list_row = new Gtk.ListBoxRow();
                list_row.set_child(new AddListRow(stream_interactor, jid, account));
                list.append(list_row);
                added_rows.add(list_row);
            }
        }
    }

    private void check_buttons_active() {
        ListBoxRow? row = list.get_selected_row();
        bool active = row != null && row.child != null && !row.child.get_type().is_a(typeof(AddListRow));
        remove_button.sensitive = active;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        AddListRow al1 = (row1 as AddListRow);
        AddListRow al2 = (row2 as AddListRow);
        if (al1 != null && al2 == null) {
            return -1;
        } else if (al2 != null && al1 == null) {
            return 1;
        }

        ListRow? c1 = (row1.child as ListRow);
        ListRow? c2 = (row2.child as ListRow);
        if (c1 != null && c2 != null) {
            return c1.name_label.label.collate(c2.name_label.label);
        }

        return 0;
    }

    private bool filter(ListBoxRow r) {
        ListRow? row = (r.child as ListRow);
        if (row == null) return true;

        if (filter_values != null) {
            foreach (string filter in filter_values) {
                if (!(row.name_label.label.down().contains(filter.down()) ||
                        row.jid.to_string().down().contains(filter.down()))) {
                    return false;
                }
            }
        }
        return true;
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private class AddListRow : ListRow {

        public AddListRow(StreamInteractor stream_interactor, Jid jid, Account account) {
            this.account = account;
            this.jid = jid;

            name_label.label = jid.to_string();
            if (stream_interactor.get_accounts().size > 1) {
                via_label.label = account.bare_jid.to_string();
            } else {
                via_label.visible = false;
            }
            picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add("+");
        }
    }
}

}
