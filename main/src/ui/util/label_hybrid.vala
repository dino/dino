using Gee;
using Gtk;

namespace Dino.Ui.Util {

public class LabelHybrid : Stack {

    public Label label = new Label("") { visible=true };
    protected Button button = new Button() { relief=ReliefStyle.NONE, visible=true };

    public void init(Widget widget) {
        button.add(label);
        add_named(button, "label");
        add_named(widget, "widget");

        button.clicked.connect(() => {
            show_widget();
        });
    }

    public void show_widget() {
        visible_child_name = "widget";
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
            label.label = value;
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

    private Entry entry;

    public EntryLabelHybrid(Entry? e = null) {
        entry = e ?? new Entry() { visible=true };
        init(entry);
        update_label();

        entry.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.Return) {
                show_label();
            } else {
                label.label = entry.text;
            }
            return false;
        });
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

    private ComboBoxText combobox;

    public ComboBoxTextLabelHybrid(ComboBoxText? cb = null) {
        combobox = cb ?? new ComboBoxText() { visible=true };
        init(combobox);
        update_label();

        combobox.changed.connect(() => {
            update_label();
            show_label();
        });
        button.clicked.connect(() => {
            combobox.popup();
        });
    }

    public void append(string id, string text) { combobox.append(id, text); }
    public string get_active_text() { return combobox.get_active_text(); }

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