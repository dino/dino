using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/list_row.ui")]
public class ListRow : ListBoxRow {

    [GtkChild] public unowned AvatarImage image;
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label via_label;

    public Jid? jid;
    public Account? account;

    public ListRow() {}

    public ListRow.from_jid(StreamInteractor stream_interactor, Jid jid, Account account, bool show_account) {
        this.jid = jid;
        this.account = account;

        Conversation conv = new Conversation(jid, account, Conversation.Type.CHAT);
        string display_name = Util.get_conversation_display_name(stream_interactor, conv);
        if (show_account && stream_interactor.get_accounts().size > 1) {
            via_label.label = @"via $(account.bare_jid)";
            this.has_tooltip = true;
            set_tooltip_text(jid.to_string());
        } else if (display_name != jid.bare_jid.to_string()){
            via_label.label = jid.bare_jid.to_string();
        } else {
            via_label.visible = false;
        }
        name_label.label = display_name;
        image.set_conversation(stream_interactor, conv);
    }
}

}
