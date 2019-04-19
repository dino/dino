using Gtk;
using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class AvatarImage : Misc {
    public int height { get; set; default = 32; }
    public int width { get; set; default = 32; }
    public bool allow_gray { get; set; default = true; }
    public Account account { get; private set; }
    public StreamInteractor stream_interactor { get; set; }
    public AvatarManager avatar_manager { owned get { return stream_interactor.get_module(AvatarManager.IDENTITY); } }
    public MucManager muc_manager { owned get { return stream_interactor.get_module(MucManager.IDENTITY); } }
    private Jid jid;
    private string? text_only;
    private bool with_plus;
    private bool gray;
    private Jid[] current_jids;
    private Gdk.Pixbuf[] current_avatars;
    private Cairo.ImageSurface? cached_surface;
    private static int8 use_image_surface = -1;

    public AvatarImage() {
        can_focus = false;
        get_style_context().add_class("avatar");
    }

    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        minimum_width = width;
        natural_width = width;
    }

    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        minimum_height = height;
        natural_height = height;
    }

    private Cairo.Surface sub_surface(Cairo.Context ctx, int idx, int width, int height, int font_factor = 1) {
        Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
        Cairo.Context bufctx = new Cairo.Context(buffer);
        if (idx == -1 || current_avatars[idx] == null) {
            set_source_hex_color(bufctx, gray || idx == -1 ? "555753" : Util.get_avatar_hex_color(stream_interactor, account, current_jids[idx]));
            bufctx.rectangle(0, 0, width, height);
            bufctx.fill();

            string text = text_only ?? (idx == -1 ? "…" : Util.get_display_name(stream_interactor, current_jids[idx], account).get_char(0).toupper().to_string());
            bufctx.select_font_face(get_pango_context().get_font_description().get_family(), Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            bufctx.set_font_size(width / font_factor < 40 ? font_factor * 17 : font_factor * 25);
            Cairo.TextExtents extents;
            bufctx.text_extents(text, out extents);
            double x_pos = width/2 - (extents.width/2 + extents.x_bearing);
            double y_pos = height/2 - (extents.height/2 + extents.y_bearing);
            bufctx.move_to(x_pos, y_pos);
            bufctx.set_source_rgba(1, 1, 1, 1);
            bufctx.show_text(text);
        } else {
            double w_scale = (double) width / current_avatars[idx].width;
            double h_scale = (double) height / current_avatars[idx].height;
            double scale = double.max(w_scale, h_scale);
            bufctx.scale(scale, scale);

            double x_off = 0, y_off = 0;
            if (scale == h_scale) {
                x_off = (width / scale - current_avatars[idx].width) / 2.0;
            } else {
                y_off = (height / scale - current_avatars[idx].height) / 2.0;
            }
            Gdk.cairo_set_source_pixbuf(bufctx, current_avatars[idx], x_off, y_off);
            bufctx.get_source().set_filter(Cairo.Filter.BEST);
            bufctx.paint();
        }
        return buffer;
    }

    private static void set_source_hex_color(Cairo.Context ctx, string hex_color) {
        ctx.set_source_rgba((double) hex_color.substring(0, 2).to_long(null, 16) / 255,
                            (double) hex_color.substring(2, 2).to_long(null, 16) / 255,
                            (double) hex_color.substring(4, 2).to_long(null, 16) / 255,
                            hex_color.length > 6 ? (double) hex_color.substring(6, 2).to_long(null, 16) / 255 : 1);
    }

    public override bool draw(Cairo.Context ctx_in) {
        if (text_only == null && (current_jids == null || current_avatars == null || current_jids.length == 0)) return false;

        Cairo.Context ctx = ctx_in;
        int width = this.width, height = this.height, base_factor = 1;
        if (use_image_surface == -1) {
            // TODO: detect if we have to buffer in image surface
            use_image_surface = 1;
        }
        if (use_image_surface == 1) {
            ctx_in.scale(1f/scale_factor, 1f/scale_factor);
            if (cached_surface != null) {
                ctx_in.set_source_surface(cached_surface, 0, 0);
                ctx_in.paint();
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

        if (text_only != null) {
            ctx.set_source_surface(sub_surface(ctx, -1, width, height, base_factor), 0, 0);
            ctx.paint();
        } else if (current_jids.length == 4 || with_plus) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface(ctx, 0, width - 1, height - 1, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface(ctx, 1, width - 1, height - 1, 2 * base_factor), width + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface(ctx, 2, width - 1, height - 1, 2 * base_factor), 0, height + 1);
            bufctx.paint();
            if (with_plus) {
                bufctx.set_source_surface(sub_surface(ctx, -1, width - 1, height - 1, 2 * base_factor), width + 1, height + 1);
                bufctx.paint();
            } else {
                bufctx.set_source_surface(sub_surface(ctx, 3, width - 1, height - 1, 2 * base_factor), width + 1, height + 1);
                bufctx.paint();
            }

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (current_jids.length == 3) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface(ctx, 0, width - 1, height - 1, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface(ctx, 1, width - 1, height * 2, 2 * base_factor), width + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface(ctx, 2, width - 1 , height - 1, 2 * base_factor), 0, height + 1);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (current_jids.length == 2) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface(ctx, 0, width - 1, height * 2, 2 * base_factor), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface(ctx, 1, width - 1, height * 2, 2 * base_factor), width + 1, 0);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (current_jids.length == 1) {
            ctx.set_source_surface(sub_surface(ctx, 0, width, height, base_factor), 0, 0);
            ctx.paint();
        } else {
            assert_not_reached();
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

        if (use_image_surface == 1) {
            ctx_in.set_source_surface(ctx.get_target(), 0, 0);
            ctx_in.paint();
        }

        return true;
    }

    public override void destroy() {
        if (stream_interactor != null) {
            stream_interactor.get_module(PresenceManager.IDENTITY).show_received.disconnect(on_show_received);
            stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.disconnect(on_received_avatar);
            stream_interactor.connection_manager.connection_state_changed.disconnect(on_connection_changed);
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.disconnect(on_roster_updated);
            stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.disconnect(on_occupant_updated);
        }
    }

    public void set_jid(StreamInteractor stream_interactor, Jid jid_, Account account, bool force_update = false) {
        this.account = account;
        if (this.stream_interactor == null) {
            this.stream_interactor = stream_interactor;
            stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect(on_show_received);
            stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect(on_received_avatar);
            stream_interactor.connection_manager.connection_state_changed.connect(on_connection_changed);
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect(on_roster_updated);
            stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect(on_occupant_updated);
        }
        if (muc_manager.is_groupchat(jid_, account) && !avatar_manager.has_avatar(account, jid_)) {
            // Groupchat without avatar
            Gee.List<Jid>? occupants;
            if (muc_manager.is_private_room(account, jid_)) {
                occupants = muc_manager.get_other_offline_members(jid_, account);
            } else {
                occupants = muc_manager.get_other_occupants(jid_, account);
            }
            jid = jid_;
            if (occupants == null || occupants.size == 0) {
                if (force_update || current_jids.length != 1 || !current_jids[0].equals(jid_) || gray != (allow_gray && (occupants == null || !is_self_online()))) {
                    set_jids_(new Jid[] {jid_}, false, occupants == null || !is_self_online());
                }
            } else if (occupants.size > 4) {
                bool requires_update = force_update;
                if (!with_plus) requires_update = true;
                foreach (Jid jid in current_jids) {
                    if (!occupants.contains(jid)) {
                        requires_update = true;
                    }
                }
                if (requires_update) {
                    set_jids_(occupants.slice(0, 3).to_array(), true);
                }
            } else { // 1 <= occupants.size <= 4
                bool requires_update = force_update;
                if (with_plus) requires_update = true;
                if (current_jids.length != occupants.size) requires_update = true;
                foreach (Jid jid in current_jids) {
                    if (!occupants.contains(jid)) {
                        requires_update = true;
                    }
                }
                if (requires_update) {
                    set_jids_(occupants.to_array(), false);
                }
            }
        } else {
            // Single user or MUC with vcard avatar
            this.jid = jid_;
            if (force_update || current_jids.length != 1 || !current_jids[0].equals(jid) || gray != (allow_gray && (!is_counterpart_online(jid) || !is_self_online()))) {
                set_jids_(new Jid[] { jid }, false, !is_counterpart_online(jid) || !is_self_online());
            }
        }
    }

    public void set_jids(StreamInteractor stream_interactor, Jid[] jids, Account account, bool gray = false) {
        this.stream_interactor = stream_interactor;
        this.account = account;
        set_jids_(jids.length > 3 ? jids[0:3] : jids, jids.length > 3, gray);
    }

    private void on_show_received(Show show, Jid jid, Account account) {
        if (!account.equals(this.account)) return;
        if (jid.equals_bare(this.jid)) {
            set_jid(stream_interactor, this.jid, account, true);
            return;
        }
        foreach (Jid jid_ in current_jids) {
            if (jid.equals_bare(jid_)) {
                set_jid(stream_interactor, this.jid, account, true);
                return;
            }
        }
    }

    private void on_received_avatar(Gdk.Pixbuf avatar, Jid jid, Account account) {
        if (!account.equals(this.account)) return;
        if (jid.equals_bare(this.jid)) {
            set_jid(stream_interactor, this.jid, account, true);
            return;
        }
        foreach (Jid jid_ in current_jids) {
            if (jid.equals_bare(jid_)) {
                set_jid(stream_interactor, this.jid, account, true);
                return;
            }
        }
    }

    private void on_connection_changed(Account account, ConnectionManager.ConnectionState state) {
        if (!account.equals(this.account)) return;
        set_jid(stream_interactor, this.jid, account, true);
    }

    private void on_roster_updated(Account account, Jid jid, Roster.Item roster_item) {
        if (!account.equals(this.account)) return;
        if (!jid.equals_bare(this.jid)) return;
        set_jid(stream_interactor, this.jid, account, true);
    }

    private void on_occupant_updated(Account account, Jid room, Jid occupant) {
        if (!account.equals(this.account)) return;
        if (!room.equals_bare(this.jid)) return;
        set_jid(stream_interactor, this.jid, account, true);
    }

    private bool is_self_online() {
        return stream_interactor.connection_manager.get_state(account) == ConnectionManager.ConnectionState.CONNECTED;
    }

    private bool is_counterpart_online(Jid counterpart) {
        return stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(counterpart, account) != null;
    }

    public void set_jids_(Jid[] jids, bool with_plus = false, bool gray = false) {
        assert(jids.length > 0);
        assert(jids.length < 5);
        assert(!with_plus || jids.length == 3);
        this.cached_surface = null;
        this.text_only = null;
        this.gray = gray && allow_gray;
        this.with_plus = with_plus;

        set_jids_async.begin(jids);
    }

    public async void set_jids_async(Jid[] jids) {
        Jid[] jids_ = jids;
        Gdk.Pixbuf[] avatars = new Gdk.Pixbuf[jids.length];
        for (int i = 0; i < jids_.length; ++i) {
            Jid? real_jid = muc_manager.get_real_jid(jids_[i], account);
            if (real_jid != null) {
                avatars[i] = yield avatar_manager.get_avatar(account, real_jid);
                if (avatars[i] != null) {
                    jids_[i] = real_jid;
                    continue;
                }
            }
            avatars[i] = yield avatar_manager.get_avatar(account, jids_[i]);
        }
        this.current_avatars = avatars;
        this.current_jids = jids_;

        queue_draw();
    }

    public void set_text(string text, bool gray = true) {
        this.text_only = text;
        this.gray = gray;
        this.with_plus = false;
        this.current_jids = null;
        this.current_avatars = null;
        queue_draw();
    }
}

}
