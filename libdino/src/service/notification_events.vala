using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class NotificationEvents : StreamInteractionModule, Object {
    public static ModuleIdentity<NotificationEvents> IDENTITY = new ModuleIdentity<NotificationEvents>("notification_events");
    public string id { get { return IDENTITY.id; } }

    public signal void notify_message(Message message, Conversation conversation);
    public signal void notify_subscription_request(Conversation conversation);
    public signal void notify_connection_error(Account account, ConnectionManager.ConnectionError error);

    private StreamInteractor stream_interactor;

    private HashMap<Account, HashMap<Conversation, Entities.Message>> mam_potential_new = new HashMap<Account, HashMap<Conversation, Entities.Message>>(Account.hash_func, Account.equals_func);
    private Gee.List<Account> synced_accounts = new ArrayList<Account>(Account.equals_func);

    public static void start(StreamInteractor stream_interactor) {
        NotificationEvents m = new NotificationEvents(stream_interactor);
        stream_interactor.add_module(m);
    }

    public NotificationEvents(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
        stream_interactor.get_module(MessageProcessor.IDENTITY).history_synced.connect((account) => {
            synced_accounts.add(account);
            if (!mam_potential_new.has_key(account)) return;
            foreach (Conversation c in mam_potential_new[account].keys) {
                Entities.Message m = mam_potential_new[account][c];
                Entities.Message last_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(c);
                if (m.equals(last_message) && !c.read_up_to.equals(m)) {
                    on_message_received(m, c);
                }
            }
            mam_potential_new[account].clear();
        });
        stream_interactor.connection_manager.connection_error.connect((account, error) => notify_connection_error(account, error));
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (!synced_accounts.contains(conversation.account)) {
            if (!mam_potential_new.has_key(conversation.account)) {
                mam_potential_new[conversation.account] = new HashMap<Conversation, Entities.Message>(Conversation.hash_func, Conversation.equals_func);
            }
            mam_potential_new[conversation.account][conversation] = message;
        }
        if (!should_notify_message(message, conversation)) return;
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) return;
        notify_message(message, conversation);
    }

    private bool should_notify_message(Entities.Message message, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
        if (notify == Conversation.NotifySetting.OFF) return false;
        Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (notify == Conversation.NotifySetting.HIGHLIGHT && nick != null) {
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
