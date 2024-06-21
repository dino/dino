using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class ListRow : Widget {

    public Box outer_box;
    public AvatarPicture picture;
    public Label name_label;
    public Image status_dot;
    public Label via_label;

    public StreamInteractor stream_interactor;
    public Jid jid;
    public Account account;

    private ulong[] handler_ids = new ulong[0];

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/add_conversation/list_row.ui");
        outer_box = (Box) builder.get_object("outer_box");
        picture = (AvatarPicture) builder.get_object("picture");
        name_label = (Label) builder.get_object("name_label");
        status_dot = (Image) builder.get_object("status_dot");
        via_label = (Label) builder.get_object("via_label");


        this.layout_manager = new BinLayout();
        outer_box.set_parent(this);
    }

    private void set_status_dot(StreamInteractor stream_interactor){
        status_dot.visible = stream_interactor.connection_manager.get_state(account) == ConnectionManager.ConnectionState.CONNECTED;

        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);
        if (full_jids != null) {
            var statuses = new ArrayList<string>();
            foreach (var full_jid in full_jids) {
                statuses.add(stream_interactor.get_module(PresenceManager.IDENTITY).get_last_show(full_jid, account));
            }

            if (statuses.contains(Xmpp.Presence.Stanza.SHOW_DND)) status_dot.set_from_icon_name("dino-status-dnd");
            else if (statuses.contains(Xmpp.Presence.Stanza.SHOW_CHAT)) status_dot.set_from_icon_name("dino-status-chat");
            else if (statuses.contains(Xmpp.Presence.Stanza.SHOW_ONLINE)) status_dot.set_from_icon_name("dino-status-online");
            else if (statuses.contains(Xmpp.Presence.Stanza.SHOW_AWAY)) status_dot.set_from_icon_name("dino-status-away");
            else if (statuses.contains(Xmpp.Presence.Stanza.SHOW_XA)) status_dot.set_from_icon_name("dino-status-away");
            else status_dot.set_from_icon_name("dino-status-offline");
        } else {
            status_dot.set_from_icon_name("dino-status-offline");
        }
    }

    public ListRow.from_jid(StreamInteractor stream_interactor, Jid jid, Account account, bool show_account) {
        this.stream_interactor = stream_interactor;
        this.jid = jid;
        this.account = account;

        Conversation conv = new Conversation(jid, account, Conversation.Type.CHAT);
        string display_name = Util.get_conversation_display_name(stream_interactor, conv);
        if (show_account && stream_interactor.get_accounts().size > 1) {
            via_label.label = @"via $(account.bare_jid)";
            this.has_tooltip = Util.use_tooltips();
            set_tooltip_text(Util.string_if_tooltips_active(jid.to_string()));
        } else if (display_name != jid.bare_jid.to_string()){
            via_label.label = jid.bare_jid.to_string();
        } else {
            via_label.visible = false;
        }
        name_label.label = display_name;
        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(conv);

        handler_ids += stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect((jid, account) => {
            if (account.equals(this.account) && jid.equals_bare(this.jid)) {
                set_status_dot(stream_interactor);
            }
        });
        handler_ids += stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => {
            if (account.equals(this.account) && jid.equals_bare(this.jid)) {
                set_status_dot(stream_interactor);
            }
        });

        set_status_dot(stream_interactor);
    }

    public override void dispose() {
        outer_box.unparent();

        foreach (var handler_id in handler_ids) {
            stream_interactor.get_module(PresenceManager.IDENTITY).disconnect(handler_id);
        }
    }
}

}
