using Dino.Entities;
using Gtk;
using Xmpp;

public class Dino.Ui.ViewModel.AvatarPictureTileModel : Object {
    public string display_text { get; set; }
    public Gdk.RGBA background_color { get; set; }
    public File? image_file { get; set; }
}

public class Dino.Ui.ViewModel.AvatarPictureModel : Object {
    public ListModel tiles { get; set; }
}


public class Dino.Ui.ViewModel.ConversationParticipantAvatarPictureTileModel : AvatarPictureTileModel {
    private StreamInteractor stream_interactor;
    private AvatarManager? avatar_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(AvatarManager.IDENTITY); } }
    private MucManager? muc_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(MucManager.IDENTITY); } }
    private Conversation? conversation;
    private Jid? primary_avatar_jid;
    private Jid? secondary_avatar_jid;
    private Jid? display_name_jid;
    
    private void get_participant_default_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.primary_avatar_jid = jid;
        this.display_name_jid = jid;
    
        string color_id = jid.to_string();
        if (conversation.type_ != Conversation.Type.CHAT && primary_avatar_jid.equals_bare(conversation.counterpart)) {
            Jid? real_jid = muc_manager.get_real_jid(primary_avatar_jid, conversation.account);
            if (real_jid != null && muc_manager.is_private_room(conversation.account, conversation.counterpart.bare_jid)) {
                secondary_avatar_jid = primary_avatar_jid;
                primary_avatar_jid = real_jid.bare_jid;
                color_id = primary_avatar_jid.to_string();
            } else {
                color_id = jid.resourcepart.to_string();
            }
        } else if (conversation.type_ == Conversation.Type.CHAT) {
            primary_avatar_jid = jid.bare_jid;
            color_id = primary_avatar_jid.to_string();
        }
        string display = Util.get_participant_display_name(stream_interactor, conversation, display_name_jid);
        display_text = display.get_char(0).toupper().to_string();
        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect(on_roster_updated);
    
        float[] rgbf = color_id != null ? Xep.ConsistentColor.string_to_rgbf(color_id) : new float[] {0.5f, 0.5f, 0.5f};
        background_color = Gdk.RGBA() { red = rgbf[0], green = rgbf[1], blue = rgbf[2], alpha = 1.0f};
    }
    
    public ConversationParticipantAvatarPictureTileModel(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        get_participant_default_display_name(stream_interactor, conversation, jid);

        update_image_file();
        avatar_manager.received_avatar.connect(on_received_avatar);
        avatar_manager.fetched_avatar.connect(on_received_avatar);
    }
    
    public ConversationParticipantAvatarPictureTileModel.remove_avatar_picture(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        get_participant_default_display_name(stream_interactor, conversation, jid);
        avatar_manager.remove_avatar_manager(conversation.account, primary_avatar_jid);
        this.image_file = null;

        update_image_file();
    }
    
    private void update_image_file() {
        File image_file = avatar_manager.get_avatar_file(conversation.account, primary_avatar_jid);
        if (image_file == null && secondary_avatar_jid != null) {
            image_file = avatar_manager.get_avatar_file(conversation.account, secondary_avatar_jid);
        }
        this.image_file = image_file;
    }

    private void on_received_avatar(Jid jid, Account account) {
        if (account.equals(conversation.account) && (jid.equals(primary_avatar_jid) || jid.equals(secondary_avatar_jid))) {
            update_image_file();
        }
    }

    private void on_roster_updated(Account account, Jid jid) {
        if (account.equals(conversation.account) && jid.equals(display_name_jid)) {
            string display = Util.get_participant_display_name(stream_interactor, conversation, display_name_jid);
            display_text = display.get_char(0).toupper().to_string();
        }
    }
}

