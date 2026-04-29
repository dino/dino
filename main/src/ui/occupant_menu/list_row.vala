using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

public class ListRow : Object {

    private Grid main_grid;
    private AvatarPicture picture;
    private Gtk.Box hats_area;
    public Label name_label;

    public Conversation? conversation;
    public Jid? jid;

    construct {
        Builder builder = new Builder.from_resource("/im/dino/Dino/occupant_list_item.ui");
        main_grid = (Grid) builder.get_object("main_grid");
        picture = (AvatarPicture) builder.get_object("picture");
        hats_area = (Gtk.Box) builder.get_object("hats_area");
        name_label = (Label) builder.get_object("name_label");
    }

    public ListRow(StreamInteractor stream_interactor, Conversation conversation, Jid jid) {
        this.conversation = conversation;
        this.jid = jid;

        name_label.label = Util.get_participant_display_name(stream_interactor, conversation, jid);
        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(conversation, jid);

        var hats = stream_interactor.get_module(PresenceManager.IDENTITY).get_hats(jid);
        foreach (var hat in hats) {
            var entry = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            entry.add_css_class("dino-tag");

            var label = new Gtk.Label(hat.title);

            entry.append(label);
            hats_area.append(entry);
        }
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
