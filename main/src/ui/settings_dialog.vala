using Gtk;
using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Adw.PreferencesWindow {

    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;
    [GtkChild] private unowned CheckButton encryption_radio_undecided;
    [GtkChild] private unowned CheckButton encryption_radio_omemo;
    [GtkChild] private unowned CheckButton encryption_radio_openpgp;
    [GtkChild] private unowned Switch send_button_switch;
    [GtkChild] private unowned Switch enter_newline_switch;
    [GtkChild] private unowned Switch dark_theme;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object();

        typing_switch.active = settings.send_typing;
        marker_switch.active = settings.send_marker;
        notification_switch.active = settings.notifications;
        emoji_switch.active = settings.convert_utf8_smileys;
        encryption_radio_undecided.active = settings.default_encryption == Encryption.UNKNOWN;
        encryption_radio_omemo.active = settings.default_encryption == Encryption.OMEMO;
        encryption_radio_openpgp.active = settings.default_encryption == Encryption.PGP;

        send_button_switch.active = settings.send_button;
        enter_newline_switch.active = settings.enter_newline;
        enter_newline_switch.sensitive = settings.send_button;
        dark_theme.active = settings.dark_theme;
        dark_theme.sensitive = !Adw.StyleManager.get_default().system_supports_color_schemes;

        typing_switch.notify["active"].connect(() => { settings.send_typing = typing_switch.active; } );
        marker_switch.notify["active"].connect(() => { settings.send_marker = marker_switch.active; } );
        notification_switch.notify["active"].connect(() => { settings.notifications = notification_switch.active; } );
        emoji_switch.notify["active"].connect(() => { settings.convert_utf8_smileys = emoji_switch.active; });

        encryption_radio_undecided.notify["active"].connect(() => {
            if (encryption_radio_undecided.active) {
                settings.default_encryption = Encryption.UNKNOWN;
            }
        });

        encryption_radio_omemo.notify["active"].connect(() => {
            if (encryption_radio_omemo.active) {
                settings.default_encryption = Encryption.OMEMO;
            }
        });

        encryption_radio_openpgp.notify["active"].connect(() => {
            if (encryption_radio_openpgp.active) {
                settings.default_encryption = Encryption.PGP;
            }
        });

        send_button_switch.notify["active"].connect(() => { settings.send_button = send_button_switch.active; });
        enter_newline_switch.notify["active"].connect(() => { settings.enter_newline = enter_newline_switch.active; });
        settings.send_button_update.connect((visible) => {
            enter_newline_switch.sensitive = visible;

            if (visible == false) {
                enter_newline_switch.active = visible;
            }
        });
        dark_theme.notify["active"].connect(() => { settings.dark_theme = dark_theme.active; });
    }
}

}
