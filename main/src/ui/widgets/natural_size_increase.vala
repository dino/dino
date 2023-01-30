using Gtk;

public class Dino.Ui.NaturalSizeIncrease : Gtk.Widget {
    public int min_natural_height { get; set; default = -1; }
    public int min_natural_width { get; set; default = -1; }

    construct {
        this.notify.connect(queue_resize);
    }

    public override void measure(Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        minimum = 0;
        if (orientation == Orientation.HORIZONTAL) {
            natural = min_natural_width;
        } else {
            natural = min_natural_height;
        }
        natural = int.max(0, natural);
        minimum_baseline = -1;
        natural_baseline = -1;
        Widget child = get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                int child_min = 0;
                int child_nat = 0;
                int child_min_baseline = -1;
                int child_nat_baseline = -1;
                child.measure(orientation, -1, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
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
    }

    public override void size_allocate(int width, int height, int baseline) {
        Widget child = get_first_child();
        while (child != null) {
            if (child.should_layout()) {
                child.allocate(width, height, baseline, null);
            }
            child = child.get_next_sibling();
        }
    }

    public override SizeRequestMode get_request_mode() {
        Widget child = get_first_child();
        if (child != null) {
            return child.get_request_mode();
        }
        return SizeRequestMode.CONSTANT_SIZE;
    }
}