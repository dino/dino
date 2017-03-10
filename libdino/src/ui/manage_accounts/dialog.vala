using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/org/dino-im/manage_accounts/dialog.ui")]
public class Dialog : Gtk.Window {

    public signal void account_enabled(Account account);
    public signal void account_disabled(Account account);

    [GtkChild] public Stack main_stack;
    [GtkChild] public ListBox account_list;
    [GtkChild] public Button no_accounts_add;
    [GtkChild] public ToolButton add_button;
    [GtkChild] public ToolButton remove_button;
    [GtkChild] public Image image;
    [GtkChild] public Button image_button;
    [GtkChild] public Label jid_label;
    [GtkChild] public Switch active_switch;

    [GtkChild] public Stack password_stack;
    [GtkChild] public Label password_label;
    [GtkChild] public Button password_button;
    [GtkChild] public Entry password_entry;

    [GtkChild] public Stack alias_stack;
    [GtkChild] public Label alias_label;
    [GtkChild] public Button alias_button;
    [GtkChild] public Entry alias_entry;

    [GtkChild] public Stack pgp_stack;
    [GtkChild] public Label pgp_label;
    [GtkChild] public Button pgp_button;
    [GtkChild] public ComboBoxText pgp_combobox;


    private Database db;
    private StreamInteractor stream_interactor;

    construct {
        account_list.row_selected.connect(account_list_row_selected);
        add_button.clicked.connect(add_button_clicked);
        no_accounts_add.clicked.connect(add_button_clicked);
        remove_button.clicked.connect(remove_button_clicked);
        password_entry.key_release_event.connect(on_password_key_release_event);
        alias_entry.key_release_event.connect(on_alias_key_release_event);
        image_button.clicked.connect(on_image_button_clicked);

        main_stack.set_visible_child_name("no_accounts");
    }

    public Dialog(StreamInteractor stream_interactor, Database db) {
        this.db = db;
        this.stream_interactor = stream_interactor;
        foreach (Account account in db.get_accounts()) {
            add_account(account);
        }

        AvatarManager.get_instance(stream_interactor).received_avatar.connect((pixbuf, jid, account) => {
        Idle.add(() => {
            on_received_avatar(pixbuf, jid, account);
            return false;
        });});

        if (account_list.get_row_at_index(0) != null) account_list.select_row(account_list.get_row_at_index(0));
    }

    public AccountRow add_account(Account account) {
        AccountRow account_item = new AccountRow (stream_interactor, account);
        account_list.add(account_item);
        main_stack.set_visible_child_name("accounts_exist");
        return account_item;
    }

    private void add_button_clicked() {
        AddAccountDialog add_account_dialog = new AddAccountDialog(stream_interactor);
        add_account_dialog.set_transient_for(this);
        add_account_dialog.added.connect((account) => {
            db.add_account(account);
            AccountRow account_item = add_account(account);
            account_list.select_row(account_item);
            account_list.queue_draw();
        });
        add_account_dialog.show();
    }

    private void remove_button_clicked() {
        AccountRow account_item = account_list.get_selected_row() as AccountRow;
        if (account_item != null) {
            account_list.remove(account_item);
            account_list.queue_draw();
            if (account_item.account.enabled) account_disabled(account_item.account);
            db.remove_account(account_item.account);
            if (account_list.get_row_at_index(0) != null) {
                account_list.select_row(account_list.get_row_at_index(0));
            } else {
                main_stack.set_visible_child_name("no_accounts");
            }
        }
    }

    private void account_list_row_selected(ListBoxRow? row) {
        AccountRow? account_item = row as AccountRow;
        if (account_item != null) populate_grid_data(account_item.account);
    }

    private void populate_grid_data(Account account) {
        active_switch.state_set.disconnect(on_active_switch_state_changed);

        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(50, 50, image.scale_factor)).draw_account(stream_interactor, account));
        active_switch.set_active(account.enabled);
        jid_label.label = account.bare_jid.to_string();

        string filler = "";
        for (int i = 0; i < account.password.length; i++) filler += password_entry.get_invisible_char().to_string();
        password_label.label = filler;
        password_stack.set_visible_child_name("label");
        password_entry.text = account.password;

        alias_stack.set_visible_child_name("label");
        alias_label.label = account.alias;
        alias_entry.text = account.alias;

        password_button.clicked.connect(() => { set_active_stack(password_stack); });
        alias_button.clicked.connect(() => { set_active_stack(alias_stack); });
        active_switch.state_set.connect(on_active_switch_state_changed);
    }

    private void on_image_button_clicked() {
        FileChooserDialog chooser = new FileChooserDialog (
				"Select avatar", this, FileChooserAction.OPEN,
				"Cancel", ResponseType.CANCEL,
				"Select", ResponseType.ACCEPT);
        FileFilter filter = new FileFilter();
        filter.add_mime_type("image/*");
        chooser.set_filter(filter);
        if (chooser.run() == Gtk.ResponseType.ACCEPT) {
            string uri = chooser.get_filename();
            Account account = (account_list.get_selected_row() as AccountRow).account;
            AvatarManager.get_instance(stream_interactor).publish(account, uri);
        }
        chooser.close();
    }

    private bool on_active_switch_state_changed(bool state) {
        Account account = (account_list.get_selected_row() as AccountRow).account;
        account.enabled = state;
        if (state) {
            account_enabled(account);
        } else {
            account_disabled(account);
        }
        return false;
    }

    private bool on_password_key_release_event(EventKey event) {
        Account account = (account_list.get_selected_row() as AccountRow).account;
        account.password = password_entry.text;
        string filler = "";
        for (int i = 0; i < account.password.length; i++) filler += password_entry.get_invisible_char().to_string();
        password_label.label = filler;
        if (event.keyval == Key.Return) {
            password_stack.set_visible_child_name("label");
        }
        return false;
    }

    private bool on_alias_key_release_event(EventKey event) {
        Account account = (account_list.get_selected_row() as AccountRow).account;
        account.alias = alias_entry.text;
        alias_label.label = alias_entry.text;
        if (event.keyval == Key.Return) {
            alias_stack.set_visible_child_name("label");
        }
        return false;
    }

    private void on_received_avatar(Pixbuf pixbuf, Jid jid, Account account) {
        Account curr_account = (account_list.get_selected_row() as AccountRow).account;
        if (curr_account.equals(account) && jid.equals(account.bare_jid)) {
            Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(50, 50, image.scale_factor)).draw_account(stream_interactor, account));
        }
    }

    private void set_active_stack(Stack stack) {
        stack.set_visible_child_name("entry");
        if (stack != password_stack) password_stack.set_visible_child_name("label");
        if (stack != alias_stack) alias_stack.set_visible_child_name("label");
        if (stack != pgp_stack) pgp_stack.set_visible_child_name("label");
    }
}

}

