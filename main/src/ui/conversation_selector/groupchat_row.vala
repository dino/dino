using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class GroupchatRow : ConversationRow {

    public GroupchatRow(StreamInteractor stream_interactor, Conversation conversation) {
        base(stream_interactor, conversation);
        has_tooltip = true;
        set_tooltip_text(conversation.counterpart.bare_jid.to_string());
        update_avatar();

        x_button.clicked.connect(on_x_button_clicked);
        stream_interactor.get_module(MucManager.IDENTITY).left.connect(() => {
            Idle.add(() => {
                update_avatar();
                return false;
            });
        });
    }


    public override void on_show_received(Show show) {
        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
    }

    public override void network_connection(bool connected) {
        update_avatar();
    }

    private void on_x_button_clicked() {
        stream_interactor.get_module(MucManager.IDENTITY).part(conversation.account, conversation.counterpart);
    }

    private void update_avatar() {
        ConnectionManager.ConnectionState connection_state = stream_interactor.connection_manager.get_state(conversation.account);
        bool is_joined = stream_interactor.get_module(MucManager.IDENTITY).is_joined(conversation.counterpart, conversation.account);

        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .set_greyscale(connection_state != ConnectionManager.ConnectionState.CONNECTED || !is_joined)
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
    }
}

}