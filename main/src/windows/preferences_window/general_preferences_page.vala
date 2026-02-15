using Gtk;

public class Dino.Ui.ViewModel.GeneralPreferencesPage : Object {
    public bool send_typing { get; set; }
    public bool send_marker { get; set; }
    public bool notifications { get; set; }
    public bool convert_emojis { get; set; }
    public bool run_in_background { get; set; }
    public bool autostart { get; set; }
}

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/general_preferences_page.ui")]
public class Dino.Ui.GeneralPreferencesPage : Adw.PreferencesPage {
    [GtkChild] private unowned Adw.SwitchRow typing_row;
    [GtkChild] private unowned Adw.SwitchRow marker_row;
    [GtkChild] private unowned Adw.SwitchRow notification_row;
    [GtkChild] private unowned Adw.SwitchRow emoji_row;
    [GtkChild] private unowned Adw.PreferencesGroup desktop_environment_group;
    [GtkChild] private unowned Adw.SwitchRow run_in_background_row;
    [GtkChild] private unowned Adw.SwitchRow autostart_row;

    public ViewModel.GeneralPreferencesPage model { get; set; default = new ViewModel.GeneralPreferencesPage(); }
    private Binding[] model_bindings = new Binding[0];
#if LIBPORTAL
    private Xdp.Portal portal = new Xdp.Portal();
#endif

    construct {
        this.notify["model"].connect(on_model_changed);
#if LIBPORTAL
        run_in_background_row.notify["active"].connect(on_run_in_background_toggled);
        autostart_row.notify["active"].connect(on_autostart_toggled);
#else
        desktop_environment_group.visible = false;
#endif
    }

    private void on_model_changed() {
        foreach (Binding binding in model_bindings) {
            binding.unbind();
        }
        if (model != null) {
            model_bindings = new Binding[] {
                model.bind_property("send-typing", typing_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("send-marker", marker_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("notifications", notification_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("convert-emojis", emoji_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("run-in-background", run_in_background_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("autostart", autostart_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
            };
        } else {
            model_bindings = new Binding[0];
        }
    }

#if LIBPORTAL
    private void request_background_permissions() {
        if (get_native () == null)
            return;

        Xdp.Parent parent = Xdp.parent_new_gtk ((Gtk.Window) get_native ());

        GLib.GenericArray<weak string> commands = new GLib.GenericArray<weak string>();
        commands.add ("dino");
        commands.add ("--gapplication-service");

        Xdp.BackgroundFlags flags = Xdp.BackgroundFlags.NONE;
        if (autostart_row.active) {
            flags |= Xdp.BackgroundFlags.AUTOSTART;
        }

        portal.request_background.begin (
            parent,
            "Allow Dino to continue receive messages and calls",
            commands,
            flags,
            null,
            callback
        );
    }

    private void on_run_in_background_toggled() {
        request_background_permissions();
    }

    private void on_autostart_toggled() {
        request_background_permissions();
    }

    private void callback (GLib.Object? obj, GLib.AsyncResult res) {
        try {
            bool? success;
            success = portal.request_background.end (res);

            if (success) {
                warning ("Portol request successful");
                portal.set_background_status("Listening for messages and calls",
                                             null);
            }
            else {
                warning ("Request failed");
            }

            if (success == null) {
                critical ("Background portal cancelled");
                return;
            }
        }
        catch (Error e) {
            critical (e.message);
        }
    }
#endif
}
