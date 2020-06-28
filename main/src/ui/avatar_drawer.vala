using Cairo;
using Gee;
using Gdk;
using Gtk;
using Xmpp.Util;

namespace Dino.Ui {

public class AvatarDrawer {
    public const string GRAY = "555753";

    private Gee.List<AvatarTile> tiles = new ArrayList<AvatarTile>();
    private int height = 35;
    private int width = 35;
    private bool gray;
    private int base_factor = 1;
    private string font_family = "Sans";

    public AvatarDrawer size(int height, int width = height) {
        this.height = height;
        this.width = width;
        return this;
    }

    public AvatarDrawer grayscale() {
        this.gray = true;
        return this;
    }

    public AvatarDrawer tile(Pixbuf? image, string? name, string? hex_color) {
        tiles.add(new AvatarTile(image, name, hex_color));
        return this;
    }

    public AvatarDrawer plus() {
        tiles.add(new AvatarTile(null, "…", GRAY));
        return this;
    }

    public AvatarDrawer scale(int base_factor) {
        this.base_factor = base_factor;
        return this;
    }

    public AvatarDrawer font(string font_family) {
        this.font_family = font_family;
        return this;
    }

    public ImageSurface draw_image_surface() {
        ImageSurface surface = new ImageSurface(Format.ARGB32, width, height);
        draw_on_context(new Context(surface));
        return surface;
    }

    public void draw_on_context(Cairo.Context ctx) {
        double radius = 3 * base_factor;
        double degrees = Math.PI / 180.0;
        ctx.new_sub_path();
        ctx.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees);
        ctx.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees);
        ctx.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees);
        ctx.arc(radius, radius, radius, 180 * degrees, 270 * degrees);
        ctx.close_path();
        ctx.clip();

        if (this.tiles.size == 4) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width - 1, height - 1, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width - 1, height - 1, 2 * base_factor), width + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 2, width - 1, height - 1, 2 * base_factor), 0, height + 1);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 3, width - 1, height - 1, 2 * base_factor), width + 1, height + 1);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.tiles.size == 3) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width - 1, height - 1, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width - 1, height * 2, 2 * base_factor), width + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 2, width - 1, height - 1, 2 * base_factor), 0, height + 1);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.tiles.size == 2) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width - 1, height * 2, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width - 1, height * 2, 2 * base_factor), width + 1, 0);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.tiles.size == 1) {
            ctx.set_source_surface(sub_surface_idx(ctx, 0, width, height, base_factor), 0, 0);
            ctx.paint();
        } else if (this.tiles.size == 0) {
            ctx.set_source_surface(sub_surface_idx(ctx, -1, width, height, base_factor), 0, 0);
            ctx.paint();
        }

        if (gray) {
            // convert to greyscale
            ctx.set_operator(Cairo.Operator.HSL_COLOR);
            ctx.set_source_rgb(1, 1, 1);
            ctx.rectangle(0, 0, width, height);
            ctx.fill();
            // make the visible part more light
            ctx.set_operator(Cairo.Operator.ATOP);
            ctx.set_source_rgba(1, 1, 1, 0.7);
            ctx.rectangle(0, 0, width, height);
            ctx.fill();
        }
        ctx.set_source_rgb(0, 0, 0);
    }

    private Cairo.Surface sub_surface_idx(Cairo.Context ctx, int idx, int width, int height, int font_factor = 1) {
        Gdk.Pixbuf? avatar = idx >= 0 ? tiles[idx].image : null;
        string? name = idx >= 0 ? tiles[idx].name : "";
        string hex_color = !gray && idx >= 0 ? tiles[idx].hex_color : GRAY;
        return sub_surface(ctx, font_family, avatar, name, hex_color, width, height, font_factor);
    }

    private static Cairo.Surface sub_surface(Cairo.Context ctx, string font_family, Gdk.Pixbuf? avatar, string? name, string? hex_color, int width, int height, int font_factor = 1) {
        Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
        Cairo.Context bufctx = new Cairo.Context(buffer);
        if (avatar == null) {
            set_source_hex_color(bufctx, hex_color ?? GRAY);
            bufctx.rectangle(0, 0, width, height);
            bufctx.fill();

            string text = name == null ? "…" : name.get_char(0).toupper().to_string();
            bufctx.select_font_face(font_family, Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            bufctx.set_font_size(width / font_factor < 40 ? font_factor * 17 : font_factor * 25);
            Cairo.TextExtents extents;
            bufctx.text_extents(text, out extents);
            double x_pos = width/2 - (extents.width/2 + extents.x_bearing);
            double y_pos = height/2 - (extents.height/2 + extents.y_bearing);
            bufctx.move_to(x_pos, y_pos);
            bufctx.set_source_rgba(1, 1, 1, 1);
            bufctx.show_text(text);
        } else {
            double w_scale = (double) width / avatar.width;
            double h_scale = (double) height / avatar.height;
            double scale = double.max(w_scale, h_scale);
            bufctx.scale(scale, scale);

            double x_off = 0, y_off = 0;
            if (scale == h_scale) {
                x_off = (width / scale - avatar.width) / 2.0;
            } else {
                y_off = (height / scale - avatar.height) / 2.0;
            }
            Gdk.cairo_set_source_pixbuf(bufctx, avatar, x_off, y_off);
            bufctx.get_source().set_filter(Cairo.Filter.BEST);
            bufctx.paint();
        }
        return buffer;
    }

    private static void set_source_hex_color(Cairo.Context ctx, string hex_color) {
        ctx.set_source_rgba((double) from_hex(hex_color.substring(0, 2)) / 255,
                    (double) from_hex(hex_color.substring(2, 2)) / 255,
                    (double) from_hex(hex_color.substring(4, 2)) / 255,
                    hex_color.length > 6 ? (double) from_hex(hex_color.substring(6, 2)) / 255 : 1);
    }
}

private class AvatarTile {
    public Pixbuf? image { get; private set; }
    public string? name { get; private set; }
    public string? hex_color { get; private set; }

    public AvatarTile(Pixbuf? image, string? name, string? hex_color) {
        this.image = image;
        this.name = name;
        this.hex_color = hex_color;
    }
}

}