using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class ConversationManager : StreamInteractionModule, Object {
    public static ModuleIdentity<ConversationManager> IDENTITY = new ModuleIdentity<ConversationManager>("conversation_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void conversation_activated(Conversation conversation);
    public signal void conversation_deactivated(Conversation conversation);

    private StreamInteractor stream_interactor;
    private Database db;

    private HashMap<Account, HashMap<Jid, Conversation>> conversations = new HashMap<Account, HashMap<Jid, Conversation>>(Account.hash_func, Account.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        ConversationManager m = new ConversationManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private ConversationManager(StreamInteractor stream_interactor, Database db) {
        this.db = db;
        this.stream_interactor = stream_interactor;
        stream_interactor.add_module(this);
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MucManager.IDENTITY).groupchat_joined.connect(on_groupchat_joined);
        stream_interactor.get_module(MessageManager.IDENTITY).pre_message_received.connect(on_message_received);
        stream_interactor.get_module(MessageManager.IDENTITY).message_sent.connect(on_message_sent);
    }

    public Conversation create_conversation(Jid jid, Account account, Conversation.Type type) {
        assert(conversations.has_key(account));
        if (conversations[account].has_key(jid)) {
            return conversations[account][jid];
        } else {
            Conversation conversation = new Conversation(jid, account, type);
            add_conversation(conversation);
            conversation.persist(db);
            return conversation;
        }
    }

    public Conversation? get_conversation(Jid jid, Account account) {
        if (conversations.has_key(account)) {
            return conversations[account][jid];
        }
        return null;
    }

    public Gee.List<Conversation> get_active_conversations() {
        ArrayList<Conversation> ret = new ArrayList<Conversation>(Conversation.equals_func);
        foreach (Account account in conversations.keys) {
            foreach (Conversation conversation in conversations[account].values) {
                if(conversation.active) ret.add(conversation);
            }
        }
        return ret;
    }

    public void start_conversation(Conversation conversation, bool push_front = false) {
        if (push_front) {
            conversation.last_active = new DateTime.now_local();
            if (conversation.active) conversation_activated(conversation);
        }
        if (!conversation.active) {
            conversation.active = true;
            conversation_activated(conversation);
        }
    }

    public void close_conversation(Conversation conversation) {
        conversation.active = false;
        conversation_deactivated(conversation);
    }

    private void on_account_added(Account account) {
        conversations[account] = new HashMap<Jid, Conversation>(Jid.hash_bare_func, Jid.equals_bare_func);
        foreach (Conversation conversation in db.get_conversations(account)) {
            add_conversation(conversation);
        }
    }

    private void on_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
        conversation.last_active = message.time;
        start_conversation(conversation);
    }

    private void on_message_sent(Entities.Message message, Conversation conversation) {
        conversation.last_active = message.time;
    }

    private void on_groupchat_joined(Account account, Jid jid, string nick) {
        Conversation conversation = create_conversation(jid, account, Conversation.Type.GROUPCHAT);
        start_conversation(conversation);
    }

    private void add_conversation(Conversation conversation) {
        conversations[conversation.account][conversation.counterpart] = conversation;
        if (conversation.active) {
            conversation_activated(conversation);
        }
    }
}

}