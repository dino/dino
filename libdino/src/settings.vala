namespace Dino {

public class Settings {

    private GLib.Settings gsettings;

    public bool send_typing {
        get { return gsettings.get_boolean("send-typing"); }
        set { gsettings.set_boolean("send-typing", value); }
    }

    public bool send_marker {
        get { return gsettings.get_boolean("send-marker"); }
        set { gsettings.set_boolean("send-marker", value); }
    }

    public bool notifications {
        get { return gsettings.get_boolean("notifications"); }
        set { gsettings.set_boolean("notifications", value); }
    }

    public bool convert_utf8_smileys {
        get { return gsettings.get_boolean("convert-utf8-smileys"); }
        set { gsettings.set_boolean("convert-utf8-smileys", value); }
    }

    public Settings(GLib.Settings gsettings) {
        this.gsettings = gsettings;
    }

    public static Settings instance() {
        SettingsSchemaSource sss = SettingsSchemaSource.get_default();
        SettingsSchema? schema = sss.lookup("org.dino-im", true);
        return new Settings(new GLib.Settings.full(schema, null, null));
    }
}

}
