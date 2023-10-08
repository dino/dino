using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

public class Dino.Ui.ViewModel.ConversationDetails : Object {
    public signal void pin_changed();
    public signal void block_changed(BlockActions action);
    public signal void notification_flipped();
    public signal void notification_changed(NotificationSetting setting);

    public enum BlockActions {
        USER,
        DOMAIN,
        UNBLOCK,
        TOGGLE
    }

    public enum NotificationOptions {
        ON_OFF,
        ON_HIGHLIGHT_OFF
    }

    public enum NotificationSetting {
        DEFAULT,
        ON,
        HIGHLIGHT,
        OFF
    }

    public ViewModel.CompatAvatarPictureModel avatar { get; set; }
    public string name { get; set; }
    public bool pinned { get; set; }

    public NotificationSetting notification { get; set; }
    public NotificationOptions notification_options { get; set; }
    public bool notification_is_default { get; set; }

    public bool show_blocked { get; set; }
    public bool blocked { get; set; }
    public bool domain_blocked { get; set; }

    public GLib.ListStore preferences_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public GLib.ListStore about_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public GLib.ListStore encryption_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public GLib.ListStore settings_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public GLib.ListStore room_configuration_rows { get; set; }
}

public class Dino.Ui.Model.ConversationDetails : Object {
    public Conversation conversation { get; set; }
    public Dino.Model.ConversationDisplayName display_name { get; set; }
    public DataForms.DataForm? data_form { get; set; }
    public string? data_form_bak;
    public bool blocked { get; set; }
    public bool domain_blocked { get; set; }
}
