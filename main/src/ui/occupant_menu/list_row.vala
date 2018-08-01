using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

[GtkTemplate (ui = "/im/dino/Dino/occupant_list_item.ui")]
public class ListRow : ListBoxRow {

    [GtkChild] private AvatarImage image;
    [GtkChild] public Label name_label;

    public Account? account;
    public Jid? jid;

    public ListRow(StreamInteractor stream_interactor, Account account, Jid jid) {
        this.account = account;
        this.jid = jid;

        name_label.label = Util.get_display_name(stream_interactor, jid, account);
        image.set_jid(stream_interactor, jid, account);
    }

    public ListRow.label(string c, string text) {
        name_label.label = text;
        image.set_text(c);
    }
}

}
