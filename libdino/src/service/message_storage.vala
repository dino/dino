using Gee;

using Dino.Entities;

namespace Dino {

public class MessageStorage : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageStorage> IDENTITY = new ModuleIdentity<MessageStorage>("message_cache");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    private HashMap<Conversation, Gee.List<Message>> messages = new HashMap<Conversation, Gee.List<Entities.Message>>(Conversation.hash_func, Conversation.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageStorage m = new MessageStorage(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private MessageStorage(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
    }

    public void add_message(Message message, Conversation conversation) {
        message.persist(db);
        init_conversation(conversation);
        messages[conversation].add(message);
    }

    public Gee.List<Message> get_messages(Conversation conversation, int count = 50) {
        init_conversation(conversation);
        if (messages[conversation].size > 0) {
            return messages[conversation][int.max(messages[conversation].size - count - 1, 0) : messages[conversation].size];
        }
        return new ArrayList<Message>();
    }

    public Message? get_last_message(Conversation conversation) {
        init_conversation(conversation);
        if (messages[conversation].size > 0) {
            return messages[conversation][messages[conversation].size - 1];
        }
        return null;
    }

    public Gee.List<Message>? get_messages_before(Conversation? conversation, Message before, int count = 20) {
        Gee.List<Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, Util.get_message_type_for_conversation(conversation), count, before);
        return db_messages;
    }

    public Message? get_message_by_id(string stanza_id, Conversation conversation) {
        init_conversation(conversation);
        for (int i = messages[conversation].size - 1; i > 0; i--) {
            if (messages[conversation][i].stanza_id == stanza_id) return messages[conversation][i];
        }
        return null;
    }

    private void init_conversation(Conversation conversation) {
        if (!messages.has_key(conversation)) {
            messages[conversation] = db.get_messages(conversation.counterpart, conversation.account, Util.get_message_type_for_conversation(conversation), 50, null);
        }
    }
}

}