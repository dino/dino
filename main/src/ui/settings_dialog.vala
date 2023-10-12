using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Adw.PreferencesWindow {

    [GtkChild] private unowned SpinButton zoom_spinbutton;
    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;
    public Adjustment zoom_spinbutton_config;
    public SettingsDialog() {
        Object();

        typing_switch.active = settings.send_typing;
        marker_switch.active = settings.send_marker;
        notification_switch.active = settings.notifications;
        emoji_switch.active = settings.convert_utf8_smileys;
        zoom_spinbutton_config = new Adjustment((double) settings.zoom_level, 0.0, 300.0, 1.0, 5.0, 0.0);
        zoom_spinbutton.set_adjustment(zoom_spinbutton_config);

        typing_switch.notify["active"].connect(() => { settings.send_typing = typing_switch.active; } );
        marker_switch.notify["active"].connect(() => { settings.send_marker = marker_switch.active; } );
        notification_switch.notify["active"].connect(() => { settings.notifications = notification_switch.active; } );
        emoji_switch.notify["active"].connect(() => { settings.convert_utf8_smileys = emoji_switch.active; });
        zoom_spinbutton.value_changed.connect(() => { settings.zoom_level = zoom_spinbutton.get_value_as_int(); });
    }
}

}