public class Dino.Ui.ViewModel.CompatAvatarPictureModel : AvatarPictureModel {
    private StreamInteractor stream_interactor;
    private AvatarManager? avatar_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(AvatarManager.IDENTITY); } }
    private MucManager? muc_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(MucManager.IDENTITY); } }
    private PresenceManager? presence_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(PresenceManager.IDENTITY); } }
    private ConnectionManager? connection_manager { owned get { return stream_interactor == null ? null : stream_interactor.connection_manager; } }
    private Conversation? conversation;

    construct {
        tiles = new GLib.ListStore(typeof(ViewModel.AvatarPictureTileModel));
    }

    public CompatAvatarPictureModel(StreamInteractor? stream_interactor) {
        this.stream_interactor = stream_interactor;
        if (stream_interactor != null) {
            connect_signals_weak(this);
        }
    }

    private static void connect_signals_weak(CompatAvatarPictureModel model_) {
        WeakRef model_weak = WeakRef(model_);
        ulong muc_manager_private_room_occupant_updated_handler_id = 0;
        ulong muc_manager_proom_info_updated_handler_id = 0;
        ulong avatar_manager_received_avatar_handler_id = 0;
        ulong avatar_manager_fetched_avatar_handler_id = 0;
        muc_manager_private_room_occupant_updated_handler_id = model_.muc_manager.private_room_occupant_updated.connect((muc_manager, account, room, jid) => {
            CompatAvatarPictureModel? model = (CompatAvatarPictureModel) model_weak.get();
            if (model != null) {
                model.on_room_updated(account, room);
            } else if (muc_manager_private_room_occupant_updated_handler_id != 0) {
                muc_manager.disconnect(muc_manager_private_room_occupant_updated_handler_id);
                muc_manager_private_room_occupant_updated_handler_id = 0;
            }
        });
        muc_manager_proom_info_updated_handler_id = model_.muc_manager.room_info_updated.connect((muc_manager, account, room) => {
            CompatAvatarPictureModel? model = (CompatAvatarPictureModel) model_weak.get();
            if (model != null) {
                model.on_room_updated(account, room);
            } else if (muc_manager_proom_info_updated_handler_id != 0) {
                muc_manager.disconnect(muc_manager_proom_info_updated_handler_id);
                muc_manager_proom_info_updated_handler_id = 0;
            }
        });
        avatar_manager_received_avatar_handler_id = model_.avatar_manager.received_avatar.connect((avatar_manager, jid, account) => {
            CompatAvatarPictureModel? model = (CompatAvatarPictureModel) model_weak.get();
            if (model != null) {
                model.on_received_avatar(jid, account);
            } else if (avatar_manager_received_avatar_handler_id != 0) {
                avatar_manager.disconnect(avatar_manager_received_avatar_handler_id);
                avatar_manager_received_avatar_handler_id = 0;
            }
        });
        avatar_manager_fetched_avatar_handler_id = model_.avatar_manager.fetched_avatar.connect((avatar_manager, jid, account) => {
            CompatAvatarPictureModel? model = (CompatAvatarPictureModel) model_weak.get();
            if (model != null) {
                model.on_received_avatar(jid, account);
            } else if (avatar_manager_fetched_avatar_handler_id != 0) {
                avatar_manager.disconnect(avatar_manager_fetched_avatar_handler_id);
                avatar_manager_fetched_avatar_handler_id = 0;
            }
        });
    }

    private void on_room_updated(Account account, Jid room) {
        if (conversation != null && account.equals(conversation.account) && conversation.counterpart.equals_bare(room)) {
            reset();
            set_conversation(conversation);
        }
    }

    private void on_received_avatar(Jid jid, Account account) {
        on_room_updated(account, jid);
    }

    public void reset() {
        (tiles as GLib.ListStore).remove_all();
    }

    public CompatAvatarPictureModel set_conversation(Conversation conversation) {
        if (stream_interactor == null) {
            critical("set_conversation() used on CompatAvatarPictureModel without stream_interactor");
            return this;
        }
        this.conversation = conversation;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            if (avatar_manager.has_avatar(conversation.account, conversation.counterpart)) {
                add_internal("#", conversation.counterpart.to_string(), avatar_manager.get_avatar_file(conversation.account, conversation.counterpart));
            } else {
                Gee.List<Jid>? occupants = muc_manager.get_other_offline_members(conversation.counterpart, conversation.account);
                if (occupants != null && !occupants.is_empty && muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
                    int count = occupants.size > 4 ? 3 : occupants.size;
                    for (int i = 0; i < count; i++) {
                        add_participant(conversation, occupants[i]);
                    }
                    if (occupants.size > 4) {
                        add_internal("+");
                    }
                } else {
                    add_internal("#", conversation.counterpart.to_string());
                }
            }
        } else {
            add_participant(conversation, conversation.counterpart);
        }
        return this;
    }

    public CompatAvatarPictureModel remove_participant_avatar(Conversation conversation, Jid jid) {
        if (stream_interactor == null) {
            critical("Remove_participant() used on CompatAvatarPictureModel without stream_interactor");
            return this;
        }

        (tiles as GLib.ListStore).append(new ConversationParticipantAvatarPictureTileModel.remove_avatar_picture(stream_interactor, conversation, jid));
        return this;
    }

    public CompatAvatarPictureModel add_participant(Conversation conversation, Jid jid) {
        if (stream_interactor == null) {
            critical("add_participant() used on CompatAvatarPictureModel without stream_interactor");
            return this;
        }
        (tiles as GLib.ListStore).append(new ConversationParticipantAvatarPictureTileModel(stream_interactor, conversation, jid));
        return this;
    }

    public CompatAvatarPictureModel add(string display, string? color_id = null, File? image_file = null) {
        add_internal(display, color_id, image_file);
        return this;
    }

    private AvatarPictureTileModel add_internal(string display, string? color_id = null, File? image_file = null) {
        GLib.ListStore store = tiles as GLib.ListStore;
        float[] rgbf = color_id != null ? Xep.ConsistentColor.string_to_rgbf(color_id) : new float[] {0.5f, 0.5f, 0.5f};
        var model = new ViewModel.AvatarPictureTileModel() {
            display_text = display.get_char(0).toupper().to_string(),
            background_color = Gdk.RGBA() { red = rgbf[0], green = rgbf[1], blue = rgbf[2], alpha = 1.0f},
            image_file = image_file
        };
        store.append(model);
        return model;
    }
}


