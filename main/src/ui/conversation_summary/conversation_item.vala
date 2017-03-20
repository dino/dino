using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public enum MessageKind {
    TEXT,
    ME_COMMAND
}

public MessageKind get_message_kind(Message message) {
    if (message.body.has_prefix("/me ")) {
        return MessageKind.ME_COMMAND;
    } else {
        return MessageKind.TEXT;
    }
}

public interface ConversationItem : Gtk.Widget {
    public abstract bool merge(Entities.Message message);

    public static ConversationItem create_for_message(StreamInteractor stream_interactor, Conversation conversation, Message message) {
        switch (get_message_kind(message)) {
            case MessageKind.TEXT:
                return new MergedMessageItem(stream_interactor, conversation, message);
            case MessageKind.ME_COMMAND:
                return new SlashMeItem(stream_interactor, conversation, message);
        }
        assert_not_reached();
    }
}

}