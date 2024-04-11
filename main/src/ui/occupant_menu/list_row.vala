using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

public class ListRow : Object {

    private Grid main_grid;
    private AvatarPicture picture;
    public Label name_label;
    public Image status_image;
    public Conversation? conversation;
    public Jid? jid;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/occupant_list_item.ui");
        main_grid = (Grid) builder.get_object("main_grid");
        picture = (AvatarPicture) builder.get_object("picture");
        name_label = (Label) builder.get_object("name_label");
        status_image = (Image) builder.get_object("status_image");
        main_grid.set_column_spacing(10);
        main_grid.set_column_homogeneous(false);
        main_grid.set_baseline_row(1);
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

    public void set_online() {
        status_image.icon_name = "dino-status-online-bright";
    }

    public void set_offline() {
        status_image.icon_name = "dino-status-offline";
    }
}

}
