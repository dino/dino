using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

[GtkTemplate (ui = "/im/dino/Dino/occupant_list_item.ui")]
public class ListRow : ListBoxRow {

    [GtkChild] private AvatarImage image;
    [GtkChild] public Label name_label;

    public Conversation? conversation;
    public Jid? jid;

    public ListRow(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        this.conversation = conversation;
        this.jid = jid;

        name_label.label = Util.get_participant_display_name(stream_interactor, conversation, jid);
        image.set_conversation_participant(stream_interactor, conversation, jid);
    }

    public ListRow.label(string c, string text) {
        name_label.label = text;
        image.set_text(c);
    }
}

}
