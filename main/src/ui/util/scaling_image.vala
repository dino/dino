using Gdk;
using Gtk;

namespace Dino.Ui {

class FixedRatioLayout : Gtk.LayoutManager {
    public int min_width { get; set; default = 0; }
    public int target_width { get; set; default = -1; }
    public int max_width { get; set; default = int.MAX; }
    public int min_height { get; set; default = 0; }
    public int target_height { get; set; default = -1; }
    public int max_height { get; set; default = int.MAX; }

    public FixedRatioLayout() {
        this.notify.connect(layout_changed);
    }

    private void measure_target_size(Gtk.Widget widget, out int width, out int height) {
        if (target_width != -1 && target_height != -1) {
            width = target_width;
            height = target_height;
            return;
        }
        Widget child;
        width = min_width;
        height = min_height;

        child = widget.get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                int child_min = 0;
                int child_nat = 0;
                int child_min_baseline = -1;
                int child_nat_baseline = -1;
                child.measure(Orientation.HORIZONTAL, -1, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
                width = int.max(child_nat, width);
            }
            child = child.get_next_sibling();
        }
        width = int.min(width, max_width);

        child = widget.get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                int child_min = 0;
                int child_nat = 0;
                int child_min_baseline = -1;
                int child_nat_baseline = -1;
                child.measure(Orientation.VERTICAL, width, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
                height = int.max(child_nat, height);
            }
            child = child.get_next_sibling();
        }

        if (height > max_height) {
            height = max_height;
            width = min_width;

            child = widget.get_first_child();
            while (child != null) {
                if (child.should_layout()) {
                    int child_min = 0;
                    int child_nat = 0;
                    int child_min_baseline = -1;
                    int child_nat_baseline = -1;
                    child.measure(Orientation.HORIZONTAL, max_height, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
                    width = int.max(child_nat, width);
                }
                child = child.get_next_sibling();
            }
            width = int.min(width, max_width);
        }
    }

    public override void measure(Gtk.Widget widget, Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        minimum_baseline = -1;
        natural_baseline = -1;
        int width, height;
        measure_target_size(widget, out width, out height);
        if (orientation == Orientation.HORIZONTAL) {
            minimum = min_width;
            natural = width;
        } else if (for_size == -1) {
            minimum = min_height;
            natural = height;
        } else {
            minimum = natural = height * for_size / width;
        }
    }

    public override void allocate(Gtk.Widget widget, int width, int height, int baseline) {
        Widget child = widget.get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                child.allocate(width, height, baseline, null);
            }
            child = child.get_next_sibling();
        }
    }

    public override SizeRequestMode get_request_mode(Gtk.Widget widget) {
        return SizeRequestMode.HEIGHT_FOR_WIDTH;
    }
}

class FixedRatioPicture : Gtk.Widget {
    public int min_width { get { return layout.min_width; } set { layout.min_width = value; } }
    public int target_width { get { return layout.target_width; } set { layout.target_width = value; } }
    public int max_width { get { return layout.max_width; } set { layout.max_width = value; } }
    public int min_height { get { return layout.min_height; } set { layout.min_height = value; } }
    public int target_height { get { return layout.target_height; } set { layout.target_height = value; } }
    public int max_height { get { return layout.max_height; } set { layout.max_height = value; } }
    public File file { get { return inner.file; } set { inner.file = value; } }
    public Gdk.Paintable paintable { get { return inner.paintable; } set { inner.paintable = value; } }
#if GTK_4_8 && VALA_0_58
    public Gtk.ContentFit content_fit { get { return inner.content_fit; } set { inner.content_fit = value; } }
#endif
    private Gtk.Picture inner = new Gtk.Picture();
    private FixedRatioLayout layout = new FixedRatioLayout();

    public FixedRatioPicture() {
        layout_manager = layout;
        inner.insert_after(this, null);
    }

    public override void dispose() {
        inner.unparent();
        base.dispose();
    }
}
}