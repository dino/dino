using Gtk;
using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Dialog {

    [GtkChild] private unowned CheckButton typing_checkbutton;
    [GtkChild] private unowned CheckButton marker_checkbutton;
    [GtkChild] private unowned CheckButton notification_checkbutton;
    [GtkChild] private unowned CheckButton emoji_checkbutton;
    [GtkChild] private unowned CheckButton check_spelling_checkbutton;
    [GtkChild] private unowned RadioButton encryption_radio_undecided;
    [GtkChild] private unowned RadioButton encryption_radio_omemo;
    [GtkChild] private unowned RadioButton encryption_radio_openpgp;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);

        typing_checkbutton.active = settings.send_typing;
        marker_checkbutton.active = settings.send_marker;
        notification_checkbutton.active = settings.notifications;
        emoji_checkbutton.active = settings.convert_utf8_smileys;
        check_spelling_checkbutton.active = settings.check_spelling;
        encryption_radio_undecided.active = settings.default_encryption == Encryption.UNKNOWN;
        encryption_radio_omemo.active = settings.default_encryption == Encryption.OMEMO;
        encryption_radio_openpgp.active = settings.default_encryption == Encryption.PGP;

        typing_checkbutton.toggled.connect(() => { settings.send_typing = typing_checkbutton.active; } );
        marker_checkbutton.toggled.connect(() => { settings.send_marker = marker_checkbutton.active; } );
        notification_checkbutton.toggled.connect(() => { settings.notifications = notification_checkbutton.active; } );
        emoji_checkbutton.toggled.connect(() => { settings.convert_utf8_smileys = emoji_checkbutton.active; });
        check_spelling_checkbutton.toggled.connect(() => { settings.check_spelling = check_spelling_checkbutton.active; });

        encryption_radio_undecided.toggled.connect(() => {
            if (encryption_radio_undecided.active) {
                settings.default_encryption = Encryption.UNKNOWN;
            }
        });

        encryption_radio_omemo.toggled.connect(() => {
            if (encryption_radio_omemo.active) {
                settings.default_encryption = Encryption.OMEMO;
            }
        });

        encryption_radio_openpgp.toggled.connect(() => {
            if (encryption_radio_openpgp.active) {
                settings.default_encryption = Encryption.PGP;
            }
        });
    }
}

}
