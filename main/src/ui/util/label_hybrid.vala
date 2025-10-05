using Gee;
using Gtk;

namespace Dino.Ui.Util {

public class LabelHybrid : Widget {

    public Stack stack = new Stack();
    public Label label = new Label("") { max_width_chars=1, ellipsize=Pango.EllipsizeMode.END };
    protected Button button = new Button() { has_frame=false };

    public signal void switched_to_label();
    public signal void switched_to_widget();
    private bool shows_widget = false;

    internal virtual void init(Widget widget) {
        this.layout_manager = new BinLayout();
        stack.set_parent(this);
        button.child = label;
        stack.add_named(button, "label");
        stack.add_named(widget, "widget");

        button.clicked.connect(() => {
            show_widget();
        });
    }

    public void show_widget() {
        stack.visible_child_name = "widget";
        stack.get_child_by_name("widget").grab_focus();
        if (!shows_widget) {
            switched_to_widget();
            shows_widget = true;
        }
    }

    public void show_label() {
        stack.visible_child_name = "label";
        if (shows_widget) {
            switched_to_label();
            shows_widget = false;
        }
    }

    public override void dispose() {
        stack.unparent();
    }
}

public class EntryLabelHybrid : LabelHybrid {

    public string text {
        get { return entry.text; }
        set {
            entry.text = value.dup();
            update_label();
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
                entry_ = new Entry();
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
        Entry? e = widget as Entry;
        if (e == null) return;
        entry = e;
        base.init(entry);
        update_label();

        var key_events = new EventControllerKey();
        key_events.key_released.connect(on_key_released);
        entry.add_controller(key_events);
        entry.changed.connect(update_label);

        var focus_events = new EventControllerFocus();
        focus_events.leave.connect(update_label);
        entry.add_controller(focus_events);
    }

    private void on_key_released(uint keyval) {
        if (keyval == Gdk.Key.Return) {
            show_label();
        }
    }

    private void update_label() {
        if (visibility) {
            label.label = entry.text;
        } else {
            string filler = "";
            for (int i = 0; i < entry.text.length; i++) filler += entry.get_invisible_char().to_string();
            label.label = filler;
        }
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
                combobox_ = new ComboBoxText();
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
        button.clicked.connect(() => {
            combobox.popup();
        });

        var focus_events = new EventControllerFocus();
        focus_events.leave.connect(on_focus_leave);
        combobox.add_controller(focus_events);
    }

    private void on_focus_leave() {
            update_label();
            show_label();
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
            if (hybrid.stack.visible_child_name == "label") return;
            foreach (LabelHybrid h in hybrids) {
                if (h != hybrid) {
                    h.stack.set_visible_child_name("label");
                }
            }
        });
    }
}

}
