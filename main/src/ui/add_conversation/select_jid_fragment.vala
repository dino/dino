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
        get { return list.get_selected_row() != null; }
        private set {}
    }

    [GtkChild] private unowned Entry entry;
    [GtkChild] private unowned Box box;
    [GtkChild] private unowned Button add_button;
    [GtkChild] private unowned Button remove_button;
    [GtkChild] private unowned Button filter_online_button;

    private StreamInteractor stream_interactor;
    private Gee.List<Account> accounts;
    private ArrayList<Widget> added_rows = new ArrayList<Widget>();

    private ListBox list;
    private string[]? filter_values;
    private bool filter_online_toggled = false;

    public SelectJidFragment(StreamInteractor stream_interactor, ListBox list, Gee.List<Account> accounts, bool is_conf_dialog) {
        this.stream_interactor = stream_interactor;
        this.list = list;
        this.accounts = accounts;

        list.activate_on_single_click = false;
        list.vexpand = true;

        if(!is_conf_dialog) filter_online_button.visible = true;
        filter_online_button.set_tooltip_text(_("Only showing online users is not toggled on."));
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
        filter_online_button.clicked.connect(() => {
            if(!filter_online_toggled){
                filter_online_toggled = true;
                Util.force_css(filter_online_button, "* {border: 2px solid limegreen;}");
                filter_online_button.set_tooltip_text(_("Only showing online users is toggled on."));
            }
            else{
                filter_online_toggled = false;
                Util.force_css(filter_online_button, "* {border: initial;}");
                filter_online_button.set_tooltip_text(_("Only showing online users is not toggled on."));
            }
            list.set_filter_func(filter);
            entry.grab_focus();
        });
    }

    public void set_filter(string str) {
        if (entry.text != str) entry.text = str;

        foreach (Widget row in added_rows) list.remove(row);
        added_rows.clear();

        filter_values = str == "" ? null : str.split(" ");
        list.invalidate_filter();

        try {
            Jid parsed_jid = new Jid(str);
            if (parsed_jid != null && parsed_jid.localpart != null) {
                foreach (Account account in accounts) {
                    var list_row = new Gtk.ListBoxRow();
                    list_row.set_child(new AddListRow(stream_interactor, parsed_jid, account));
                    list.append(list_row);
                    added_rows.add(list_row);
                }
            }
        } catch (InvalidJidError ignored) {
            // Ignore
        }
    }

    private void check_buttons_active() {
        ListBoxRow? row = list.get_selected_row();
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
        if (filter_online_toggled){
            if(row.status_str == null){
                return false;
            }
        }

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
