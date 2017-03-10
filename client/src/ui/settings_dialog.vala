using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/settings_dialog.ui")]
class SettingsDialog : Dialog {

    [GtkChild] private CheckButton marker_checkbutton;
    [GtkChild] private CheckButton emoji_checkbutton;

    Dino.Settings settings = Dino.Settings.instance();

    public SettingsDialog() {
        Object(use_header_bar : 1);

        marker_checkbutton.active = settings.send_read;
        emoji_checkbutton.active = settings.convert_utf8_smileys;

        marker_checkbutton.toggled.connect(() => { settings.send_read = marker_checkbutton.active; });
        emoji_checkbutton.toggled.connect(() => { settings.convert_utf8_smileys = emoji_checkbutton.active; });
    }
}

}