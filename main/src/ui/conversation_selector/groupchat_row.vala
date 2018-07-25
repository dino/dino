using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class GroupchatRow : ConversationRow {

    public GroupchatRow(StreamInteractor stream_interactor, Conversation conversation) {
        base(stream_interactor, conversation);
        has_tooltip = true;
        set_tooltip_text(conversation.counterpart.bare_jid.to_string());

        closed.connect(() => {
            stream_interactor.get_module(MucManager.IDENTITY).part(conversation.account, conversation.counterpart);
        });

        stream_interactor.get_module(MucManager.IDENTITY).subject_set.connect((account, jid, subject) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_name_label(subject);
            }
        });
    }

    protected override void update_message_label() {
        base.update_message_label();
        if (last_message != null) {
            nick_label.visible = true;
            nick_label.label = Util.get_message_display_name(stream_interactor, last_message, conversation.account) + ": ";
        }
    }
}

}
