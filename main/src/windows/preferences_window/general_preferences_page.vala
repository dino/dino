using Gtk;

public class Dino.Ui.ViewModel.GeneralPreferencesPage : Object {
    public bool send_typing { get; set; }
    public bool send_marker { get; set; }
    public bool notifications { get; set; }
    public bool convert_emojis { get; set; }
}

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/general_preferences_page.ui")]
public class Dino.Ui.GeneralPreferencesPage : Adw.PreferencesPage {
    [GtkChild] private unowned Adw.SwitchRow typing_row;
    [GtkChild] private unowned Adw.SwitchRow marker_row;
    [GtkChild] private unowned Adw.SwitchRow notification_row;
    [GtkChild] private unowned Adw.SwitchRow emoji_row;

    public ViewModel.GeneralPreferencesPage model { get; set; default = new ViewModel.GeneralPreferencesPage(); }
    private Binding[] model_bindings = new Binding[0];

    construct {
        this.notify["model"].connect(on_model_changed);
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
                model.bind_property("convert-emojis", emoji_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL)
            };
        } else {
            model_bindings = new Binding[0];
        }
    }
}
