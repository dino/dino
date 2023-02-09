using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Adw.PreferencesWindow {

    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;
    [GtkChild] private unowned Switch check_spelling_switch;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object();

        typing_switch.active = settings.send_typing;
        marker_switch.active = settings.send_marker;
        notification_switch.active = settings.notifications;
        emoji_switch.active = settings.convert_utf8_smileys;
        check_spelling_switch.active = settings.check_spelling;

        typing_switch.activate.connect(() => { settings.send_typing = typing_switch.active; } );
        marker_switch.activate.connect(() => { settings.send_marker = marker_switch.active; } );
        notification_switch.activate.connect(() => { settings.notifications = notification_switch.active; } );
        emoji_switch.activate.connect(() => { settings.convert_utf8_smileys = emoji_switch.active; });
        check_spelling_switch.activate.connect(() => { settings.check_spelling = check_spelling_switch.active; });
    }
}

}
