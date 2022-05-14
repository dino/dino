using Gtk;

namespace Dino.Ui {
public class SizingBin : Widget {
    public int min_width { get; set; default = -1; }
    public int target_width { get; set; default = -1; }
    public int max_width { get; set; default = -1; }
    public int min_height { get; set; default = -1; }
    public int target_height { get; set; default = -1; }
    public int max_height { get; set; default = -1; }

    construct {
        layout_manager = new BinLayout();
    }

    public override void size_allocate(int width, int height, int baseline) {
        if (max_height != -1) height = int.min(height, max_height);
        if (max_width != -1) width = int.min(width, max_width);
        base.size_allocate(width, height, baseline);
    }

    public override void measure(Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        base.measure(orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
        if (orientation == Orientation.HORIZONTAL) {
            if (min_width != -1) minimum = int.max(minimum, min_width);
            if (max_width != -1) natural = int.min(natural, max_width);
            if (target_width != -1) natural = int.max(natural, target_width);
            natural = int.max(natural, minimum);
        } else {
            if (min_height != -1) minimum = int.max(minimum, min_height);
            if (max_height != -1) natural = int.min(natural, max_height);
            if (target_height != -1) natural = int.max(natural, target_height);
            natural = int.max(natural, minimum);
        }
    }

    public override void dispose() {
        var child = this.get_first_child();
        if (child != null) child.unparent();
    }
}
}
