using Gdk;
using Gee;
using Gtk;
using Markup;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/dialog.ui")]
public class Dialog : Gtk.Dialog {

    public signal void account_enabled(Account account);
    public signal void account_disabled(Account account);

    [GtkChild] public unowned Stack main_stack;
    [GtkChild] public unowned ListBox account_list;
    [GtkChild] public unowned Button no_accounts_add;
    [GtkChild] public unowned Button add_account_button;
    [GtkChild] public unowned Button remove_account_button;
    [GtkChild] public unowned AvatarPicture picture;
    [GtkChild] public unowned Button image_button;
    [GtkChild] public unowned Label jid_label;
    [GtkChild] public unowned Label state_label;
    [GtkChild] public unowned Switch active_switch;
    [GtkChild] public unowned Util.EntryLabelHybrid password_hybrid;
    [GtkChild] public unowned Button password_change_button;
    [GtkChild] public unowned Util.EntryLabelHybrid alias_hybrid;
    [GtkChild] public unowned Grid settings_list;

    private Database db;
    private StreamInteractor stream_interactor;
    private Account? selected_account;

    construct {
        Util.force_error_color(state_label, ".is_error");
        account_list.row_selected.connect(on_account_list_row_selected);
        add_account_button.clicked.connect(show_add_account_dialog);
        no_accounts_add.clicked.connect(show_add_account_dialog);
        remove_account_button.clicked.connect(() => {
            AccountRow? account_row = account_list.get_selected_row() as AccountRow;
            if (selected_account != null) remove_account(account_row);
        });
        image_button.clicked.connect(show_select_avatar);
        alias_hybrid.entry.changed.connect(() => { selected_account.alias = alias_hybrid.text; });
        password_hybrid.entry.changed.connect(() => { selected_account.password = password_hybrid.text; });
        password_change_button.clicked.connect(show_change_password_dialog);

        Util.LabelHybridGroup label_hybrid_group = new Util.LabelHybridGroup();
        label_hybrid_group.add(alias_hybrid);
        label_hybrid_group.add(password_hybrid);
        password_change_button.sensitive = false;

        main_stack.set_visible_child_name("no_accounts");

        int row_index = 4;
        int16 default_top_padding = new Gtk.Button().get_style_context().get_padding().top + 1;
        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.AccountSettingsEntry e in app.plugin_registry.account_settings_entries) {
            Widget? widget = e.get_widget(Plugins.WidgetType.GTK4) as Widget;
            if (widget == null) continue;

            Label label = new Label(e.name) { xalign=1, yalign=0 };
            label.add_css_class("dim-label");
            label.margin_top = e.label_top_padding == -1 ? default_top_padding : e.label_top_padding;
            settings_list.attach(label, 0, row_index);

            settings_list.attach(widget, 1, row_index, 2);
            row_index++;
        }
    }

    public Dialog(StreamInteractor stream_interactor, Database db) {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);
        this.db = db;
        this.stream_interactor = stream_interactor;
        foreach (Account account in db.get_accounts()) {
            add_account(account);
        }

        stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect(on_received_avatar);
        stream_interactor.connection_manager.connection_error.connect((account, error) => {
            if (account.equals(selected_account)) {
                update_status_label(account);
            }
        });
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            if (account.equals(selected_account)) {
                update_status_label(account);
            }
        });

        if (account_list.get_row_at_index(0) != null) account_list.select_row(account_list.get_row_at_index(0));
    }

    public AccountRow add_account(Account account) {
        AccountRow account_item = new AccountRow (stream_interactor, account);
        account_list.append(account_item);
        main_stack.set_visible_child_name("accounts_exist");
        return account_item;
    }

    private void show_add_account_dialog() {
        AddAccountDialog add_account_dialog = new AddAccountDialog(stream_interactor, db);
        add_account_dialog.set_transient_for(this);
        add_account_dialog.added.connect((account) => {
            AccountRow account_item = add_account(account);
            account_list.select_row(account_item);
            account_list.queue_draw();
        });
        add_account_dialog.present();
    }

    private void show_change_password_dialog() {
         ChangePasswordDialog change_password_dialog = new ChangePasswordDialog(selected_account, stream_interactor);
         change_password_dialog.set_transient_for(this);
         change_password_dialog.present();
    }
