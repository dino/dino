using Gdk;
using Gtk;

namespace Dino.Ui {
class ScalingImage : Misc {
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
    private Cairo.ImageSurface? cached_surface;
    private static int8 use_image_surface = -1;

    public void load(Pixbuf image) {
        this.image = image;
        this.image_ratio = ((double)image.height) / ((double)image.width);
        this.image_height = image.height;
        this.image_width = image.width;
        queue_resize();
    }

    public override void dispose() {
        base.dispose();
        image = null;
        cached_surface = null;
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
            cached_surface = null;
        }
    }

    public override bool draw(Cairo.Context ctx_in) {
        if (image == null) return false;
        Cairo.Context ctx = ctx_in;
        int width = this.get_allocated_width(), height = this.get_allocated_height(), base_factor = 1;
        if (use_image_surface == -1) {
            // TODO: detect if we have to buffer in image surface
            use_image_surface = 1;
        }
        if (use_image_surface == 1) {
            ctx_in.scale(1f / scale_factor, 1f / scale_factor);
            if (cached_surface != null) {
                ctx_in.set_source_surface(cached_surface, 0, 0);
                ctx_in.paint();
                ctx_in.set_source_rgb(0, 0, 0);
                return true;
            }
            width *= scale_factor;
            height *= scale_factor;
            base_factor *= scale_factor;
            cached_surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
            ctx = new Cairo.Context(cached_surface);
        }

        double radius = 3 * base_factor;
        double degrees = Math.PI / 180.0;
        ctx.new_sub_path();
        ctx.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees);
        ctx.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees);
        ctx.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees);
        ctx.arc(radius, radius, radius, 180 * degrees, 270 * degrees);
        ctx.close_path();
        ctx.clip();

        Cairo.Surface buffer = sub_surface(ctx, width, height);
        ctx.set_source_surface(buffer, 0, 0);
        ctx.paint();

        if (use_image_surface == 1) {
            ctx_in.set_source_surface(ctx.get_target(), 0, 0);
            ctx_in.paint();
            ctx_in.set_source_rgb(0, 0, 0);
        }

        return true;
    }

    private Cairo.Surface sub_surface(Cairo.Context ctx, int width, int height) {
        Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
        Cairo.Context bufctx = new Cairo.Context(buffer);
        double w_scale = (double) width / image_width;
        double h_scale = (double) height / image_height;
        double scale = double.max(w_scale, h_scale);
        bufctx.scale(scale, scale);

        double x_off = 0, y_off = 0;
        if (scale == h_scale) {
            x_off = (width / scale - image_width) / 2.0;
        } else {
            y_off = (height / scale - image_height) / 2.0;
        }
        Gdk.cairo_set_source_pixbuf(bufctx, image, 0, 0);
        bufctx.get_source().set_filter(Cairo.Filter.BILINEAR);
        bufctx.paint();
        bufctx.set_source_rgb(0, 0, 0);
        return buffer;
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
