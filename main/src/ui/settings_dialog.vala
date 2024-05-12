using Gtk;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/settings_dialog.ui")]
class SettingsDialog : Adw.PreferencesWindow {

    [GtkChild] private unowned Switch typing_switch;
    [GtkChild] private unowned Switch marker_switch;
    [GtkChild] private unowned Switch notification_switch;
    [GtkChild] private unowned Switch emoji_switch;
    [GtkChild] private unowned Switch unread_count;
    [GtkChild] private unowned Switch unread_count_notifications;

    Dino.Entities.Settings settings = Dino.Application.get_default().settings;

    public SettingsDialog() {
        Object();

        typing_switch.active = settings.send_typing;
        marker_switch.active = settings.send_marker;
        notification_switch.active = settings.notifications;
        emoji_switch.active = settings.convert_utf8_smileys;
        unread_count.active = settings.unread_count;
        unread_count_notifications.active = settings.unread_count_notifications;

        typing_switch.notify["active"].connect(() => { settings.send_typing = typing_switch.active; } );
        marker_switch.notify["active"].connect(() => { settings.send_marker = marker_switch.active; } );
        notification_switch.notify["active"].connect(() => { settings.notifications = notification_switch.active; } );
        emoji_switch.notify["active"].connect(() => { settings.convert_utf8_smileys = emoji_switch.active; });
        unread_count.notify["active"].connect(() => { settings.unread_count = unread_count.active; });
        unread_count_notifications.notify["active"].connect(() => { settings.unread_count_notifications = unread_count_notifications.active; });
    }
}

}
