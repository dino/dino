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

    private StreamInteractor stream_interactor;

    private HashMap<Account, HashMap<Conversation, ContentItem>> mam_potential_new = new HashMap<Account, HashMap<Conversation, ContentItem>>(Account.hash_func, Account.equals_func);
    private Gee.List<Account> synced_accounts = new ArrayList<Account>(Account.equals_func);

    public static void start(StreamInteractor stream_interactor) {
        NotificationEvents m = new NotificationEvents(stream_interactor);
        stream_interactor.add_module(m);
    }

    public NotificationEvents(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(on_content_item_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
        stream_interactor.get_module(MucManager.IDENTITY).invite_received.connect((account, room_jid, from_jid, password, reason) => notify_muc_invite(account, room_jid, from_jid, password, reason));
        stream_interactor.connection_manager.connection_error.connect((account, error) => notify_connection_error(account, error));
        stream_interactor.get_module(MessageProcessor.IDENTITY).history_synced.connect((account) => {
            synced_accounts.add(account);
            if (!mam_potential_new.has_key(account)) return;
            foreach (Conversation c in mam_potential_new[account].keys) {
                ContentItem last_mam_item = mam_potential_new[account][c];
                ContentItem last_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(c);
                if (last_mam_item == last_item /* && !c.read_up_to.equals(m) */) {
                    on_content_item_received(last_mam_item, c);
                }
            }
            mam_potential_new[account].clear();
        });
    }

    private void on_content_item_received(ContentItem item, Conversation conversation) {

        // Don't wait for MAM sync on servers without MAM
        bool mam_available = true;
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream != null) {
            mam_available = stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) != null;
        }

        if (mam_available && !synced_accounts.contains(conversation.account)) {
            if (!mam_potential_new.has_key(conversation.account)) {
                mam_potential_new[conversation.account] = new HashMap<Conversation, ContentItem>(Conversation.hash_func, Conversation.equals_func);
            }
            mam_potential_new[conversation.account][conversation] = item;
            return;
        }
        if (!should_notify(item, conversation)) return;
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) return;
        notify_content_item(item, conversation);
    }

    private bool should_notify(ContentItem content_item, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
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
        if (notify == Conversation.NotifySetting.OFF) return false;
        Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (content_item.type_ == MessageItem.TYPE) {
            Entities.Message message = (content_item as MessageItem).message;
            if (notify == Conversation.NotifySetting.HIGHLIGHT && nick != null) {
                return Regex.match_simple("\\b" + Regex.escape_string(nick.resourcepart) + "\\b", message.body, RegexCompileFlags.CASELESS);
            }
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
