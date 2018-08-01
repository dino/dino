using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/select_jid_fragment.ui")]
public class SelectJidFragment : Gtk.Box {

    public signal void add_jid();
    public signal void remove_jid(ListRow row);
    public bool done {
        get { return filterable_list.get_selected_row() != null; }
        private set {}
    }

    [GtkChild] private Entry entry;
    [GtkChild] private Box box;
    [GtkChild] private Button add_button;
    [GtkChild] private Button remove_button;

    private StreamInteractor stream_interactor;
    private FilterableList filterable_list;
    private Gee.List<Account> accounts;

    private ArrayList<AddListRow> added_rows = new ArrayList<AddListRow>();

    public SelectJidFragment(StreamInteractor stream_interactor, FilterableList filterable_list, Gee.List<Account> accounts) {
        this.stream_interactor = stream_interactor;
        this.filterable_list = filterable_list;
        this.accounts = accounts;

        filterable_list.visible = true;
        filterable_list.activate_on_single_click = false;
        filterable_list.vexpand = true;
        box.add(filterable_list);

        filterable_list.set_sort_func(sort);
        filterable_list.row_selected.connect(check_buttons_active);
        filterable_list.row_selected.connect(() => { done = true; }); // just for notifying
        entry.changed.connect(() => { set_filter(entry.text); });
        add_button.clicked.connect(() => { add_jid(); });
        remove_button.clicked.connect(() => { remove_jid(filterable_list.get_selected_row() as ListRow); });
    }

    public void set_filter(string str) {
        if (entry.text != str) entry.text = str;

        foreach (AddListRow row in added_rows) row.destroy();
        added_rows.clear();

        string[] ? values = str == "" ? null : str.split(" ");
        filterable_list.set_filter_values(values);
        Jid? parsed_jid = Jid.parse(str);
        if (parsed_jid != null && parsed_jid.localpart != null) {
            foreach (Account account in accounts) {
                AddListRow row = new AddListRow(stream_interactor, str, account);
                filterable_list.add(row);
                added_rows.add(row);
            }
        }
    }

    private void check_buttons_active() {
        ListBoxRow? row = filterable_list.get_selected_row();
        bool active = row != null && !row.get_type().is_a(typeof(AddListRow));
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
        return filterable_list.sort(row1, row2);
    }

    private class AddListRow : ListRow {

        public AddListRow(StreamInteractor stream_interactor, string jid, Account account) {
            this.account = account;
            this.jid = new Jid(jid);

            name_label.label = jid;
            if (stream_interactor.get_accounts().size > 1) {
                via_label.label = account.bare_jid.to_string();
            } else {
                via_label.visible = false;
            }
            image.set_text("?");
        }
    }
}

public abstract class FilterableList : Gtk.ListBox {
    public string[]? filter_values;

    public void set_filter_values(string[] values) {
        if (filter_values == values) return;
        filter_values = values;
        invalidate_filter();
    }

    public abstract int sort(ListBoxRow row1, ListBoxRow row2);
}

}
