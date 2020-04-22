using Gtk;

namespace Dino.Ui {
public class SizingBin : Bin {
    public int min_width { get; set; default = -1; }
    public int target_width { get; set; default = -1; }
    public int max_width { get; set; default = -1; }
    public int min_height { get; set; default = -1; }
    public int target_height { get; set; default = -1; }
    public int max_height { get; set; default = -1; }

    public override void size_allocate(Allocation allocation) {
        if (max_height != -1) allocation.height = int.min(allocation.height, max_height);
        if (max_width != -1) allocation.width = int.min(allocation.width, max_width);
        base.size_allocate(allocation);
    }

    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        base.get_preferred_width(out minimum_width, out natural_width);
        if (min_width != -1) minimum_width = int.max(minimum_width, min_width);
        if (max_width != -1) natural_width = int.min(natural_width, max_width);
        if (target_width != -1) natural_width = int.max(natural_width, target_width);
        natural_width = int.max(natural_width, minimum_width);
    }

    public override void get_preferred_height_for_width(int width, out int minimum_height, out int natural_height) {
        base.get_preferred_height_for_width(width, out minimum_height, out natural_height);
        if (min_height != -1) minimum_height = int.max(minimum_height, min_height);
        if (max_height != -1) natural_height = int.min(natural_height, max_height);
        if (target_height != -1) natural_height = int.max(natural_height, target_height);
        natural_height = int.max(natural_height, minimum_height);
    }

}
}
