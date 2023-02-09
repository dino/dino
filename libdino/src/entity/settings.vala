namespace Dino.Entities {

public class Settings : Object {

    private Database db;

    public Settings.from_db(Database db) {
        this.db = db;

        send_typing_ = col_to_bool_or_default("send_typing", true);
        send_marker_ = col_to_bool_or_default("send_marker", true);
        notifications_ = col_to_bool_or_default("notifications", true);
        convert_utf8_smileys_ = col_to_bool_or_default("convert_utf8_smileys", true);
        check_spelling = col_to_bool_or_default("check_spelling", true);
        unread_count_ = col_to_bool_or_default("unread_count", true);
        unread_count_notifications_ = col_to_bool_or_default("unread_count_notifications", true);
    }

    private bool col_to_bool_or_default(string key, bool def) {
        string? val = db.settings.select({db.settings.value}).with(db.settings.key, "=", key)[db.settings.value];
        return val != null ? bool.parse(val) : def;
    }

    private bool send_typing_;
    public bool send_typing {
        get { return send_typing_; }
        set {
            db.settings.upsert()
                    .value(db.settings.key, "send_typing", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            send_typing_ = value;
        }
    }

    private bool send_marker_;
    public bool send_marker {
        get { return send_marker_; }
        set {
            db.settings.upsert()
                    .value(db.settings.key, "send_marker", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            send_marker_ = value;
        }
    }

    private bool notifications_;
    public bool notifications {
        get { return notifications_; }
        set {
            db.settings.upsert()
                    .value(db.settings.key, "notifications", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            notifications_ = value;
        }
    }

    private bool convert_utf8_smileys_;
    public bool convert_utf8_smileys {
        get { return convert_utf8_smileys_; }
        set {
            db.settings.upsert()
                    .value(db.settings.key, "convert_utf8_smileys", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            convert_utf8_smileys_ = value;
        }
    }

    // There is currently no spell checking for GTK4, thus there is currently no UI for this setting.
    private bool check_spelling_;
    public bool check_spelling {
        get { return check_spelling_; }
        set {
            db.settings.upsert()
                .value(db.settings.key, "check_spelling", true)
                .value(db.settings.value, value.to_string())
                .perform();
            check_spelling_ = value;
        }
    }

    private bool unread_count_;
    public bool unread_count {
        get { return unread_count_; }
        set {
            db.settings.upsert()
                .value(db.settings.key, "unread_count", true)
                .value(db.settings.value, value.to_string())
                .perform();
            unread_count_ = value;
        }
    }

    private bool unread_count_notifications_;
    public bool unread_count_notifications {
        get { return unread_count_notifications_; }
        set {
            db.settings.upsert()
                .value(db.settings.key, "unread_count_notifications", true)
                .value(db.settings.value, value.to_string())
                .perform();
            unread_count_notifications_ = value;
        }
    }
}

}
