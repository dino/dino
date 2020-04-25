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

    private HashMap<Account, HashMap<Jid, Gee.List<Conversation>>> conversations = new HashMap<Account, HashMap<Jid, Gee.List<Conversation>>>(Account.hash_func, Account.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        ConversationManager m = new ConversationManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private ConversationManager(StreamInteractor stream_interactor, Database db) {
        this.db = db;
        this.stream_interactor = stream_interactor;
        stream_interactor.add_module(this);
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.account_removed.connect(on_account_removed);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new MessageListener(stream_interactor));
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(handle_sent_message);
    }

    public Conversation create_conversation(Jid jid, Account account, Conversation.Type? type = null) {
        assert(conversations.has_key(account));
        Jid store_jid = type == Conversation.Type.GROUPCHAT ? jid.bare_jid : jid;

        // Do we already have a conversation for this jid?
        if (conversations[account].has_key(store_jid)) {
            foreach (var conversation in conversations[account][store_jid]) {
                if (conversation.type_ == type) {
                    return conversation;
                }
            }
        }

        // Create a new converation
        Conversation conversation = new Conversation(jid, account, type);
        add_conversation(conversation);
        conversation.persist(db);
        return conversation;
    }

    public Conversation? get_conversation_for_message(Entities.Message message) {
        if (message.type_ == Entities.Message.Type.CHAT) {
            return create_conversation(message.counterpart.bare_jid, message.account, Conversation.Type.CHAT);
        } else if (message.type_ == Entities.Message.Type.GROUPCHAT) {
            return create_conversation(message.counterpart.bare_jid, message.account, Conversation.Type.GROUPCHAT);
        } else if (message.type_ == Entities.Message.Type.GROUPCHAT_PM) {
            return create_conversation(message.counterpart, message.account, Conversation.Type.GROUPCHAT_PM);
        }
        return null;
    }

    public Gee.List<Conversation> get_conversations(Jid jid, Account account) {
        Gee.List<Conversation> ret = new ArrayList<Conversation>(Conversation.equals_func);
        Conversation? bare_conversation = get_conversation(jid, account);
        if (bare_conversation != null) ret.add(bare_conversation);
        Conversation? full_conversation = get_conversation(jid.bare_jid, account);
        if (full_conversation != null) ret.add(full_conversation);
        return ret;
    }

    public Conversation? get_conversation(Jid jid, Account account, Conversation.Type? type = null) {
        if (conversations.has_key(account)) {
            if (conversations[account].has_key(jid)) {
                foreach (var conversation in conversations[account][jid]) {
                    if (type == null || conversation.type_ == type) {
                        return conversation;
                    }
                }
            }
        }
        return null;
    }

    public Conversation? get_conversation_by_id(int id) {
        foreach (HashMap<Jid, Gee.List<Conversation>> hm in conversations.values) {
            foreach (Gee.List<Conversation> hm2 in hm.values) {
                foreach (Conversation conversation in hm2) {
                    if (conversation.id == id) {
                        return conversation;
                    }
                }
            }
        }
        return null;
    }

    public Gee.List<Conversation> get_active_conversations(Account? account = null) {
        Gee.List<Conversation> ret = new ArrayList<Conversation>(Conversation.equals_func);
        foreach (Account account_ in conversations.keys) {
            if (account != null && !account_.equals(account)) continue;
            foreach (Gee.List<Conversation> list in conversations[account_].values) {
                foreach (var conversation in list) {
                    if(conversation.active) ret.add(conversation);
                }
            }
        }
        return ret;
    }

    public void start_conversation(Conversation conversation) {
        if (conversation.last_active == null) {
            conversation.last_active = new DateTime.now_utc();
            if (conversation.active) conversation_activated(conversation);
        }
        if (!conversation.active) {
            conversation.active = true;
            conversation_activated(conversation);
        }
    }

    public void close_conversation(Conversation conversation) {
        if (!conversation.active) return;

        conversation.active = false;
        conversation_deactivated(conversation);
    }

    private void on_account_added(Account account) {
        conversations[account] = new HashMap<Jid, ArrayList<Conversation>>(Jid.hash_func, Jid.equals_func);
        foreach (Conversation conversation in db.get_conversations(account)) {
            add_conversation(conversation);
        }
    }

    private void on_account_removed(Account account) {
        foreach (Gee.List<Conversation> list in conversations[account].values) {
            foreach (var conversation in list) {
                if(conversation.active) conversation_deactivated(conversation);
            }
        }
        conversations.unset(account);
    }

    private class MessageListener : Dino.MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "FILTER_EMPTY" };
        public override string action_group { get { return "MANAGER"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public MessageListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            conversation.last_active = message.time;

            if (stanza != null) {
                bool is_mam_message = Xep.MessageArchiveManagement.MessageFlag.get_flag(stanza) != null;
                bool is_recent = message.local_time.compare(new DateTime.now_utc().add_days(-3)) > 0;
                if (is_mam_message && !is_recent) return false;
            }
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation);
            return false;
        }
    }

    private void handle_sent_message(Entities.Message message, Conversation conversation) {
        conversation.last_active = message.time;

        bool is_recent = message.local_time.compare(new DateTime.now_utc().add_hours(-24)) > 0;
        if (is_recent) {
            start_conversation(conversation);
        }
    }

    private void add_conversation(Conversation conversation) {
        if (!conversations[conversation.account].has_key(conversation.counterpart)) {
            conversations[conversation.account][conversation.counterpart] = new ArrayList<Conversation>(Conversation.equals_func);
        }

        conversations[conversation.account][conversation.counterpart].add(conversation);

        if (conversation.active) {
            conversation_activated(conversation);
        }
    }
}

}
