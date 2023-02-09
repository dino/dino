using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Adw.PreferencesWindow {

<<<<<<< HEAD
    [GtkChild] private unowned CheckButton typing_checkbutton;
    [GtkChild] private unowned CheckButton marker_checkbutton;
    [GtkChild] private unowned CheckButton notification_checkbutton;
    [GtkChild] private unowned CheckButton emoji_checkbutton;
    [GtkChild] private unowned CheckButton check_spelling_checkbutton;
    [GtkChild] private unowned CheckButton unread_count_checkbutton;
    [GtkChild] private unowned CheckButton unread_count_notifications_checkbutton;
=======
    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;
>>>>>>> master

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object();

<<<<<<< HEAD
        typing_checkbutton.active = settings.send_typing;
        marker_checkbutton.active = settings.send_marker;
        notification_checkbutton.active = settings.notifications;
        emoji_checkbutton.active = settings.convert_utf8_smileys;
        check_spelling_checkbutton.active = settings.check_spelling;
        unread_count_checkbutton.active = settings.unread_count;
        unread_count_notifications_checkbutton.active = settings.unread_count_notifications;

        typing_checkbutton.toggled.connect(() => { settings.send_typing = typing_checkbutton.active; } );
        marker_checkbutton.toggled.connect(() => { settings.send_marker = marker_checkbutton.active; } );
        notification_checkbutton.toggled.connect(() => { settings.notifications = notification_checkbutton.active; } );
        emoji_checkbutton.toggled.connect(() => { settings.convert_utf8_smileys = emoji_checkbutton.active; });
        check_spelling_checkbutton.toggled.connect(() => { settings.check_spelling = check_spelling_checkbutton.active; });
        unread_count_checkbutton.toggled.connect(() => { settings.unread_count = unread_count_checkbutton.active; });
        unread_count_notifications_checkbutton.toggled.connect(() => { settings.unread_count_notifications = unread_count_notifications_checkbutton.active; });
=======
        typing_switch.active = settings.send_typing;
        marker_switch.active = settings.send_marker;
        notification_switch.active = settings.notifications;
        emoji_switch.active = settings.convert_utf8_smileys;

        typing_switch.notify["active"].connect(() => { settings.send_typing = typing_switch.active; } );
        marker_switch.notify["active"].connect(() => { settings.send_marker = marker_switch.active; } );
        notification_switch.notify["active"].connect(() => { settings.notifications = notification_switch.active; } );
        emoji_switch.notify["active"].connect(() => { settings.convert_utf8_smileys = emoji_switch.active; });
>>>>>>> master
    }
}

}
