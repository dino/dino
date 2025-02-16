using Gdk;
using Gtk;

class Dino.Ui.FixedRatioPicture : Gtk.Widget {
    public int min_width { get; set; default = -1; }
    public int max_width { get; set; default = int.MAX; }
    public int min_height { get; set; default = -1; }
    public int max_height { get; set; default = int.MAX; }
    public File file { get { return inner.file; } set { inner.file = value; } }
    public Gdk.Paintable paintable { get { return inner.paintable; } set { inner.paintable = value; } }
#if GTK_4_8 && VALA_0_58
    public Gtk.ContentFit content_fit { get { return inner.content_fit; } set { inner.content_fit = value; } }
#endif
    private Gtk.Picture inner = new Gtk.Picture();

    construct {
        set_css_name("picture");
        add_css_class("fixed-ratio");
        inner.insert_after(this, null);
        this.notify.connect(queue_resize);
    }

    private void measure_target_size(out int width, out int height) {
        if (width_request != -1 && height_request != -1) {
            width = width_request;
            height = height_request;
            return;
        }
        width = min_width;
        height = min_height;

        if (inner.should_layout()) {
            int child_min = 0, child_nat = 0, child_min_baseline = -1, child_nat_baseline = -1;
            inner.measure(Orientation.HORIZONTAL, -1, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
            width = int.max(child_nat, width);
        }
        width = int.min(width, max_width);

        if (inner.should_layout()) {
            int child_min = 0, child_nat = 0, child_min_baseline = -1, child_nat_baseline = -1;
            inner.measure(Orientation.VERTICAL, width, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
            height = int.max(child_nat, height);
        }

        if (height > max_height) {
            height = max_height;
            width = min_width;

            if (inner.should_layout()) {
                int child_min = 0, child_nat = 0, child_min_baseline = -1, child_nat_baseline = -1;
                inner.measure(Orientation.HORIZONTAL, max_height, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
                width = int.max(child_nat, width);
            }
            width = int.min(width, max_width);
        }
    }

    public override void measure(Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        minimum_baseline = -1;
        natural_baseline = -1;
        int width, height;
        measure_target_size(out width, out height);
        if (orientation == Orientation.HORIZONTAL) {
            minimum = min_width;
            natural = int.max(min_width, int.min(width, max_width));
        } else if (for_size == -1) {
            minimum = min_height;
            natural = int.max(min_height, int.min(height, max_height));
        } else {
            minimum = natural = int.max(min_height, int.min(height * for_size / width, max_height));
        }
    }

    public override void size_allocate(int width, int height, int baseline) {
        if (inner.should_layout()) {
            inner.allocate(width, height, baseline, null);
        }
    }

    public override SizeRequestMode get_request_mode() {
        return SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void dispose() {
        inner.unparent();
        base.dispose();
    }
}