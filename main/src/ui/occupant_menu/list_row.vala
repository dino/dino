using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

public class ListRow : Object {

    private Grid main_grid;
    private AvatarPicture picture;
    public Label name_label;

    public Conversation? conversation;
    public Jid? jid;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/occupant_list_item.ui");
        main_grid = (Grid) builder.get_object("main_grid");
        picture = (AvatarPicture) builder.get_object("picture");
        name_label = (Label) builder.get_object("name_label");
    }

    public ListRow(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        this.conversation = conversation;
        this.jid = jid;

        name_label.label = Util.get_participant_display_name(stream_interactor, conversation, jid);
        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(conversation, jid);
    }

    public ListRow.label(string c, string text) {
        name_label.label = text;
        picture.model = new ViewModel.CompatAvatarPictureModel(null).add(c);
    }

    public Widget get_widget() {
        return main_grid;
    }
}

}
