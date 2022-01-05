using Gtk;
using Dino.Entities;
using Xmpp;
using Xmpp.Util;

namespace Dino.Ui {

public class AvatarImage : Misc {
    public int height { get; set; default = 35; }
    public int width { get; set; default = 35; }
    public bool allow_gray { get; set; default = true; }
    public bool force_gray { get; set; default = false; }
    public StreamInteractor? stream_interactor { get; set; }
    public AvatarManager? avatar_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(AvatarManager.IDENTITY); } }
    public MucManager? muc_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(MucManager.IDENTITY); } }
    public PresenceManager? presence_manager { owned get { return stream_interactor == null ? null : stream_interactor.get_module(PresenceManager.IDENTITY); } }
    public ConnectionManager? connection_manager { owned get { return stream_interactor == null ? null : stream_interactor.connection_manager; } }
    public Account account { get { return conversation.account; } }
    private AvatarDrawer? drawer;
    private Conversation conversation;
    private Jid[] jids;
    private Cairo.ImageSurface? cached_surface;
    private static int8 use_image_surface = -1;

    public AvatarImage() {
        can_focus = false;
        get_style_context().add_class("avatar");
    }

    public override void dispose() {
        base.dispose();
        drawer = null;
        cached_surface = null;
        disconnect_stream_interactor();
    }

    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        minimum_width = width;
        natural_width = width;
    }

    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        minimum_height = height;
        natural_height = height;
    }

    public override bool draw(Cairo.Context ctx_in) {
        Cairo.Context ctx = ctx_in;
        int width = this.width, height = this.height, base_factor = 1;
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

        AvatarDrawer drawer = this.drawer;
        Jid[] jids = this.jids;
        if (drawer == null && jids.length == 0) {
            switch (conversation.type_) {
                case Conversation.Type.CHAT:
                case Conversation.Type.GROUPCHAT_PM:
                    // In direct chats or group chats, conversation avatar is same as counterpart avatar
                    jids = { conversation.counterpart };
                    break;
                case Conversation.Type.GROUPCHAT:
                    string user_color = Util.get_avatar_hex_color(stream_interactor, account, conversation.counterpart, conversation);
                    if (avatar_manager.has_avatar_cached(account, conversation.counterpart)) {
                        drawer = new AvatarDrawer().tile(avatar_manager.get_cached_avatar(account, conversation.counterpart), "#", user_color);
                        if (force_gray || allow_gray && (!is_self_online() || !is_counterpart_online())) drawer.grayscale();
                    } else {
                        Gee.List<Jid>? occupants = muc_manager.get_other_offline_members(conversation.counterpart, account);
                        if (muc_manager.is_private_room(account, conversation.counterpart) && occupants != null && occupants.size > 0) {
                            jids = occupants.to_array();
                        } else {
                            drawer = new AvatarDrawer().tile(null, "#", user_color);
                            if (force_gray || allow_gray && (!is_self_online() || !is_counterpart_online())) drawer.grayscale();
                        }
                        try_load_avatar_async(conversation.counterpart);
                    }
                    break;
            }
        }
        if (drawer == null && jids.length > 0) {
            drawer = new AvatarDrawer();
            for (int i = 0; i < (jids.length <= 4 ? jids.length : 3); i++) {
                Jid avatar_jid = jids[i];
                Jid? real_avatar_jid = null;
                if (conversation.type_ != Conversation.Type.CHAT && avatar_jid.equals_bare(conversation.counterpart) && muc_manager.is_private_room(account, conversation.counterpart.bare_jid)) {
                    // In private room, consider real jid
                    real_avatar_jid = muc_manager.get_real_jid(avatar_jid, account) ?? avatar_jid;
                }
                string display_name = Util.get_participant_display_name(stream_interactor, conversation, jids[i]);
                string user_color = Util.get_avatar_hex_color(stream_interactor, account, jids[i], conversation);
                if (avatar_manager.has_avatar_cached(account, avatar_jid)) {
                    drawer.tile(avatar_manager.get_cached_avatar(account, avatar_jid), display_name, user_color);
                } else if (real_avatar_jid != null && avatar_manager.has_avatar_cached(account, real_avatar_jid)) {
                    drawer.tile(avatar_manager.get_cached_avatar(account, real_avatar_jid), display_name, user_color);
                } else {
                    drawer.tile(null, display_name, user_color);
                    try_load_avatar_async(avatar_jid);
                    if (real_avatar_jid != null) try_load_avatar_async(real_avatar_jid);
                }
            }
            if (jids.length > 4) {
                drawer.plus();
            }
            if (force_gray || allow_gray && (!is_self_online() || !is_counterpart_online())) drawer.grayscale();
        }


        if (drawer == null) return false;
        drawer.size(height, width)
                .scale(base_factor)
                .font(get_pango_context().get_font_description().get_family())
                .draw_on_context(ctx);

        if (use_image_surface == 1) {
            ctx_in.set_source_surface(ctx.get_target(), 0, 0);
            ctx_in.paint();
            ctx_in.set_source_rgb(0, 0, 0);
        }

        return true;
    }

    private void try_load_avatar_async(Jid jid) {
        if (avatar_manager.has_avatar(account, jid)) {
            avatar_manager.get_avatar.begin(account, jid, (_, res) => {
                var avatar = avatar_manager.get_avatar.end(res);
                if (avatar != null) force_redraw();
            });
        }
    }

    private void force_redraw() {
        this.cached_surface = null;
        queue_draw();
    }

    private void disconnect_stream_interactor() {
        if (stream_interactor != null) {
            presence_manager.show_received.disconnect(on_show_received);
            presence_manager.received_offline_presence.disconnect(on_show_received);
            avatar_manager.received_avatar.disconnect(on_received_avatar);
            stream_interactor.connection_manager.connection_state_changed.disconnect(on_connection_changed);
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.disconnect(on_roster_updated);
            muc_manager.private_room_occupant_updated.disconnect(on_private_room_occupant_updated);
            muc_manager.room_info_updated.disconnect(on_room_info_updated);
            stream_interactor = null;
        }
    }

    private void on_show_received(Jid jid, Account account) {
        if (!account.equals(this.account)) return;
        update_avatar_if_jid(jid);
    }

    private void on_received_avatar(Jid jid, Account account) {
        if (!account.equals(this.account)) return;
        update_avatar_if_jid(jid);
    }

    private void update_avatar_if_jid(Jid jid) {
        if (jid.equals_bare(this.conversation.counterpart)) {
            force_redraw();
            return;
        }
        foreach (Jid ours in this.jids) {
            if (jid.equals_bare(ours)) {
                force_redraw();
                return;
            }
        }
    }

    private void on_connection_changed(Account account, ConnectionManager.ConnectionState state) {
        if (!account.equals(this.account)) return;
        force_redraw();
    }

    private void on_roster_updated(Account account, Jid jid, Roster.Item roster_item) {
        if (!account.equals(this.account)) return;
        update_avatar_if_jid(jid);
    }

    private void on_private_room_occupant_updated(Account account, Jid room, Jid occupant) {
        if (!account.equals(this.account)) return;
        update_avatar_if_jid(room);
    }

    private void on_room_info_updated(Account account, Jid muc_jid) {
        if (!account.equals(this.account)) return;
        update_avatar_if_jid(muc_jid);
    }

    private bool is_self_online() {
        if (connection_manager != null) {
            return connection_manager.get_state(account) == ConnectionManager.ConnectionState.CONNECTED;
        }
        return false;
    }

    private bool is_counterpart_online() {
        return presence_manager.get_full_jids(conversation.counterpart, account) != null;
    }

    public void set_conversation(StreamInteractor stream_interactor, Conversation conversation) {
        set_avatar(stream_interactor, conversation, new Jid[0]);
    }

    public void set_conversation_participant(StreamInteractor stream_interactor, Conversation conversation, Jid sub_jid) {
        set_avatar(stream_interactor, conversation, new Jid[] {sub_jid});
    }

    public void set_conversation_participants(StreamInteractor stream_interactor, Conversation conversation, Jid[] sub_jids) {
        set_avatar(stream_interactor, conversation, sub_jids);
    }

    private void set_avatar(StreamInteractor stream_interactor, Conversation conversation, Jid[] jids) {
        if (this.stream_interactor != null && stream_interactor != this.stream_interactor) {
            disconnect_stream_interactor();
        }
        if (this.stream_interactor != stream_interactor) {
            this.stream_interactor = stream_interactor;
            presence_manager.show_received.connect(on_show_received);
            presence_manager.received_offline_presence.connect(on_show_received);
            stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect(on_received_avatar);
            stream_interactor.connection_manager.connection_state_changed.connect(on_connection_changed);
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect(on_roster_updated);
            muc_manager.private_room_occupant_updated.connect(on_private_room_occupant_updated);
            muc_manager.room_info_updated.connect(on_room_info_updated);
        }
        this.cached_surface = null;
        this.conversation = conversation;
        this.jids = jids;

        force_redraw();
    }

    public void set_text(string text, bool gray = true) {
        disconnect_stream_interactor();
        this.drawer = new AvatarDrawer().tile(null, text, null);
        if (gray) drawer.grayscale();
        force_redraw();
    }
}

}
