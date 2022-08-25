using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

public class ListRow : Object {

    private Grid main_grid;
    private AvatarImage image;
    public Label name_label;

    public Conversation? conversation;
    public Jid? jid;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/occupant_list_item.ui");
        main_grid = (Grid) builder.get_object("main_grid");
        image = (AvatarImage) builder.get_object("image");
        name_label = (Label) builder.get_object("name_label");
    }

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

    public Widget get_widget() {
        return main_grid;
    }
}

}
