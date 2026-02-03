using Gtk;

public class Dino.Ui.ViewModel.GeneralPreferencesPage : Object {
    public bool send_typing { get; set; }
    public bool send_marker { get; set; }
    public bool notifications { get; set; }
    public bool convert_emojis { get; set; }
    public bool publish_tune { get; set; }
}

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/general_preferences_page.ui")]
public class Dino.Ui.GeneralPreferencesPage : Adw.PreferencesPage {
    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;
    [GtkChild] private unowned Switch tune_switch;

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
                model.bind_property("send-typing", typing_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("send-marker", marker_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("notifications", notification_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("convert-emojis", emoji_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("publish-tune", tune_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL)
            };
        } else {
            model_bindings = new Binding[0];
        }
    }
}
