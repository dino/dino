using Gee;
using Qlite;

using Dino.Entities;

namespace Dino {

public class MessageStorage : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageStorage> IDENTITY = new ModuleIdentity<MessageStorage>("message_cache");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    private HashMap<Conversation, Gee.TreeSet<Message>> messages = new HashMap<Conversation, Gee.TreeSet<Message>>(Conversation.hash_func, Conversation.equals_func);

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
        Gee.List<Message> ret = new ArrayList<Message>(Message.equals_func);
        BidirIterator<Message> iter = messages[conversation].bidir_iterator();
        iter.last();
        if (messages[conversation].size > 0) {
            do {
                ret.insert(0, iter.get());
                iter.previous();
            } while (iter.has_previous() && ret.size < count);
        }
        return ret;
    }

    public Message? get_last_message(Conversation conversation) {
        init_conversation(conversation);
        if (messages[conversation].size > 0) {
            return messages[conversation].last();
        }
        return null;
    }

    public Gee.List<MessageItem> get_messages_before_message(Conversation? conversation, DateTime before, int id, int count = 20) {
//        SortedSet<Message>? before = messages[conversation].head_set(message);
//        if (before != null && before.size >= count) {
//            Gee.List<Message> ret = new ArrayList<Message>(Message.equals_func);
//            Iterator<Message> iter = before.iterator();
//            iter.next();
//            for (int from_index = before.size - count; iter.has_next() && from_index > 0; from_index--) iter.next();
//            while(iter.has_next()) {
//                Message m = iter.get();
//                ret.add(m);
//                iter.next();
//            }
//            return ret;
//        } else {
        Gee.List<Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, Util.get_message_type_for_conversation(conversation), count, before, null, id);
        Gee.List<MessageItem> ret = new ArrayList<MessageItem>();
        foreach (Message message in db_messages) {
            ret.add(new MessageItem(message, conversation, -1));
        }
        return ret;
//        }
    }

    public Gee.List<MessageItem> get_messages_after_message(Conversation? conversation, DateTime after, int id, int count = 20) {
        Gee.List<Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, Util.get_message_type_for_conversation(conversation), count, null, after, id);
        Gee.List<MessageItem> ret = new ArrayList<MessageItem>();
        foreach (Message message in db_messages) {
            ret.add(new MessageItem(message, conversation, -1));
        }
        return ret;
    }

    public Message? get_message_by_id(int id, Conversation conversation) {
        init_conversation(conversation);
        foreach (Message message in messages[conversation]) {
            if (message.id == id) return message;
        }
        return null;
    }

    public Message? get_message_by_stanza_id(string stanza_id, Conversation conversation) {
        init_conversation(conversation);
        foreach (Message message in messages[conversation]) {
            if (message.stanza_id == stanza_id) return message;
        }
        return null;
    }

    public Message? get_message_by_server_id(string server_id, Conversation conversation) {
        init_conversation(conversation);
        foreach (Message message in messages[conversation]) {
            if (message.server_id == server_id) return message;
        }
        return null;
    }

    private void init_conversation(Conversation conversation) {
        if (!messages.has_key(conversation)) {
            messages[conversation] = new Gee.TreeSet<Message>((a, b) => {
                int res = a.local_time.compare(b.local_time);
                if (res == 0) {
                    res = a.time.compare(b.time);
                }
                if (res == 0) {
                    res = a.id - b.id > 0 ? 1 : -1;
                }
                return res;
            });
            Gee.List<Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, Util.get_message_type_for_conversation(conversation), 50, null, null, -1);
            messages[conversation].add_all(db_messages);
        }
    }
}

}
