using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;
using Gdk;

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/account_preferences_subpage.ui")]
public class Dino.Ui.AccountPreferencesSubpage : Gtk.Box {

    [GtkChild] public unowned Adw.HeaderBar headerbar;
    [GtkChild] public unowned Button back_button;
    [GtkChild] public unowned AvatarPicture avatar;
    [GtkChild] public unowned Adw.ActionRow xmpp_address;
    [GtkChild] public unowned Adw.EntryRow local_alias;
    [GtkChild] public unowned Adw.ActionRow password_change;
    [GtkChild] public unowned Adw.ActionRow connection_status;
    [GtkChild] public unowned Button enter_password_button;
    [GtkChild] public unowned Box avatar_menu_box;
    [GtkChild] public unowned Button edit_avatar_button;
    [GtkChild] public unowned Button remove_avatar_button;
    [GtkChild] public unowned Widget button_container;
    [GtkChild] public unowned Button remove_account_button;
    [GtkChild] public unowned Button disable_account_button;

    public Account account { get { return model.selected_account.account; } }
    public ViewModel.PreferencesWindow model { get; set; }

    private Binding[] bindings = new Binding[0];
    private ulong[] account_notify_ids = new ulong[0];
    private ulong alias_entry_changed = 0;

    construct {
#if Adw_1_4
        headerbar.show_title = false;
#endif
        button_container.layout_manager = new NaturalDirectionBoxLayout((BoxLayout)button_container.layout_manager);
        back_button.clicked.connect(() => {
            var window = (Adw.PreferencesWindow) this.get_root();
            window.close_subpage();
        });
        edit_avatar_button.clicked.connect(() => {
            show_select_avatar();
        });
        remove_avatar_button.clicked.connect(() => {
            model.remove_avatar(account);
        });
        disable_account_button.clicked.connect(() => {
            model.enable_disable_account(account);
        });
        remove_account_button.clicked.connect(() => {
            show_remove_account_dialog();
        });
        password_change.activatable_widget = new Label("");
        password_change.activated.connect(() => {
            var dialog = new ChangePasswordDialog(model.get_change_password_dialog_model());
            dialog.set_transient_for((Gtk.Window)this.get_root());
            dialog.present();
        });
        enter_password_button.clicked.connect(() => {
            var dialog = new Adw.MessageDialog((Window)this.get_root(), "Enter password for %s".printf(account.bare_jid.to_string()), null);
            var password = new PasswordEntry() { show_peek_icon=true };
            dialog.response.connect((response) => {
                if (response == "connect") {
                    var new_pw = password.text;

                    // TODO indicate saving?
                    account.set_password.begin(new_pw, (obj, res) => {
                        model.reconnect_account(account);
                    });
                }
            });
            dialog.set_default_response("connect");
            dialog.set_extra_child(password);
            dialog.add_response("cancel", _("Cancel"));
            dialog.add_response("connect", _("Connect"));

            dialog.present();
        });

        this.notify["model"].connect(() => {
            model.notify["selected-account"].connect(() => {
                foreach (var binding in bindings) {
                    binding.unbind();
                }

                avatar.model = model.selected_account.avatar_model;
                xmpp_address.subtitle = account.bare_jid.to_string();

                if (alias_entry_changed != 0) local_alias.disconnect(alias_entry_changed);
                local_alias.text = account.alias ?? "";
                alias_entry_changed = local_alias.changed.connect(() => {
                    account.alias = local_alias.text;
                });

                bindings += account.bind_property("enabled", disable_account_button, "label", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                    bool enabled_bool = (bool) from;
                    to = enabled_bool ? _("Disable account") : _("Enable account");
                    return true;
                });
                bindings += account.bind_property("enabled", avatar_menu_box, "visible", BindingFlags.SYNC_CREATE);
                bindings += account.bind_property("enabled", password_change, "visible", BindingFlags.SYNC_CREATE);
                bindings += account.bind_property("enabled", connection_status, "visible", BindingFlags.SYNC_CREATE);
                bindings += model.selected_account.bind_property("connection-state", connection_status, "subtitle", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                    to = get_status_label();
                    return true;
                });
                bindings += model.selected_account.bind_property("connection-error", connection_status, "subtitle", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                    to = get_status_label();
                    return true;
                });
                bindings += model.selected_account.bind_property("connection-error", enter_password_button, "visible", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                    var error = (ConnectionManager.ConnectionError) from;
                    to = error != null && error.source == ConnectionManager.ConnectionError.Source.SASL;
                    return true;
                });

                // Only show avatar removal button if an avatar is set
                var avatar_model = model.selected_account.avatar_model.tiles.get_item(0) as ViewModel.AvatarPictureTileModel;
                avatar_model.notify["image-file"].connect(() => {
                    remove_avatar_button.visible = avatar_model.image_file != null;
                });
                remove_avatar_button.visible = avatar_model.image_file != null;

                model.selected_account.notify["connection-error"].connect(() => {
                    if (model.selected_account.connection_error != null) {
                        connection_status.add_css_class("error");
                    } else {
                        connection_status.remove_css_class("error");
                    }
                });
                if (model.selected_account.connection_error != null) {
                    connection_status.add_css_class("error");
                } else {
                    connection_status.remove_css_class("error");
                }
            });
        });
    }

    private void show_select_avatar() {
        FileChooserNative chooser = new FileChooserNative(_("Select avatar"), (Window)this.get_root(), FileChooserAction.OPEN, _("Select"), _("Cancel"));
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
            model.set_avatar_uri(account, uri);
        });

        chooser.show();
    }

    private void show_remove_account_dialog() {
        Adw.MessageDialog dialog = new Adw.MessageDialog (
                (Window)this.get_root(),
                _("Remove account %s?".printf(account.bare_jid.to_string())),
                "You won't be able to access your conversation history anymore."
        );
        // TODO remove history!
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("remove", "Remove");
        dialog.set_response_appearance("remove", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.response.connect((response) => {
            if (response == "remove") {
                model.remove_account(account);
                // Close the account subpage
                var window = (Adw.PreferencesWindow) this.get_root();
                window.close_subpage();
//                window.pop_subpage();
            }
            dialog.close();
        });
        dialog.present();
    }

    private string get_status_label() {
        string? error_label = get_connection_error_description();
        if (error_label != null) return error_label;

        ConnectionManager.ConnectionState state = model.selected_account.connection_state;
        switch (state) {
            case ConnectionManager.ConnectionState.CONNECTING:
                return _("Connecting…");
            case ConnectionManager.ConnectionState.CONNECTED:
                return _("Connected");
            case ConnectionManager.ConnectionState.DISCONNECTED:
                return _("Disconnected");
        }
        assert_not_reached();
    }

    private string? get_connection_error_description() {
        ConnectionManager.ConnectionError? error = model.selected_account.connection_error;
        if (error == null) return null;

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

public class Dino.Ui.NaturalDirectionBoxLayout : LayoutManager {
    private BoxLayout original;
    private BoxLayout alternative;

    public NaturalDirectionBoxLayout(BoxLayout original) {
        this.original = original;
        if (original.orientation == Orientation.HORIZONTAL) {
            this.alternative = new BoxLayout(Orientation.VERTICAL);
            this.alternative.spacing = this.original.spacing / 2;
        }
    }

    public override SizeRequestMode get_request_mode(Widget widget) {
        return original.orientation == Orientation.HORIZONTAL ? SizeRequestMode.HEIGHT_FOR_WIDTH : SizeRequestMode.WIDTH_FOR_HEIGHT;
    }

    public override void allocate(Widget widget, int width, int height, int baseline) {
        int blind_minimum, blind_natural, blind_minimum_baseline, blind_natural_baseline;
        original.measure(widget, original.orientation, -1, out blind_minimum, out blind_natural, out blind_minimum_baseline, out blind_natural_baseline);
        int for_size = (original.orientation == Orientation.HORIZONTAL ? width : height);
        if (for_size >= blind_minimum) {
            original.allocate(widget, width, height, baseline);
        } else {
            alternative.allocate(widget, width, height, baseline);
        }
    }

    public override void measure(Widget widget, Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        if (for_size == -1) {
            original.measure(widget, orientation, -1, out minimum, out natural, out minimum_baseline, out natural_baseline);
            int alt_minimum, alt_natural, alt_minimum_baseline, alt_natural_baseline;
            alternative.measure(widget, orientation, -1, out alt_minimum, out alt_natural, out alt_minimum_baseline, out alt_natural_baseline);
            if (alt_minimum < minimum && alt_minimum != -1) minimum = alt_minimum;
            if (alt_minimum_baseline < minimum_baseline && alt_minimum_baseline != -1) minimum = alt_minimum_baseline;
        } else {
            Orientation other_orientation = orientation == Orientation.HORIZONTAL ? Orientation.VERTICAL : Orientation.HORIZONTAL;
            int blind_minimum, blind_natural, blind_minimum_baseline, blind_natural_baseline;
            original.measure(widget, other_orientation, -1, out blind_minimum, out blind_natural, out blind_minimum_baseline, out blind_natural_baseline);
            if (for_size >= blind_minimum) {
                original.measure(widget, orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
            } else {
                alternative.measure(widget, orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
            }
        }
    }
}
