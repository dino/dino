using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class Config : Object {

    public Database db { get; private set; }

    public Config(Database db) {
        this.db = db;

        window_maximize = col_to_bool_or_default("window_maximized", false);
        window_width = col_to_int_or_default("window_width", 1200);
        window_height = col_to_int_or_default("window_height", 700);
    }

    private bool window_maximize_;
    public bool window_maximize {
        get { return window_maximize_; }
        set {
            if (value == window_maximize_) return;
            db.settings.upsert()
                    .value(db.settings.key, "window_maximized", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            window_maximize_ = value;
        }
    }

    public int window_height_;
    public int window_height {
        get { return window_height_; }
        set {
            if (value == window_height_) return;
            db.settings.upsert()
                    .value(db.settings.key, "window_height", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            window_height_ = value;
        }
    }

    public int window_width_;
    public int window_width {
        get { return window_width_; }
        set {
            if (value == window_width_) return;
            db.settings.upsert()
                    .value(db.settings.key, "window_width", true)
                    .value(db.settings.value, value.to_string())
                    .perform();
            window_width_ = value;
        }
    }

    private bool col_to_bool_or_default(string key, bool def) {
        string? val = db.settings.select({db.settings.value}).with(db.settings.key, "=", key)[db.settings.value];
        return val != null ? bool.parse(val) : def;
    }

    private int col_to_int_or_default(string key, int def) {
        string? val = db.settings.select({db.settings.value}).with(db.settings.key, "=", key)[db.settings.value];
        return val != null ? int.parse(val) : def;
    }
}

}