public class Dino.Ui.CompatAvatarDrawer {
    public float radius_percent { get; set; default = 0.2f; }
    public ViewModel.AvatarPictureModel? model { get; set; }
    public int height_request { get; set; default = 35; }
    public int width_request { get; set; default = 35; }
    public string font_family { get; set; default = "Sans"; }

    public Cairo.ImageSurface draw_image_surface() {
        Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width_request, height_request);
        draw_on_context(new Cairo.Context(surface));
        return surface;
    }

    public void draw_on_context(Cairo.Context ctx) {
        double radius = (width_request + height_request) * 0.25f * radius_percent;
        double degrees = Math.PI / 180.0;
        ctx.new_sub_path();
        ctx.arc(width_request - radius, radius, radius, -90 * degrees, 0 * degrees);
        ctx.arc(width_request - radius, height_request - radius, radius, 0 * degrees, 90 * degrees);
        ctx.arc(radius, height_request - radius, radius, 90 * degrees, 180 * degrees);
        ctx.arc(radius, radius, radius, 180 * degrees, 270 * degrees);
        ctx.close_path();
        ctx.clip();

        if (this.model.tiles.get_n_items() == 4) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width_request, height_request);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width_request - 1, height_request - 1, 2), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width_request - 1, height_request - 1, 2), width_request + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 2, width_request - 1, height_request - 1, 2), 0, height_request + 1);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 3, width_request - 1, height_request - 1, 2), width_request + 1, height_request + 1);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.model.tiles.get_n_items() == 3) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width_request, height_request);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width_request - 1, height_request - 1, 2), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width_request - 1, height_request * 2, 2), width_request + 1, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 2, width_request - 1, height_request - 1, 2), 0, width_request + 1);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.model.tiles.get_n_items() == 2) {
            Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width_request, height_request);
            Cairo.Context bufctx = new Cairo.Context(buffer);
            bufctx.scale(0.5, 0.5);
            bufctx.set_source_surface(sub_surface_idx(ctx, 0, width_request - 1, height_request * 2, 2), 0, 0);
            bufctx.paint();
            bufctx.set_source_surface(sub_surface_idx(ctx, 1, width_request - 1, height_request * 2, 2), width_request + 1, 0);
            bufctx.paint();

            ctx.set_source_surface(buffer, 0, 0);
            ctx.paint();
        } else if (this.model.tiles.get_n_items() == 1) {
            ctx.set_source_surface(sub_surface_idx(ctx, 0, width_request, height_request, 1), 0, 0);
            ctx.paint();
        } else if (this.model.tiles.get_n_items() == 0) {
            ctx.set_source_surface(sub_surface_idx(ctx, -1, width_request, height_request, 1), 0, 0);
            ctx.paint();
        }
        ctx.set_source_rgb(0, 0, 0);
    }

    private Cairo.Surface sub_surface_idx(Cairo.Context ctx, int idx, int width, int height, int font_factor = 1) {
        ViewModel.AvatarPictureTileModel tile = (ViewModel.AvatarPictureTileModel) this.model.tiles.get_item(idx);
        Gdk.Pixbuf? avatar = new Gdk.Pixbuf.from_file(tile.image_file.get_path());
        string? name = idx >= 0 ? tile.display_text : "";
        Gdk.RGBA hex_color = tile.background_color;
        return sub_surface(ctx, font_family, avatar, name, hex_color, width, height, font_factor);
    }

    private static Cairo.Surface sub_surface(Cairo.Context ctx, string font_family, Gdk.Pixbuf? avatar, string? name, Gdk.RGBA background_color, int width, int height, int font_factor = 1) {
        Cairo.Surface buffer = new Cairo.Surface.similar(ctx.get_target(), Cairo.Content.COLOR_ALPHA, width, height);
        Cairo.Context bufctx = new Cairo.Context(buffer);
        if (avatar == null) {
            Gdk.cairo_set_source_rgba(bufctx, background_color);
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
}

public class Dino.Ui.AvatarPicture : Gtk.Widget {
    public float radius_percent { get; set; default = 0.2f; }
    public ViewModel.AvatarPictureModel? model { get; set; }
    private Gee.List<Tile> tiles = new Gee.ArrayList<Tile>();

    private ViewModel.AvatarPictureModel? old_model;
    private ulong model_tiles_items_changed_handler;

    construct {
        height_request = 35;
        width_request = 35;
        set_css_name("picture");
        add_css_class("avatar");
        notify["radius-percent"].connect(queue_draw);
        notify["model"].connect(on_model_changed);
    }

    private void on_model_changed() {
        if (old_model != null) {
            old_model.tiles.disconnect(model_tiles_items_changed_handler);
        }
        foreach (Tile tile in tiles) {
            tile.unparent();
            tile.dispose();
        }
        tiles.clear();
        old_model = model;
        if (model != null) {
            model_tiles_items_changed_handler = model.tiles.items_changed.connect(on_model_items_changed);
            for(int i = 0; i < model.tiles.get_n_items(); i++) {
                Tile tile = new Tile();
                tile.model = model.tiles.get_item(i) as ViewModel.AvatarPictureTileModel;
                tile.insert_after(this, tiles.is_empty ? null : tiles.last());
                tiles.add(tile);
            }
        }
    }

    private void on_model_items_changed(uint position, uint removed, uint added) {
        while (removed > 0) {
            Tile old = tiles.remove_at((int) position);
            old.unparent();
            old.dispose();
            removed--;
        }
        while (added > 0) {
            Tile tile = new Tile();
            tile.model = model.tiles.get_item(position) as ViewModel.AvatarPictureTileModel;
            tile.insert_after(this, position == 0 ? null : tiles[(int) position - 1]);
            tiles.insert((int) position, tile);
            position++;
            added--;
        }
        queue_allocate();
    }

    public override void measure(Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        minimum_baseline = natural_baseline = -1;
        if (orientation == Orientation.HORIZONTAL) {
            minimum = natural = width_request;
        } else {
            minimum = natural = height_request;
        }
    }

    public override void size_allocate(int width, int height, int baseline) {
        int half_width_size = width / 2;
        int half_height_size = height / 2;
        int half_width_offset = (width % 2 == 0) ? half_width_size : half_width_size + 1;
        int half_height_offset = (height % 2 == 0) ? half_height_size : half_height_size + 1;
        if (tiles.size == 1) {
            tiles[0].allocate(width, height, baseline, null);
        } else if (tiles.size == 2) {
            tiles[0].allocate_size(Allocation() { x = 0, y = 0, width = half_width_size, height = height }, baseline);
            tiles[1].allocate_size(Allocation() { x = half_width_offset, y = 0, width = half_width_size, height = height }, baseline);
        } else if (tiles.size == 3) {
            tiles[0].allocate_size(Allocation() { x = 0, y = 0, width = half_width_size, height = height }, baseline);
            tiles[1].allocate_size(Allocation() { x = half_width_offset, y = 0, width = half_width_size, height = half_height_size }, baseline);
            tiles[2].allocate_size(Allocation() { x = half_width_offset, y = half_height_offset, width = half_width_size, height = half_height_size }, baseline);
        } else if (tiles.size == 4) {
            tiles[0].allocate_size(Allocation() { x = 0, y = 0, width = half_width_size, height = half_height_size }, baseline);
            tiles[1].allocate_size(Allocation() { x = half_width_offset, y = 0, width = half_width_size, height = half_height_size }, baseline);
            tiles[2].allocate_size(Allocation() { x = 0, y = half_height_offset, width = half_width_size, height = half_height_size }, baseline);
            tiles[3].allocate_size(Allocation() { x = half_width_offset, y = half_height_offset, width = half_width_size, height = half_height_size }, baseline);
        }
    }

    public override SizeRequestMode get_request_mode() {
        return SizeRequestMode.CONSTANT_SIZE;
    }

    public override void snapshot(Gtk.Snapshot snapshot) {
        Graphene.Rect bounds = Graphene.Rect();
        bounds.init(0, 0, get_width(), get_height());
        Gsk.RoundedRect rounded_rect = Gsk.RoundedRect();
        rounded_rect.init_from_rect(bounds, (get_width() + get_height()) * 0.25f * radius_percent);
        snapshot.push_rounded_clip(rounded_rect);
        base.snapshot(snapshot);
        snapshot.pop();
    }

    public override void dispose() {
        model = null;
        on_model_changed();
        base.dispose();
    }

    private class Tile : Gtk.Widget {
        public ViewModel.AvatarPictureTileModel? model { get; set; }
        public Gdk.RGBA background_color { get; set; default = Gdk.RGBA(){ red = 1.0f, green = 1.0f, blue = 1.0f, alpha = 0.0f }; }
        public string display_text { get { return label.get_text(); } set { label.set_text(value); } }
        public File? image_file { get { return picture.file; } set { picture.file = value; } }

        private Binding? background_color_binding;
        private Binding? display_text_binding;
        private Binding? image_file_binding;

        private Label label = new Label("");
        private Picture picture = new Picture();

        construct {
            label.insert_after(this, null);
            label.attributes = new Pango.AttrList();
            label.attributes.insert(Pango.attr_foreground_new(uint16.MAX, uint16.MAX, uint16.MAX));
#if GTK_4_8 && VALA_0_58
            picture.content_fit = Gtk.ContentFit.COVER;
#elif GTK_4_8
            picture.@set("content-fit", 2);
#endif
            picture.insert_after(this, label);
            this.notify["model"].connect(on_model_changed);
        }

        private void on_model_changed() {
            if (background_color_binding != null) background_color_binding.unbind();
            if (display_text_binding != null) display_text_binding.unbind();
            if (image_file_binding != null) image_file_binding.unbind();
            if (model != null) {
                background_color_binding = model.bind_property("background-color", this, "background-color", BindingFlags.SYNC_CREATE);
                display_text_binding = model.bind_property("display-text", this, "display-text", BindingFlags.SYNC_CREATE);
                image_file_binding = model.bind_property("image-file", this, "image-file", BindingFlags.SYNC_CREATE);
            } else {
                background_color_binding = null;
                display_text_binding = null;
                image_file_binding = null;
            }
        }

        public override void dispose() {
            if (background_color_binding != null) background_color_binding.unbind();
            if (display_text_binding != null) display_text_binding.unbind();
            if (image_file_binding != null) image_file_binding.unbind();
            background_color_binding = null;
            display_text_binding = null;
            image_file_binding = null;
            label.unparent();
            picture.unparent();
            base.dispose();
        }

        public override void size_allocate(int width, int height, int baseline) {
            int min, nat, bl_min, bl_nat;
            picture.measure(Orientation.HORIZONTAL, -1, out min, out nat, out bl_min, out bl_nat);
            if (nat > 0) {
                picture.allocate(width, height, baseline, null);
                label.visible = false;
            } else {
                picture.allocate(0, 0, 0, null);
                label.attributes = new Pango.AttrList();
                label.attributes.insert(Pango.attr_foreground_new(uint16.MAX, uint16.MAX, uint16.MAX));
                label.attributes.insert(Pango.attr_scale_new(double.min((double)width, (double)height) * 0.05));
                label.margin_bottom = height/40;
                label.visible = true;
                label.allocate(width, height, baseline, null);
            }
        }

        public override void snapshot(Gtk.Snapshot snapshot) {
            if (label.visible) {
                Graphene.Rect bounds = Graphene.Rect();
                bounds.init(0, 0, get_width(), get_height());
                snapshot.append_node(new Gsk.ColorNode(background_color, bounds));
            }
            base.snapshot(snapshot);
        }
    }
}