//
    private void remove_account(AccountRow account_item) {
        Gtk.MessageDialog msg = new Gtk.MessageDialog (
                        this,  Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL,
                        _("Remove account %s?"), account_item.jid_label.get_text());
        msg.secondary_text = "You won't be able to access your conversation history anymore."; // TODO remove history!
        Button ok_button = msg.get_widget_for_response(ResponseType.OK) as Button;
        ok_button.label = _("Remove");
        ok_button.add_css_class("destructive-action");
        msg.response.connect((response) => {
            if (response == ResponseType.OK) {
                account_list.remove(account_item);
                if (account_item.account.enabled) account_disabled(account_item.account);
                account_item.account.remove();
                if (account_list.get_row_at_index(0) != null) {
                    account_list.select_row(account_list.get_row_at_index(0));
                } else {
                    main_stack.set_visible_child_name("no_accounts");
                }
            }
            msg.close();
        });
        msg.present();
    }

    private void on_account_list_row_selected(ListBoxRow? row) {
        AccountRow? account_item = row as AccountRow;
        if (account_item != null) {
            selected_account = account_item.account;
            populate_grid_data(account_item.account);
        }
    }

    private void show_select_avatar() {
        FileChooserNative chooser = new FileChooserNative(_("Select avatar"), this, FileChooserAction.OPEN, _("Select"), _("Cancel"));
        FileFilter filter = new FileFilter();
        foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
            foreach (string mime_type in pixbuf_format.get_mime_types()) {
                filter.add_mime_type(mime_type);
            }
        }
        filter.set_filter_name(_("Images"));
        chooser.add_filter(filter);

        filter = new FileFilter();
        filter.set_filter_name(_("All files"));
        filter.add_pattern("*");
        chooser.add_filter(filter);

        chooser.response.connect(() => {
            string uri = chooser.get_file().get_path();
            stream_interactor.get_module(AvatarManager.IDENTITY).publish(selected_account, uri);
        });

        chooser.show();
    }

    private bool change_account_state(bool state) {
        selected_account.enabled = state;
        if (state) {
            account_enabled(selected_account);
        } else {
            account_disabled(selected_account);
        }
        return false;
    }

    private void on_received_avatar(Jid jid, Account account) {
        if (selected_account.equals(account) && jid.equals(account.bare_jid)) {
            picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(new Conversation(account.bare_jid, account, Conversation.Type.CHAT), account.bare_jid);
        }
    }

    private void populate_grid_data(Account account) {
        active_switch.state_set.disconnect(change_account_state);

        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(new Conversation(account.bare_jid, account, Conversation.Type.CHAT), account.bare_jid);
        active_switch.set_active(account.enabled);
        jid_label.label = account.bare_jid.to_string();

        alias_hybrid.text = account.alias ?? "";
        password_hybrid.entry.input_purpose = InputPurpose.PASSWORD;
        password_hybrid.text = account.password;

        update_status_label(account);

        active_switch.state_set.connect(change_account_state);

        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.AccountSettingsEntry e in app.plugin_registry.account_settings_entries) {
            e.set_account(account);
        }
    }

    private void update_status_label(Account account) {
        state_label.label = "";
        ConnectionManager.ConnectionError? error = stream_interactor.connection_manager.get_error(account);
        if (error != null) {
            state_label.label = get_connection_error_description(error);
            state_label.add_css_class("is_error");
        } else {
            ConnectionManager.ConnectionState state = stream_interactor.connection_manager.get_state(account);
            switch (state) {
                case ConnectionManager.ConnectionState.CONNECTING:
                    state_label.label = _("Connecting…"); break;
                case ConnectionManager.ConnectionState.CONNECTED:
                    password_change_button.sensitive = true;
                    state_label.label = _("Connected"); break;
                case ConnectionManager.ConnectionState.DISCONNECTED:
                    password_change_button.sensitive = false;
                    state_label.label = _("Disconnected"); break;
            }
            state_label.remove_css_class("is_error");
        }
    }

    private string get_connection_error_description(ConnectionManager.ConnectionError error) {
        password_change_button.sensitive = false;
        switch (error.source) {
            case ConnectionManager.ConnectionError.Source.SASL:
                return _("Wrong password");
            case ConnectionManager.ConnectionError.Source.TLS:
                return _("Invalid TLS certificate");
        }
        if (error.identifier != null) {
            return _("Error") + ": " + error.identifier;
        } else {
            return _("Error");
        }
    }
}

}
