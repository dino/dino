using Gdk;
using Gtk;

namespace Dino.Ui {
class ScalingImage : Image {
    public int min_width { get; set; default = -1; }
    public int target_width { get; set; default = -1; }
    public int max_width { get; set; default = -1; }
    public int min_height { get; set; default = -1; }
    public int max_height { get; set; default = -1; }

    private Pixbuf image;
    private double image_ratio;
    private int image_height = 0;
    private int image_width = 0;
    private int last_allocation_height = -1;
    private int last_allocation_width = -1;
    private int last_scale_factor = -1;

    public void load(Pixbuf image) {
        this.image = image;
        this.image_ratio = ((double)image.height) / ((double)image.width);
        this.image_height = image.height;
        this.image_width = image.width;
        queue_resize();
    }

    private void calculate_size(ref double exact_width, ref double exact_height) {
        if (exact_width == -1 && exact_height == -1) {
            if (target_width == -1) {
                exact_width = ((double)image_width) / ((double)scale_factor);
                exact_height = ((double)image_height) / ((double)scale_factor);
            } else {
                exact_width = target_width;
                exact_height = exact_width * image_ratio;
            }
        } else if (exact_width != -1) {
            exact_height = exact_width * image_ratio;
        } else if (exact_height != -1) {
            exact_width = exact_height / image_ratio;
        } else {
            if (exact_width * image_ratio > exact_height + scale_factor) {
                exact_width = exact_height / image_ratio;
            } else if (exact_height / image_ratio > exact_width + scale_factor) {
                exact_height = exact_width * image_ratio;
            }
        }
        if (max_width != -1 && exact_width > max_width) {
            exact_width = max_width;
            exact_height = exact_width * image_ratio;
        }
        if (max_height != -1 && exact_height > max_height) {
            exact_height = max_height;
            exact_width = exact_height / image_ratio;
        }
        if (exact_width < min_width) exact_width = min_width;
        if (exact_height < min_height) exact_height = min_height;
    }

    public override void size_allocate(Allocation allocation) {
        if (max_width != -1) allocation.width = int.min(allocation.width, max_width);
        if (max_height != -1) allocation.height = int.min(allocation.height, max_height);
        allocation.height = int.max(allocation.height, min_height);
        allocation.width = int.max(allocation.width, min_width);
        double exact_width = allocation.width, exact_height = allocation.height;
        calculate_size(ref exact_width, ref exact_height);
        base.size_allocate(allocation);
        if (last_allocation_height != allocation.height || last_allocation_width != allocation.width || last_scale_factor != scale_factor) {
            last_allocation_height = allocation.height;
            last_allocation_width = allocation.width;
            last_scale_factor = scale_factor;
            Pixbuf scaled = image.scale_simple((int) Math.floor(exact_width * scale_factor), (int) Math.floor(exact_height * scale_factor), Gdk.InterpType.BILINEAR);
            scaled = crop_corners(scaled, 3 * scale_factor);
            Util.image_set_from_scaled_pixbuf(this, scaled);
        }
    }

    private static Gdk.Pixbuf crop_corners(Gdk.Pixbuf pixbuf, double radius = 3) {
        Cairo.Context ctx = new Cairo.Context(new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.width, pixbuf.height));
        Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 0, 0);
        double degrees = Math.PI / 180.0;
        ctx.new_sub_path();
        ctx.arc(pixbuf.width - radius, radius, radius, -90 * degrees, 0 * degrees);
        ctx.arc(pixbuf.width - radius, pixbuf.height - radius, radius, 0 * degrees, 90 * degrees);
        ctx.arc(radius, pixbuf.height - radius, radius, 90 * degrees, 180 * degrees);
        ctx.arc(radius, radius, radius, 180 * degrees, 270 * degrees);
        ctx.close_path();
        ctx.clip();
        ctx.paint();
        return Gdk.pixbuf_get_from_surface(ctx.get_target(), 0, 0, pixbuf.width, pixbuf.height);
    }

    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        minimum_width = int.max(0, min_width);
        double exact_width = -1, exact_height = -1;
        calculate_size(ref exact_width, ref exact_height);
        natural_width = (int) Math.ceil(exact_width);
    }

    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        minimum_height = int.max(0, min_height);
        double exact_width = -1, exact_height = -1;
        calculate_size(ref exact_width, ref exact_height);
        natural_height = (int) Math.ceil(exact_height);
    }

    public override void get_preferred_height_for_width(int width, out int minimum_height, out int natural_height) {
        double exact_width = width, exact_height = -1;
        calculate_size(ref exact_width, ref exact_height);
        natural_height = (int) Math.ceil(exact_height);
        minimum_height = natural_height;
    }

    public override void get_preferred_width_for_height(int height, out int minimum_width, out int natural_width) {
        double exact_width = -1, exact_height = height;
        calculate_size(ref exact_width, ref exact_height);
        natural_width = (int) Math.ceil(exact_width);
        minimum_width = natural_width;
    }

    public override SizeRequestMode get_request_mode() {
        return SizeRequestMode.HEIGHT_FOR_WIDTH;
    }
}
}
