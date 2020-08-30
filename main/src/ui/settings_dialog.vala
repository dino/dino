using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Dialog {

    [GtkChild] private CheckButton typing_checkbutton;
    [GtkChild] private CheckButton marker_checkbutton;
    [GtkChild] private CheckButton notification_checkbutton;
    [GtkChild] private CheckButton emoji_checkbutton;
    [GtkChild] private CheckButton omemo_default_checkbutton;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);

        typing_checkbutton.active = settings.send_typing;
        marker_checkbutton.active = settings.send_marker;
        notification_checkbutton.active = settings.notifications;
        emoji_checkbutton.active = settings.convert_utf8_smileys;
        omemo_default_checkbutton.active = settings.omemo_default;

        typing_checkbutton.toggled.connect(() => { settings.send_typing = typing_checkbutton.active; } );
        marker_checkbutton.toggled.connect(() => { settings.send_marker = marker_checkbutton.active; } );
        notification_checkbutton.toggled.connect(() => { settings.notifications = notification_checkbutton.active; } );
        emoji_checkbutton.toggled.connect(() => { settings.convert_utf8_smileys = emoji_checkbutton.active; });
        omemo_default_checkbutton.toggled.connect(() => { settings.omemo_default = omemo_default_checkbutton.active; });
    }
}

}
