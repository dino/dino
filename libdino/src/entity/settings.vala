namespace Dino.Entities {

public class Settings : Object {

    private Database db;

    public Settings.from_db(Database db) {
        this.db = db;

        send_typing_ = col_to_bool_or_default("send_typing", true);
        send_marker_ = col_to_bool_or_default("send_marker", true);
        notifications_ = col_to_bool_or_default("notifications", true);
        sound_ = col_to_bool_or_default("sound", true);
        convert_utf8_smileys_ = col_to_bool_or_default("convert_utf8_smileys", true);

        current_width = col_to_int_or_default("window_width", 1200);
        current_height = col_to_int_or_default("window_height", 700);
        is_maximized = col_to_bool_or_default("window_maximized", false);
        position_x = col_to_int_or_default("window_position_x", -1);
        position_y = col_to_int_or_default("window_position_y", -1);
    }

    private bool col_to_bool_or_default(string key, bool def) {
        string? val = db.settings.select({db.settings.value}).with(db.settings.key, "=", key)[db.settings.value];
        return val != null ? bool.parse(val) : def;
    }

    private int col_to_int_or_default(string key, int def) {
        string? val = db.settings.select({db.settings.value}).with(db.settings.key, "=", key)[db.settings.value];
        return val != null ? int.parse(val) : def;
    }

    private bool send_typing_;
    public bool send_typing {
        get { return send_typing_; }
        set {
            db.settings.insert().or("REPLACE").value(db.settings.key, "send_typing").value(db.settings.value, value.to_string()).perform();
            send_typing_ = value;
        }
    }

    private bool send_marker_;
    public bool send_marker {
        get { return send_marker_; }
        set {
            db.settings.insert().or("REPLACE").value(db.settings.key, "send_marker").value(db.settings.value, value.to_string()).perform();
            send_marker_ = value;
        }
    }

    private bool notifications_;
    public bool notifications {
        get { return notifications_; }
        set {
            db.settings.insert().or("REPLACE").value(db.settings.key, "notifications").value(db.settings.value, value.to_string()).perform();
            notifications_ = value;
        }
    }

    private bool sound_;
    public bool sound {
        get { return sound_; }
        set {
            db.settings.insert().or("REPLACE").value(db.settings.key, "sound").value(db.settings.value, value.to_string()).perform();
            sound_ = value;
        }
    }

    private bool convert_utf8_smileys_;
    public bool convert_utf8_smileys {
        get { return convert_utf8_smileys_; }
        set {
            db.settings.insert().or("REPLACE").value(db.settings.key, "convert_utf8_smileys").value(db.settings.value, value.to_string()).perform();
            convert_utf8_smileys_ = value;
        }
    }

    private int current_width_;
    public int current_width {
        get { return current_width_; }
        set {
            if (value == current_width_) return;
            db.settings.insert().or("REPLACE").value(db.settings.key, "window_width").value(db.settings.value, value.to_string()).perform();
            current_width_ = value;
        }
    }

    private int current_height_;
    public int current_height {
        get { return current_height_; }
        set {
            if (value == current_height_) return;
            db.settings.insert().or("REPLACE").value(db.settings.key, "window_height").value(db.settings.value, value.to_string()).perform();
            current_height_ = value;
        }
    }

    private bool is_maximized_;
    public bool is_maximized {
        get { return is_maximized_; }
        set {
            if (value == is_maximized_) return;
            db.settings.insert().or("REPLACE").value(db.settings.key, "window_maximized").value(db.settings.value, value.to_string()).perform();
            is_maximized_ = value;
        }
    }

    private int position_x_;
    public int position_x {
        get { return position_x_; }
        set {
            if (value == position_x_) return;
            db.settings.insert().or("REPLACE").value(db.settings.key, "window_position_x").value(db.settings.value, value.to_string()).perform();
            position_x_ = value;
        }
    }

    private int position_y_;
    public int position_y {
        get { return position_y_; }
        set {
            if (value == position_y_) return;
            db.settings.insert().or("REPLACE").value(db.settings.key, "window_position_y").value(db.settings.value, value.to_string()).perform();
            position_y_ = value;
        }
    }
}

}
