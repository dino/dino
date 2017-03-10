using Cairo;
using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class AvatarGenerator {

    private const string COLOR_GREY = "E0E0E0";
    private const string GROUPCHAT_ICON = "system-users-symbolic";

    StreamInteractor? stream_interactor;
    bool greyscale = false;
    bool stateless = false;
    int width;
    int height;
    int scale_factor;

    public AvatarGenerator(int width, int height, int scale_factor = 1) {
        this.width = width;
        this.height = height;
        this.scale_factor = scale_factor;
    }

    public Pixbuf draw_jid(StreamInteractor stream_interactor, Jid jid, Account account) {
        this.stream_interactor = stream_interactor;
        return crop_corners(draw_tile(jid, account, width * scale_factor, height * scale_factor));
    }

    public Pixbuf draw_message(StreamInteractor stream_interactor, Message message) {
        Jid? real_jid = MucManager.get_instance(stream_interactor).get_message_real_jid(message);
        return draw_jid(stream_interactor, real_jid != null ? real_jid : message.from, message.account);
    }

    public Pixbuf draw_conversation(StreamInteractor stream_interactor, Conversation conversation) {
        return draw_jid(stream_interactor, conversation.counterpart, conversation.account);
    }

    public Pixbuf draw_account(StreamInteractor stream_interactor, Account account) {
        return draw_jid(stream_interactor, account.bare_jid, account);
    }

    public Pixbuf draw_text(string text) {
        string color = greyscale ? COLOR_GREY : Util.get_avatar_hex_color(text);
        Pixbuf pixbuf = draw_colored_rectangle_text(color, text, width, height);
        return crop_corners(pixbuf);
    }

    public AvatarGenerator set_greyscale(bool greyscale) {
        this.greyscale = greyscale;
        return this;
    }

    public AvatarGenerator set_stateless(bool stateless) {
        this.stateless = stateless;
        return this;
    }

    private int get_left_border() {
        return (int)Math.floor(scale_factor/2.0);
    }

    private int get_right_border() {
        return (int)Math.ceil(scale_factor/2.0);
    }

    private void add_tile_to_pixbuf(Pixbuf pixbuf, Jid jid, Account account, int width, int height, int x, int y) {
        Pixbuf tile = draw_chat_tile(jid, account, width, height);
        tile.copy_area(0, 0, width, height, pixbuf, x, y);
    }

    private Pixbuf draw_tile(Jid jid, Account account, int width, int height) {
        if (MucManager.get_instance(stream_interactor).is_groupchat(jid, account)) {
            return draw_groupchat_tile(jid, account, width, height);
        } else {
            return draw_chat_tile(jid, account, width, height);
        }
    }

    private Pixbuf draw_chat_tile(Jid jid, Account account, int width, int height) {
        if (MucManager.get_instance(stream_interactor).is_groupchat_occupant(jid, account)) {
            Jid? real_jid = MucManager.get_instance(stream_interactor).get_real_jid(jid, account);
            if (real_jid != null) {
                return draw_tile(real_jid, account, width, height);
            }
        }
        Pixbuf? avatar = AvatarManager.get_instance(stream_interactor).get_avatar(account, jid);
        if (avatar != null) {
            double desired_ratio = (double) width / height;
            double avatar_ratio = (double) avatar.width / avatar.height;
            if (avatar_ratio > desired_ratio) {
                int comp_width = width * avatar.height / height;
                avatar = new Pixbuf.subpixbuf(avatar, avatar.width / 2 - comp_width / 2, 0, comp_width, avatar.height);
            } else if (avatar_ratio < desired_ratio) {
                int comp_height = height * avatar.width / width;
                avatar = new Pixbuf.subpixbuf(avatar, 0, avatar.height / 2 - comp_height / 2, avatar.width, comp_height);
            }
            avatar = avatar.scale_simple(width, height, InterpType.BILINEAR);
            if (greyscale) avatar = convert_to_greyscale(avatar);
            return avatar;
        } else {
            string display_name = Util.get_display_name(stream_interactor, jid, account);
            string color = greyscale ? COLOR_GREY : Util.get_avatar_hex_color(display_name);
            return draw_colored_rectangle_text(color, display_name.get_char(0).toupper().to_string(), width, height);
        }
    }

    private Pixbuf draw_groupchat_tile(Jid jid, Account account, int width, int height) {
        ArrayList<Jid>? occupants = MucManager.get_instance(stream_interactor).get_other_occupants(jid, account);
        if (stateless || occupants == null || occupants.size == 0) {
            return draw_chat_tile(jid, account, width, height);
        }
        Pixbuf pixbuf = initialize_pixbuf(width, height);
        if (occupants.size == 1 || occupants.size == 2 || occupants.size == 3) {
            add_tile_to_pixbuf(pixbuf, occupants[0], account, width / 2 - get_right_border(), height, 0, 0);
            if (occupants.size == 1) {
                add_tile_to_pixbuf(pixbuf, account.bare_jid, account, width / 2 - get_left_border(), height, width / 2 + get_left_border(), 0);
            } else if (occupants.size == 2) {
                add_tile_to_pixbuf(pixbuf, occupants[1], account, width / 2 - get_left_border(), height, width / 2 + get_left_border(), 0);
            } else if (occupants.size == 3) {
                add_tile_to_pixbuf(pixbuf, occupants[1], account, width / 2 - get_left_border(), height / 2 - get_right_border(), width / 2 + get_left_border(), 0);
                add_tile_to_pixbuf(pixbuf, occupants[2], account, width / 2 - get_left_border(), height / 2 - get_left_border(), width / 2 + get_left_border(), height / 2 + get_left_border());
            }
        } else if (occupants.size >= 4) {
            add_tile_to_pixbuf(pixbuf, occupants[0], account, width / 2 - get_right_border(), height / 2 - get_right_border(), 0, 0);
            add_tile_to_pixbuf(pixbuf, occupants[1], account, width / 2 - get_left_border(), height / 2 - get_right_border(), width / 2 + get_left_border(), 0);
            add_tile_to_pixbuf(pixbuf, occupants[2], account, width / 2 - get_right_border(), height / 2 - get_left_border(), 0, height / 2 + get_left_border());
            if (occupants.size == 4) {
                add_tile_to_pixbuf(pixbuf, occupants[3], account, width / 2 - get_left_border(), height / 2 - get_left_border(), width / 2 + get_left_border(), height / 2 + get_left_border());
            } else if (occupants.size > 4) {
                Pixbuf plus_pixbuf = draw_colored_rectangle_text("555753", "+", width / 2 - get_left_border(), height / 2 - get_left_border());
                if (greyscale) plus_pixbuf = convert_to_greyscale(plus_pixbuf);
                plus_pixbuf.copy_area(0, 0, width / 2 - get_left_border(), height / 2 - get_left_border(), pixbuf, width / 2 + get_left_border(), height / 2 + get_left_border());
            }
        }
        return pixbuf;
    }

    public Pixbuf draw_colored_icon(string hex_color, string icon, int width, int height) {
        int ICON_SIZE = width > 20 * scale_factor ? 17 * scale_factor : 14 * scale_factor;

        Context rectancle_context = new Context(new ImageSurface(Format.ARGB32, width, height));
        draw_colored_rectangle(rectancle_context, hex_color, width, height);

        Pixbuf icon_pixbuf = IconTheme.get_default().load_icon(icon, ICON_SIZE, IconLookupFlags.FORCE_SIZE);
        Surface icon_surface = cairo_surface_create_from_pixbuf(icon_pixbuf, 1, null);
        Context context = new Context(icon_surface);
        context.set_operator(Operator.IN);
        context.set_source_rgba(1, 1, 1, 1);
        context.rectangle(0, 0, width, height);
        context.fill();

        rectancle_context.set_source_surface(icon_surface, width / 2 - ICON_SIZE / 2, height / 2 - ICON_SIZE / 2);
        rectancle_context.paint();

        return pixbuf_get_from_surface(rectancle_context.get_target(), 0, 0, width, height);
    }

    public Pixbuf draw_colored_rectangle_text(string hex_color, string text, int width, int height) {
        Context ctx = new Context(new ImageSurface(Format.ARGB32, width, height));
        draw_colored_rectangle(ctx, hex_color, width, height);
        draw_center_text(ctx, text, width < 40 * scale_factor ? 17 * scale_factor : 25 * scale_factor, width, height);
        return pixbuf_get_from_surface(ctx.get_target(), 0, 0, width, height);
    }

    private static void draw_center_text(Context ctx, string text, int fontsize, int width, int height) {
        ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        ctx.set_font_size(fontsize);
        Cairo.TextExtents extents;
        ctx.text_extents(text, out extents);
        double x_pos = width/2 - (extents.width/2 + extents.x_bearing);
        double y_pos = height/2 - (extents.height/2 + extents.y_bearing);
        ctx.move_to(x_pos, y_pos);
        ctx.set_source_rgba(1, 1, 1, 1);
        ctx.show_text(text);
    }

    private static void draw_colored_rectangle(Context ctx, string hex_color, int width, int height) {
        set_source_hex_color(ctx, hex_color);
        ctx.rectangle(0, 0, width, height);
        ctx.fill();
    }

    private static Pixbuf convert_to_greyscale(Pixbuf pixbuf) {
        Surface surface = cairo_surface_create_from_pixbuf(pixbuf, 1, null);
        Context context = new Context(surface);
        // convert to greyscale
        context.set_operator(Operator.HSL_COLOR);
        context.set_source_rgb(1, 1, 1);
        context.rectangle(0, 0, pixbuf.width, pixbuf.height);
        context.fill();
        // make the visible part more light
        context.set_operator(Operator.ATOP);
        context.set_source_rgba(1, 1, 1, 0.7);
        context.rectangle(0, 0, pixbuf.width, pixbuf.height);
        context.fill();
        return pixbuf_get_from_surface(context.get_target(), 0, 0, pixbuf.width, pixbuf.height);
    }

    private Pixbuf crop_corners(Pixbuf pixbuf, double radius = 3) {
        radius *= scale_factor;
        Context ctx = new Context(new ImageSurface(Format.ARGB32, pixbuf.width, pixbuf.height));
        cairo_set_source_pixbuf(ctx, pixbuf, 0, 0);
        double degrees = Math.PI / 180.0;
        ctx.new_sub_path();
        ctx.arc(pixbuf.width - radius, radius, radius, -90 * degrees, 0 * degrees);
        ctx.arc(pixbuf.width - radius, pixbuf.height - radius, radius, 0 * degrees, 90 * degrees);
        ctx.arc(radius, pixbuf.height - radius, radius, 90 * degrees, 180 * degrees);
        ctx.arc(radius, radius, radius, 180 * degrees, 270 * degrees);
        ctx.close_path();
        ctx.clip();
        ctx.paint();
        return pixbuf_get_from_surface(ctx.get_target(), 0, 0, pixbuf.width, pixbuf.height);
    }

    private static Pixbuf initialize_pixbuf(int width, int height) {
        Context ctx = new Context(new ImageSurface(Format.ARGB32, width, height));
        ctx.set_source_rgba(1, 1, 1, 0);
        ctx.rectangle(0, 0, width, height);
        ctx.fill();
        return pixbuf_get_from_surface(ctx.get_target(), 0, 0, width, height);
    }

    private static void set_source_hex_color(Context ctx, string hex_color) {
        ctx.set_source_rgba((double) hex_color.substring(0, 2).to_long(null, 16) / 255,
                            (double) hex_color.substring(2, 2).to_long(null, 16) / 255,
                            (double) hex_color.substring(4, 2).to_long(null, 16) / 255,
                            hex_color.length > 6 ? (double) hex_color.substring(6, 2).to_long(null, 16) / 255 : 1);
    }
}

}
