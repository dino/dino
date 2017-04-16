using Gdk;
using Gee;
using Gtk;
using Markup;

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
    [GtkChild] public Label state_label;
    [GtkChild] public Switch active_switch;

    [GtkChild] public Stack password_stack;
    [GtkChild] public Label password_label;
    [GtkChild] public Button password_button;
    [GtkChild] public Entry password_entry;

    [GtkChild] public Stack alias_stack;
    [GtkChild] public Label alias_label;
    [GtkChild] public Button alias_button;
    [GtkChild] public Entry alias_entry;

    [GtkChild] public Grid settings_list;

    private ArrayList<Plugins.AccountSettingsWidget> plugin_widgets = new ArrayList<Plugins.AccountSettingsWidget>();

    private Database db;
    private StreamInteractor stream_interactor;
    private Account? selected_account;

    construct {
        Util.force_error_color(state_label, ".is_error");
        account_list.row_selected.connect(on_account_list_row_selected);
        add_button.clicked.connect(on_add_button_clicked);
        no_accounts_add.clicked.connect(on_add_button_clicked);
        remove_button.clicked.connect(on_remove_button_clicked);
        password_entry.key_release_event.connect(on_password_key_release_event);
        alias_entry.key_release_event.connect(on_alias_key_release_event);
        image_button.clicked.connect(on_image_button_clicked);

        main_stack.set_visible_child_name("no_accounts");

        int row_index = 4;
        int16 default_top_padding = new Gtk.Button().get_style_context().get_padding(Gtk.StateFlags.NORMAL).top + 1;
        Application app = GLib.Application.get_default() as Application;
        foreach (var e in app.plugin_registry.account_settings_entries) {
            Plugins.AccountSettingsWidget widget = e.get_widget();
            plugin_widgets.add(widget);
            widget.visible = true;
            widget.activated.connect(child_activated);
            Label label = new Label(e.name);
            label.get_style_context().add_class("dim-label");
            label.set_padding(0, e.label_top_padding == -1 ? default_top_padding : e.label_top_padding);
            label.yalign = 0;
            label.xalign = 1;
            label.visible = true;
            settings_list.attach(label, 0, row_index);
            settings_list.attach(widget, 1, row_index, 2);
            row_index++;
        }
    }

    public Dialog(StreamInteractor stream_interactor, Database db) {
        this.db = db;
        this.stream_interactor = stream_interactor;
        foreach (Account account in db.get_accounts()) {
            add_account(account);
        }

        stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect((pixbuf, jid, account) => {
            Idle.add(() => {
                on_received_avatar(pixbuf, jid, account);
                return false;
            });
        });
        stream_interactor.connection_manager.connection_error.connect((account, error) => {
            Idle.add(() => {
                if (account.equals(selected_account)) update_status_label(account);
                return false;
            });
        });
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            Idle.add(() => {
                if (account.equals(selected_account)) update_status_label(account);
                return false;
            });
        });

        if (account_list.get_row_at_index(0) != null) account_list.select_row(account_list.get_row_at_index(0));
    }

    public AccountRow add_account(Account account) {
        AccountRow account_item = new AccountRow (stream_interactor, account);
        account_list.add(account_item);
        main_stack.set_visible_child_name("accounts_exist");
        return account_item;
    }

    private void on_add_button_clicked() {
        AddAccountDialog add_account_dialog = new AddAccountDialog(stream_interactor);
        add_account_dialog.set_transient_for(this);
        add_account_dialog.added.connect((account) => {
            account.persist(db);
            AccountRow account_item = add_account(account);
            account_list.select_row(account_item);
            account_list.queue_draw();
        });
        add_account_dialog.show();
    }

    private void on_remove_button_clicked() {
        AccountRow account_item = account_list.get_selected_row() as AccountRow;
        if (account_item != null) {
            account_list.remove(account_item);
            account_list.queue_draw();
            if (account_item.account.enabled) account_disabled(account_item.account);
            account_item.account.remove();
            if (account_list.get_row_at_index(0) != null) {
                account_list.select_row(account_list.get_row_at_index(0));
            } else {
                main_stack.set_visible_child_name("no_accounts");
            }
        }
    }

    private void on_account_list_row_selected(ListBoxRow? row) {
        AccountRow? account_item = row as AccountRow;
        if (account_item != null) {
            selected_account = account_item.account;
            populate_grid_data(account_item.account);
        }
    }

    private void on_image_button_clicked() {
        FileChooserDialog chooser = new FileChooserDialog (
				_("Select avatar"), this, FileChooserAction.OPEN,
				_("Cancel"), ResponseType.CANCEL,
				_("Select"), ResponseType.ACCEPT);
        FileFilter filter = new FileFilter();
        filter.add_mime_type("image/*");
        chooser.set_filter(filter);
        if (chooser.run() == Gtk.ResponseType.ACCEPT) {
            string uri = chooser.get_filename();
            Account account = (account_list.get_selected_row() as AccountRow).account;
            stream_interactor.get_module(AvatarManager.IDENTITY).publish(account, uri);
        }
        chooser.close();
    }

    private bool on_active_switch_state_changed(bool state) {
        Account account = (account_list.get_selected_row() as AccountRow).account;
        account.enabled = state;
        if (state) {
            if (account.enabled) account_disabled(account);
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

        update_status_label(account);

        password_button.clicked.connect(() => { set_active_stack(password_stack); });
        alias_button.clicked.connect(() => { set_active_stack(alias_stack); });
        active_switch.state_set.connect(on_active_switch_state_changed);

        foreach(Plugins.AccountSettingsWidget widget in plugin_widgets) {
            widget.set_account(account);
        }

        child_activated(null);
    }

    private void update_status_label(Account account) {
        state_label.label = "";
        ConnectionManager.ConnectionError? error = stream_interactor.connection_manager.get_error(account);
        if (error != null) {
            state_label.label = get_connection_error_description(error);
            state_label.get_style_context().add_class("is_error");

            if (error.source == ConnectionManager.ConnectionError.Source.SASL ||
                    (error.flag != null && error.flag.reconnection_recomendation == Xmpp.StreamError.Flag.Reconnect.NEVER)) {
                active_switch.active = false;
            }

        } else {
            ConnectionManager.ConnectionState state = stream_interactor.connection_manager.get_state(account);
            switch (state) {
                case ConnectionManager.ConnectionState.CONNECTING:
                    state_label.label = _("Connecting…"); break;
                case ConnectionManager.ConnectionState.CONNECTED:
                    state_label.label = _("Connected"); break;
                case ConnectionManager.ConnectionState.DISCONNECTED:
                    state_label.label = _("Disconnected"); break;
            }
            state_label.get_style_context().remove_class("is_error");
        }
    }

    private void child_activated(Gtk.Widget? widget) {
        if (widget != password_stack) password_stack.set_visible_child_name("label");
        if (widget != alias_stack) alias_stack.set_visible_child_name("label");

        foreach(var w in plugin_widgets) {
            if (widget != (Gtk.Widget)w) w.deactivate();
        }
    }

    private void set_active_stack(Stack stack) {
        stack.set_visible_child_name("entry");
        child_activated(stack);
    }

    private string get_connection_error_description(ConnectionManager.ConnectionError error) {
        switch (error.source) {
            case ConnectionManager.ConnectionError.Source.SASL:
                return _("Wrong password");
        }
        if (error.identifier != null) {
            return _("Error") + ": " + error.identifier;
        } else {
            return _("Error");
        }
    }
}

}

