using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class NotificationEvents : StreamInteractionModule, Object {
    public static ModuleIdentity<NotificationEvents> IDENTITY = new ModuleIdentity<NotificationEvents>("notification_events");
    public string id { get { return IDENTITY.id; } }

    public signal void notify_content_item(ContentItem content_item, Conversation conversation);

    private StreamInteractor stream_interactor;
    private NotificationProvider? notifier;

    public static void start(StreamInteractor stream_interactor) {
        NotificationEvents m = new NotificationEvents(stream_interactor);
        stream_interactor.add_module(m);
    }

    public NotificationEvents(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(on_content_item_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);

        stream_interactor.get_module(MucManager.IDENTITY).invite_received.connect(on_invite_received);
        stream_interactor.get_module(MucManager.IDENTITY).voice_request_received.connect((account, room_jid, from_jid, nick) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            if (conversation == null) return;
            notifier.notify_voice_request.begin(conversation, from_jid);
        });

        stream_interactor.get_module(Calls.IDENTITY).call_incoming.connect(on_call_incoming);
        stream_interactor.connection_manager.connection_error.connect((account, error) => notifier.notify_connection_error.begin(account, error));
        stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect((conversation) => {
            notifier.retract_content_item_notifications.begin();
            notifier.retract_conversation_notifications.begin(conversation);
        });
    }

    public void register_notification_provider(NotificationProvider notification_provider) {
        if (notifier == null || notifier.get_priority() < notification_provider.get_priority()) {
            notifier = notification_provider;
        }
    }

    private void on_content_item_received(ContentItem item, Conversation conversation) {
        ContentItem last_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation);

        if (item.id != last_item.id) return;
        if (item.id == conversation.read_up_to_item) return;
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) return;

        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
        if (notify == Conversation.NotifySetting.OFF) return;

        string conversation_display_name = get_conversation_display_name(stream_interactor, conversation, null);
        string? participant_display_name = null;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            participant_display_name = get_participant_display_name(stream_interactor, conversation, item.jid);
        }

        switch (item.type_) {
            case MessageItem.TYPE:
                Message message = ((MessageItem) item).message;

                if (message.direction == Message.DIRECTION_SENT) return;

                if (notify == Conversation.NotifySetting.HIGHLIGHT) {
                    Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
                    if (nick == null) return;

                    bool highlight = Regex.match_simple("\\b" + Regex.escape_string(nick.resourcepart) + "\\b", message.body, RegexCompileFlags.CASELESS);
                    if (!highlight) return;
                }

                notify_content_item(item, conversation);
                if (notify != Conversation.NotifySetting.OFF) {
                    notifier.notify_message.begin(message, conversation, conversation_display_name, participant_display_name);
                }
                break;
            case FileItem.TYPE:
                FileTransfer file_transfer = ((FileItem) item).file_transfer;
                bool is_image = file_transfer.mime_type != null && file_transfer.mime_type.has_prefix("image");

                // Don't notify on file transfers in a groupchat set to "mention only"
                if (notify == Conversation.NotifySetting.HIGHLIGHT) return;
                if (file_transfer.direction == FileTransfer.DIRECTION_SENT) return;

                notify_content_item(item, conversation);
                if (notify != Conversation.NotifySetting.OFF) {
                    notifier.notify_file.begin(file_transfer, conversation, is_image, conversation_display_name, participant_display_name);
                }
                break;
            case CallItem.TYPE:
                // handled in `on_call_incoming`
                break;
        }
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus(conversation)) return;

        notifier.notify_subscription_request.begin(conversation);
    }

    private void on_call_incoming(Call call, Conversation conversation, bool video) {
        string conversation_display_name = get_conversation_display_name(stream_interactor, conversation, null);

        notifier.notify_call.begin(call, conversation, video, conversation_display_name);
        call.notify["state"].connect(() => {
            if (call.state != Call.State.RINGING) {
                notifier.retract_call_notification.begin(call, conversation);
            }
        });
    }

    private void on_invite_received(Account account, Jid room_jid, Jid from_jid, string? password, string? reason) {
        string inviter_display_name;
        if (room_jid.equals_bare(from_jid)) {
            Conversation conversation = new Conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            inviter_display_name = get_participant_display_name(stream_interactor, conversation, from_jid);
        } else {
            Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);
            inviter_display_name = get_participant_display_name(stream_interactor, direct_conversation, from_jid);
        }
        notifier.notify_muc_invite.begin(account, room_jid, from_jid, inviter_display_name);
    }
}

public interface NotificationProvider : Object {
    public abstract double get_priority();

    public abstract async void notify_message(Message message, Conversation conversation, string conversation_display_name, string? participant_display_name);
    public abstract async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name);
    public abstract async void notify_call(Call call, Conversation conversation, bool video, string conversation_display_name);
    public abstract async void retract_call_notification(Call call, Conversation conversation);
    public abstract async void notify_subscription_request(Conversation conversation);
    public abstract async void notify_connection_error(Account account, ConnectionManager.ConnectionError error);
    public abstract async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name);
    public abstract async void notify_voice_request(Conversation conversation, Jid from_jid);

    public abstract async void retract_content_item_notifications();
    public abstract async void retract_conversation_notifications(Conversation conversation);
}

}
