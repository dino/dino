using Gtk;
using Dino.Entities;
using Xmpp;
using Xmpp.Util;

namespace Dino.Ui {

public class AvatarImage : Misc {
    public int height { get; set; default = 35; }
    public int width { get; set; default = 35; }
    public bool allow_gray { get; set; default = true; }
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

    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        minimum_width = width;
        natural_width = width;
    }

    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        minimum_height = height;
        natural_height = height;
    }

    public override bool draw(Cairo.Context ctx_in) {
        if (drawer == null) return false;

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

        drawer.size(height, width)
            .scale(base_factor)
            .font(get_pango_context().get_font_description().get_family())
            .draw_on_context(ctx);

        if (use_image_surface == 1) {
            ctx_in.set_source_surface(ctx.get_target(), 0, 0);
            ctx_in.paint();
        }

        return true;
    }

    public override void destroy() {
        disconnect_stream_interactor();
    }

    private void disconnect_stream_interactor() {
        if (stream_interactor != null) {
            presence_manager.show_received.disconnect(on_show_received);
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
            update_avatar_async.begin();
            return;
        }
        foreach (Jid ours in this.jids) {
            if (jid.equals_bare(ours)) {
                update_avatar_async.begin();
                return;
            }
        }
    }

    private void on_connection_changed(Account account, ConnectionManager.ConnectionState state) {
        if (!account.equals(this.account)) return;
        update_avatar_async.begin();
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
        set_avatar_async.begin(stream_interactor, conversation, new Jid[0]);
    }

    public void set_conversation_participant(StreamInteractor stream_interactor, Conversation conversation, Jid sub_jid) {
        set_avatar_async.begin(stream_interactor, conversation, new Jid[] {sub_jid});
    }

    public void set_conversation_participants(StreamInteractor stream_interactor, Conversation conversation, Jid[] sub_jids) {
        set_avatar_async.begin(stream_interactor, conversation, sub_jids);
    }

    private async void update_avatar_async() {
        this.cached_surface = null;
        this.drawer = yield Util.get_conversation_participants_avatar_drawer(stream_interactor, conversation, jids);
        if (allow_gray && (!is_self_online() || !is_counterpart_online())) drawer.grayscale();

        queue_draw();
    }

    private async void set_avatar_async(StreamInteractor stream_interactor, Conversation conversation, Jid[] jids) {
        if (this.stream_interactor != null && stream_interactor != this.stream_interactor) {
            disconnect_stream_interactor();
        }
        if (this.stream_interactor != stream_interactor) {
            this.stream_interactor = stream_interactor;
            presence_manager.show_received.connect(on_show_received);
            stream_interactor.get_module(AvatarManager.IDENTITY).received_avatar.connect(on_received_avatar);
            stream_interactor.connection_manager.connection_state_changed.connect(on_connection_changed);
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect(on_roster_updated);
            muc_manager.private_room_occupant_updated.connect(on_private_room_occupant_updated);
            muc_manager.room_info_updated.connect(on_room_info_updated);
        }
        this.cached_surface = null;
        this.conversation = conversation;
        this.jids = jids;

        yield update_avatar_async();
    }

    public void set_text(string text, bool gray = true) {
        disconnect_stream_interactor();
        this.drawer = new AvatarDrawer().tile(null, text, null);
        if (gray) drawer.grayscale();
        queue_draw();
    }
}

}
