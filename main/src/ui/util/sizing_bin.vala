using Gtk;

namespace Dino.Ui {
public class SizingBin : Widget {
    public int min_width { get; set; default = -1; }
    public int target_width { get; set; default = -1; }
    public int max_width { get; set; default = -1; }
    public int min_height { get; set; default = -1; }
    public int target_height { get; set; default = -1; }
    public int max_height { get; set; default = -1; }

    public override void compute_expand_internal(out bool hexpand, out bool vexpand) {
        hexpand = false;
        vexpand = false;
        Widget child = get_first_child();
        while (child != null) {
            hexpand = hexpand || child.compute_expand(Orientation.HORIZONTAL);
            vexpand = vexpand || child.compute_expand(Orientation.VERTICAL);
            child = child.get_next_sibling();
        }
    }

    public override void size_allocate(int width, int height, int baseline) {
        if (max_height != -1) height = int.min(height, max_height);
        if (max_width != -1) width = int.min(width, max_width);
        Widget child = get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                child.allocate(width, height, baseline, null);
            }
            child = child.get_next_sibling();
        }
    }

    public override void measure(Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        if (orientation == Orientation.HORIZONTAL) {
            minimum = min_width;
            natural = target_width;
        } else {
            minimum = min_height;
            natural = target_height;
        }
        minimum_baseline = -1;
        natural_baseline = -1;
        Widget child = get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                int child_min = 0;
                int child_nat = 0;
                int child_min_baseline = -1;
                int child_nat_baseline = -1;
                child.measure(orientation, for_size, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
                minimum = int.max(minimum, child_min);
                natural = int.max(natural, child_nat);
                if (child_min_baseline > 0) {
                    minimum_baseline = int.max(minimum_baseline, child_min_baseline);
                }
                if (child_nat_baseline > 0) {
                    natural_baseline = int.max(natural_baseline, child_nat_baseline);
                }
            }
            child = child.get_next_sibling();
        }
        if (orientation == Orientation.HORIZONTAL) {
            if (max_width != -1) natural = int.min(natural, max_width);
        } else {
            if (max_height != -1) natural = int.min(natural, max_height);
        }
        natural = int.max(natural, minimum);
    }

    public override SizeRequestMode get_request_mode() {
        Widget child = get_first_child();
        if (child != null) {
            return child.get_request_mode();
        }
        return SizeRequestMode.CONSTANT_SIZE;
    }

    public override void dispose() {
        var child = this.get_first_child();
        if (child != null) child.unparent();
    }
}
}
