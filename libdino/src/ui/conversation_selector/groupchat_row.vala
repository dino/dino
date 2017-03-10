using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class GroupchatRow : ConversationRow {

    public GroupchatRow(StreamInteractor stream_interactor, Conversation conversation) {
        base(stream_interactor, conversation);
        has_tooltip = true;
        set_tooltip_text(conversation.counterpart.bare_jid.to_string());
        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .set_greyscale(true)
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
        x_button.clicked.connect(on_x_button_clicked);
    }


    public override void on_show_received(Show show) {
        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
    }

    public override void network_connection(bool connected) {
        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .set_greyscale(!connected ||
                    MucManager.get_instance(stream_interactor).get_nick(conversation.counterpart, conversation.account) == null) // TODO better currently joined
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
    }

    private void on_x_button_clicked() {
        MucManager.get_instance(stream_interactor).part(conversation.account, conversation.counterpart);
    }
}

}