using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class ListRow : Widget {

    public Grid outer_grid;
    public AvatarImage image;
    public Label name_label;
    public Label via_label;

    public Jid? jid;
    public Account? account;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/add_conversation/list_row.ui");
        outer_grid = (Grid) builder.get_object("outer_grid");
        image = (AvatarImage) builder.get_object("image");
        name_label = (Label) builder.get_object("name_label");
        via_label = (Label) builder.get_object("via_label");

        this.layout_manager = new BinLayout();
        outer_grid.set_parent(this);
    }

    public ListRow() {}

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
        image.set_conversation(stream_interactor, conv);
    }

    public override void dispose() {
        outer_grid.unparent();
    }
}

}
