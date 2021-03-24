using Gee;
using Gtk;

namespace Dino.Ui.Util {

public class LabelHybrid : Stack {

    public Label label = new Label("") {
        visible = true,
        max_width_chars = 0,
        ellipsize = Pango.EllipsizeMode.END
    };
    protected Button button = new Button() { relief=ReliefStyle.NONE, visible=true };

    internal virtual void init(Widget widget) {
        button.add(label);
        add_named(button, "label");
        add_named(widget, "widget");

        button.clicked.connect(() => {
            show_widget();
        });
    }

    public void show_widget() {
        visible_child_name = "widget";
        get_child_by_name("widget").grab_focus();
    }

    public void show_label() {
        visible_child_name = "label";
    }
}

public class EntryLabelHybrid : LabelHybrid {

    public string text {
        get { return entry.text; }
        set {
            entry.text = value;
            set_label_label(value);
        }
    }

    public bool visibility {
        get { return entry.visibility; }
        set { entry.visibility = value; }
    }

    public float xalign {
        get { return label.xalign; }
        set {
            label.xalign = value;
            entry.set_alignment(value);
        }
    }

    private Entry? entry_;
    public Entry entry {
        get {
            if (entry_ == null) {
                entry_ = new Entry() { visible=true };
                init(entry_);
            }
            return entry_;
        }
        set { entry_ = value; }
    }

    public EntryLabelHybrid.wrap(Entry e) {
        init(e);
    }

    internal override void init(Widget widget) {
        Entry? e = widget as Entry; if (e == null) return;
        entry = e;
        base.init(entry);
        update_label();

        entry.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.Return) {
                show_label();
            } else {
                set_label_label(entry.text);
            }
            return false;
        });
        entry.focus_out_event.connect(() => {
            show_label();
            return false;
        });
    }

    private void set_label_label(string value) {
        if (visibility) {
            label.label = value;
        } else {
            string filler = "";
            for (int i = 0; i < value.length; i++) filler += entry.get_invisible_char().to_string();
            label.label = filler;
        }
    }

    private void update_label() {
        text = text;
    }
}

public class ComboBoxTextLabelHybrid : LabelHybrid {

    public int active {
        get { return combobox.active; }
        set { combobox.active = value; }
    }

    public float xalign {
        get { return label.xalign; }
        set { label.xalign = value; }
    }

    private ComboBoxText combobox_;
    public ComboBoxText combobox {
        get {
            if (combobox_ == null) {
                combobox_ = new ComboBoxText() { visible=true };
                init(combobox_);
            }
            return combobox_;
        }
        set { combobox_ = combobox; }
    }

    public ComboBoxTextLabelHybrid.wrap(ComboBoxText cb) {
        combobox_ = cb;
        init(cb);
    }

    public void append(string id, string text) { combobox.append(id, text); }
    public string get_active_text() { return combobox.get_active_text(); }

    internal override void init(Widget widget) {
        ComboBoxText? combobox = widget as ComboBoxText; if (combobox == null) return;
        base.init(combobox);
        update_label();

        combobox.changed.connect(() => {
            update_label();
            show_label();
        });
        combobox.focus_out_event.connect(() => {
            update_label();
            show_label();
            return false;
        });
        button.clicked.connect(() => {
            combobox.popup();
        });
    }

    private void update_label() {
        label.label = combobox.get_active_text();
    }
}

public class LabelHybridGroup {

    private Gee.List<LabelHybrid> hybrids = new ArrayList<LabelHybrid>();

    public void add(LabelHybrid hybrid) {
        hybrids.add(hybrid);

        hybrid.notify["visible-child-name"].connect(() => {
            if (hybrid.visible_child_name == "label") return;
            foreach (LabelHybrid h in hybrids) {
                if (h != hybrid) {
                    h.set_visible_child_name("label");
                }
            }
        });
    }
}

}
