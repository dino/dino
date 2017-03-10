using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/occupant_list_item.ui")]
public class OccupantListRow : ListBoxRow {

    [GtkChild]
    private Image image;

    [GtkChild]
    public Label name_label;

    public OccupantListRow(StreamInteractor stream_interactor, Account account, Jid jid) {
        name_label.label = Util.get_display_name(stream_interactor, jid, account);
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(30, 30, image.scale_factor)).draw_jid(stream_interactor, jid, account));
        //has_tooltip = true;
    }

    public void on_presence_received(Presence.Stanza presence) {

    }
}
}