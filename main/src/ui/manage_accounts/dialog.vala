using Gdk;
using Gee;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/manage_accounts/dialog.ui")]
public class Dialog : Gtk.Dialog {

    public signal void account_enabled(Account account);
    public signal void account_disabled(Account account);

    [GtkChild] public Stack main_stack;
    [GtkChild] public ListBox account_list;
    [GtkChild] public Button no_accounts_add;
    [GtkChild] public ToolButton add_account_button;
    [GtkChild] public ToolButton remove_account_button;
    [GtkChild] public Image image;
    [GtkChild] public Button image_button;
    [GtkChild] public Label jid_label;
    [GtkChild] public Label state_label;
    [GtkChild] public Switch active_switch;
    [GtkChild] public Util.EntryLabelHybrid password_hybrid;
    [GtkChild] public Util.EntryLabelHybrid alias_hybrid;
    [GtkChild] public Grid settings_list;

    private ArrayList<Plugins.AccountSettingsWidget> plugin_widgets = new ArrayList<Plugins.AccountSettingsWidget>();

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
        alias_hybrid.entry.key_release_event.connect(() => { selected_account.alias = alias_hybrid.text; return false; });
        password_hybrid.entry.key_release_event.connect(() => { selected_account.password = password_hybrid.text; return false; });

        Util.LabelHybridGroup label_hybrid_group = new Util.LabelHybridGroup();
        label_hybrid_group.add(alias_hybrid);
        label_hybrid_group.add(password_hybrid);

        main_stack.set_visible_child_name("no_accounts");

        int row_index = 4;
        int16 default_top_padding = new Gtk.Button().get_style_context().get_padding(Gtk.StateFlags.NORMAL).top + 1;
        Application app = GLib.Application.get_default() as Application;
        foreach (var e in app.plugin_registry.account_settings_entries) {
            Plugins.AccountSettingsWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            plugin_widgets.add(widget);

            Label label = new Label(e.name) { xalign=1, yalign=0, visible=true };
            label.get_style_context().add_class("dim-label");
            label.set_padding(0, e.label_top_padding == -1 ? default_top_padding : e.label_top_padding);

            settings_list.attach(label, 0, row_index);
            if (widget is Widget) {
                Widget gtkw = (Widget) widget;
                plugin_widgets.add(widget);
                gtkw.visible = true;
                settings_list.attach(gtkw, 1, row_index, 2);
            } else {
                // TODO
            }
            row_index++;
        }
    }

    public Dialog(StreamInteractor stream_interactor, Database db) {
        Object(use_header_bar : 1);
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

    private void show_add_account_dialog() {
        AddAccountDialog add_account_dialog = new AddAccountDialog(stream_interactor);
        add_account_dialog.set_transient_for(this);
        add_account_dialog.added.connect((account) => {
            account.persist(db);
            AccountRow account_item = add_account(account);
            account_list.select_row(account_item);
            account_list.queue_draw();
        });
        add_account_dialog.present();
    }

    private void remove_account(AccountRow account_item) {
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

    private void on_account_list_row_selected(ListBoxRow? row) {
        AccountRow? account_item = row as AccountRow;
        if (account_item != null) {
            selected_account = account_item.account;
            populate_grid_data(account_item.account);
        }
    }

    private void show_select_avatar() {
        FileChooserNative chooser = new FileChooserNative (
                _("Select avatar"), this, FileChooserAction.OPEN,
                _("Select"), _("Cancel"));
        FileFilter filter = new FileFilter();
        filter.add_pattern("*.png");
        filter.add_pattern("*.jpg");
        filter.add_pattern("*.jpeg");
        filter.add_pattern("*.gif");
        filter.add_pattern("*.svg");
        filter.add_pattern("*.bmp");
        filter.set_filter_name(_("Images"));
        chooser.add_filter(filter);
        filter = new FileFilter();
        filter.set_filter_name(_("All files"));
        filter.add_pattern("*");
        chooser.add_filter(filter);
        if (chooser.run() == Gtk.ResponseType.ACCEPT) {
            string uri = chooser.get_filename();
            stream_interactor.get_module(AvatarManager.IDENTITY).publish(selected_account, uri);
        }
    }

    private bool on_active_switch_state_changed(bool state) {
        selected_account.enabled = state;
        if (state) {
            if (selected_account.enabled) account_disabled(selected_account);
            account_enabled(selected_account);
        } else {
            account_disabled(selected_account);
        }
        return false;
    }

    private void on_received_avatar(Pixbuf pixbuf, Jid jid, Account account) {
        if (selected_account.equals(account) && jid.equals(account.bare_jid)) {
            Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(50, 50, image.scale_factor)).draw_account(stream_interactor, account));
        }
    }

    private void populate_grid_data(Account account) {
        active_switch.state_set.disconnect(on_active_switch_state_changed);

        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(50, 50, image.scale_factor)).draw_account(stream_interactor, account));
        active_switch.set_active(account.enabled);
        jid_label.label = account.bare_jid.to_string();

        alias_hybrid.text = account.alias;
        password_hybrid.entry.input_purpose = InputPurpose.PASSWORD;
        password_hybrid.text = account.password;

        update_status_label(account);

        active_switch.state_set.connect(on_active_switch_state_changed);

        foreach(Plugins.AccountSettingsWidget widget in plugin_widgets) {
            widget.set_account(account);
        }
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
