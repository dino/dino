using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class ListRow : Widget {

    public Grid outer_grid;
    public AvatarPicture picture;
    public Label name_label;
    public Image status_dot;
    public Label via_label;

    public string? status_str;
    public Jid? jid;
    public Account? account;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/add_conversation/list_row.ui");
        outer_grid = (Grid) builder.get_object("outer_grid");
        picture = (AvatarPicture) builder.get_object("picture");
        name_label = (Label) builder.get_object("name_label");
        status_dot = (Image) builder.get_object("status_dot");
        via_label = (Label) builder.get_object("via_label");


        this.layout_manager = new BinLayout();
        outer_grid.set_parent(this);
    }

    public ListRow() {}

    private void set_status_dot(StreamInteractor stream_interactor, Jid jid, Account account){
        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);
        string presence_str = null;
        if (full_jids != null){
            int devices = 0;
            string newline_if_more_devices;
            for (int i = 0; i < full_jids.size; i++) {
                Jid full_jid = full_jids[i];
                presence_str = stream_interactor.get_module(PresenceManager.IDENTITY).get_last_show(full_jid, account);
                if(presence_str != null) devices += 1;
                newline_if_more_devices = devices > 1 ? "\r\n" : "";
                switch(presence_str){
                        case "dnd": this.status_dot.set_from_icon_name("dino-status-dnd"); i = full_jids.size; break; // dnd detected = marked as dnd for all devices
                        case "online": this.status_dot.set_from_icon_name("dino-status-online"); i = full_jids.size; break;
                        case "away": this.status_dot.set_from_icon_name("dino-status-away"); break;
                        case "xa": this.status_dot.set_from_icon_name("dino-status-away"); break;
                        case "chat": this.status_dot.set_from_icon_name("dino-status-chat"); break;
                }
                status_str = presence_str;
            }
        }
        else status_dot.set_from_icon_name("dino-status-offline");
    }

    public ListRow.from_jid(StreamInteractor stream_interactor, Jid jid, Account account, bool show_account) {
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
        set_status_dot(stream_interactor, jid, account);
    }

    public override void dispose() {
        outer_grid.unparent();
    }
}

}
