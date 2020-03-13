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

    public override void size_allocate(Allocation allocation) {
        if (max_width != -1) allocation.width = int.min(allocation.width, max_width);
        if (max_height != -1) allocation.height = int.min(allocation.height, max_height);
        allocation.height = int.min(allocation.height, (int)(allocation.width * image_ratio));
        allocation.width = int.min(allocation.width, (int)(allocation.height / image_ratio));
        base.size_allocate(allocation);
        if (last_allocation_height != allocation.height || last_allocation_width != allocation.width || last_scale_factor != scale_factor) {
            last_allocation_height = allocation.height;
            last_allocation_width = allocation.width;
            last_scale_factor = scale_factor;
            Pixbuf scaled = image.scale_simple(allocation.width * scale_factor, allocation.height * scale_factor, Gdk.InterpType.BILINEAR);
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
        natural_width = target_width != -1 ? target_width : (image_width / scale_factor);
        natural_width = int.min(natural_width, max_width);
        if (natural_width * image_ratio > max_height) {
            natural_width = (int) (max_height / image_ratio);
        }
    }

    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        minimum_height = int.max(0, min_height);
        natural_height = (int) (target_width != -1 ? target_width * image_ratio : image_width / scale_factor);
        natural_height = int.min(natural_height, max_height);
        if (natural_height / image_ratio > max_width) {
            natural_height = (int) (max_width * image_ratio);
        }
    }

    public override void get_preferred_height_for_width(int width, out int minimum_height, out int natural_height) {
        natural_height = (int) (width * image_ratio);
        minimum_height = min_height != -1 ? int.min(min_height, natural_height) : natural_height;
    }

    public override void get_preferred_width_for_height(int height, out int minimum_width, out int natural_width) {
        natural_width = (int) (height / image_ratio);
        minimum_width = min_width != -1 ? int.min(min_width, natural_width) : natural_width;
    }

    public override SizeRequestMode get_request_mode() {
        return SizeRequestMode.HEIGHT_FOR_WIDTH;
    }
}
}