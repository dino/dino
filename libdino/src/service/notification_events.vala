using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class NotificationEvents : StreamInteractionModule, Object {
    public static ModuleIdentity<NotificationEvents> IDENTITY = new ModuleIdentity<NotificationEvents>("notification_events");
    public string id { get { return IDENTITY.id; } }

    public signal void notify_message(Message message, Conversation conversation);
    public signal void notify_subscription_request(Conversation conversation);

    private StreamInteractor stream_interactor;

    public static void start(StreamInteractor stream_interactor) {
        NotificationEvents m = new NotificationEvents(stream_interactor);
        stream_interactor.add_module(m);
    }

    public NotificationEvents(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (!should_notify_message(message, conversation)) return;
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) return;
        notify_message(message, conversation);
    }

    private bool should_notify_message(Entities.Message message, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
        if (notify == Conversation.NotifySetting.OFF) return false;
        Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (notify == Conversation.NotifySetting.HIGHLIGHT && nick != null) {
        return Regex.match_simple("""\b""" + Regex.escape_string(nick.resourcepart) + """\b""", message.body, RegexCompileFlags.CASELESS);
        }
        return true;
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus(conversation)) return;

        notify_subscription_request(conversation);
    }
}

}
