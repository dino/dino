using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class NotificationEvents : StreamInteractionModule, Object {
    public static ModuleIdentity<NotificationEvents> IDENTITY = new ModuleIdentity<NotificationEvents>("notification_events");
    public string id { get { return IDENTITY.id; } }

    public signal void notify_content_item(ContentItem content_item, Conversation conversation);
    public signal void notify_subscription_request(Conversation conversation);
    public signal void notify_connection_error(Account account, ConnectionManager.ConnectionError error);
    public signal void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string? password, string? reason);
    public signal void notify_voice_request(Account account, Jid room_jid, Jid from_jid, string? nick, string? role, string? label);

    private StreamInteractor stream_interactor;

    public static void start(StreamInteractor stream_interactor) {
        NotificationEvents m = new NotificationEvents(stream_interactor);
        stream_interactor.add_module(m);
    }

    public NotificationEvents(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(on_content_item_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
        stream_interactor.get_module(MucManager.IDENTITY).invite_received.connect((account, room_jid, from_jid, password, reason) => notify_muc_invite(account, room_jid, from_jid, password, reason));
        stream_interactor.get_module(MucManager.IDENTITY).voice_request_received.connect((account, room_jid, from_jid, nick, role, label) => notify_voice_request(account, room_jid, from_jid, nick, role, label));
        stream_interactor.connection_manager.connection_error.connect((account, error) => notify_connection_error(account, error));
    }

    private void on_content_item_received(ContentItem item, Conversation conversation) {
        ContentItem last_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation);

        if (item.id != last_item.id && last_item.id != conversation.read_up_to_item) return;

        if (!should_notify(item, conversation)) return;
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) return;
        notify_content_item(item, conversation);
    }

    private bool should_notify(ContentItem content_item, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);

        if (notify == Conversation.NotifySetting.OFF) return false;

        switch (content_item.type_) {
            case MessageItem.TYPE:
                Message message = (content_item as MessageItem).message;
                if (message.direction == Message.DIRECTION_SENT) return false;
                break;
            case FileItem.TYPE:
                FileTransfer file_transfer = (content_item as FileItem).file_transfer;
                // Don't notify on file transfers in a groupchat set to "mention only"
                if (notify == Conversation.NotifySetting.HIGHLIGHT) return false;
                if (file_transfer.direction == FileTransfer.DIRECTION_SENT) return false;
                break;
        }

        if (content_item.type_ == MessageItem.TYPE && notify == Conversation.NotifySetting.HIGHLIGHT) {
            Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
            if (nick == null) return false;

            Entities.Message message = (content_item as MessageItem).message;
            return Regex.match_simple("\\b" + Regex.escape_string(nick.resourcepart) + "\\b", message.body, RegexCompileFlags.CASELESS);
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
