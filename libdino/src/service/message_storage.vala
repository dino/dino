using Xmpp;
using Gee;

using Dino.Entities;
using Dino.Qlite;

namespace Dino {

public class MessageStorage : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageStorage> IDENTITY = new ModuleIdentity<MessageStorage>("message_cache");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    private WeakMap<int, Message> messages_by_db_id = new WeakMap<int, Message>();
    private HashMap<Conversation, WeakMap<string, Message>> messages_by_stanza_id = new HashMap<Conversation, WeakMap<string, Message>>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Conversation, WeakMap<string, Message>> messages_by_server_id = new HashMap<Conversation, WeakMap<string, Message>>(Conversation.hash_func, Conversation.equals_func);

    // This is to keep the last 300 messages such that we don't have to recreate the newest ones all the time
    private LinkedList<Message> message_refs = new LinkedList<Message>();

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
        cache_message(message, conversation);
    }

    public Message? get_last_message(Conversation conversation) {
        Gee.List<Message> messages = get_messages(conversation, 1);

        if (messages.size > 0) {
            return messages[0];
        }

        return null;
    }

    public Message? get_last_message_by_sent_resource(Conversation conversation, string resource) {
        RowOption row = db.message.select({db.message.id})
                .with(db.message.account_id, "=", conversation.account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message.type_, "=", (int) Util.get_message_type_for_conversation(conversation))
                .with(db.message.our_resource, "=", resource)
                .with(db.message.direction, "=", Message.DIRECTION_SENT)
                .order_by(db.message.time, "DESC")
                .single().row();
        return get_message_by_id_row_opt(row, conversation);
    }

    public Gee.List<Message> get_messages(Conversation conversation, int count = 50, Message.Type? type = null, DateTime? before = null, DateTime? after = null, int id = 0) {
        QueryBuilder select = db.message.select();

        if (before != null) {
            if (id > 0) {
                select.where(@"time < ? OR (time = ? AND message.id < ?)", { before.to_unix().to_string(), before.to_unix().to_string(), id.to_string() });
            } else {
                select.with(db.message.id, "<", id);
            }
        }
        if (after != null) {
            if (id > 0) {
                select.where(@"time > ? OR (time = ? AND message.id > ?)", { after.to_unix().to_string(), after.to_unix().to_string(), id.to_string() });
            } else {
                select.with(db.message.time, ">", (long) after.to_unix());
            }
            if (id > 0) {
                select.with(db.message.id, ">", id);
            }
        } else {
            select.order_by(db.message.time, "DESC");
        }

        select.with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message.account_id, "=", conversation.account.id)
                .limit(count);
        if (conversation.counterpart.resourcepart != null) {
            select.with(db.message.counterpart_resource, "=", conversation.counterpart.resourcepart);
        }
        if (type != null) {
            select.with(db.message.type_, "=", (int) type);
        }

        select.outer_join_with(db.real_jid, db.real_jid.message_id, db.message.id);
        select.outer_join_with(db.message_correction, db.message_correction.message_id, db.message.id);
        select.outer_join_with(db.message_occupant_id, db.message_occupant_id.message_id, db.message.id);
        select.outer_join_with(db.reply, db.reply.message_id, db.message.id);

        LinkedList<Message> ret = new LinkedList<Message>();
        foreach (Row row in select) {
            try {
                Message? message = messages_by_db_id[row[db.message.id]];
                if (message == null) {
                    message = create_message_from_row(row, conversation);
                }
            } catch (InvalidJidError e) {
                warning("Ignoring message with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public Gee.List<MessageItem> get_messages_before_message(Conversation? conversation, DateTime before, int id, int count = 20) {
        Gee.List<Message> db_messages = get_messages(conversation, count, Util.get_message_type_for_conversation(conversation), before, null, id);
        Gee.List<MessageItem> ret = new ArrayList<MessageItem>();
        foreach (Message message in db_messages) {
            ret.add(new MessageItem(message, conversation, -1));
        }
        return ret;
    }

    public Gee.List<MessageItem> get_messages_after_message(Conversation? conversation, DateTime after, int id, int count = 20) {
        Gee.List<Message> db_messages = get_messages(conversation, count, Util.get_message_type_for_conversation(conversation), null, after, id);
        Gee.List<MessageItem> ret = new ArrayList<MessageItem>();
        foreach (Message message in db_messages) {
            ret.add(new MessageItem(message, conversation, -1));
        }
        return ret;
    }

    private Message? get_message_by_id_row_opt(RowOption row_option, Conversation conversation) {
        if (!row_option.is_present()) return null;
        return get_message_by_id(row_option[db.message.id], conversation);
    }

    public Message? get_message_by_id(int id, Conversation conversation) {
        Message? message = messages_by_db_id[id];
        if (message != null) {
            return message;
        }

        RowOption row_option = db.message.select().with(db.message.id, "=", id)
                .outer_join_with(db.real_jid, db.real_jid.message_id, db.message.id)
                .outer_join_with(db.message_occupant_id, db.message_occupant_id.message_id, db.message.id)
                .outer_join_with(db.message_correction, db.message_correction.message_id, db.message.id)
                .outer_join_with(db.reply, db.reply.message_id, db.message.id)
                .single()
                .row();

        return create_message_from_row_opt(row_option, conversation);
    }

    public Message? get_message_by_referencing_id(string id, Conversation conversation) {
        if (conversation.type_ == Conversation.Type.CHAT) {
            return get_message_by_stanza_id(id, conversation);
        } else {
            return get_message_by_server_id(id, conversation);
        }
    }

    public Message? get_message_by_stanza_id(string stanza_id, Conversation conversation) {
        if (messages_by_stanza_id.has_key(conversation)) {
            Message? message = messages_by_stanza_id[conversation][stanza_id];
            if (message != null) {
                return message;
            }
        }

        var query = db.message.select({db.message.id})
                .with(db.message.account_id, "=", conversation.account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message.type_, "=", (int) Util.get_message_type_for_conversation(conversation))
                .with(db.message.stanza_id, "=", stanza_id)
                .order_by(db.message.time, "DESC");

        if (conversation.counterpart.resourcepart != null) {
            query.with(db.message.counterpart_resource, "=", conversation.counterpart.resourcepart);
        }

        RowOption row_option = query.single().row();

        return get_message_by_id_row_opt(row_option, conversation);
    }

    public Message? get_message_by_server_id(string server_id, Conversation conversation) {
        if (messages_by_server_id.has_key(conversation)) {
            Message? message = messages_by_server_id[conversation][server_id];
            if (message != null) {
                return message;
            }
        }

        var query = db.message.select({db.message.id})
                .with(db.message.account_id, "=", conversation.account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message.type_, "=", (int) Util.get_message_type_for_conversation(conversation))
                .with(db.message.server_id, "=", server_id)
                .order_by(db.message.time, "DESC");

        if (conversation.counterpart.resourcepart != null) {
            query.with(db.message.counterpart_resource, "=", conversation.counterpart.resourcepart);
        }

        RowOption row_option = query.single().row();

        return get_message_by_id_row_opt(row_option, conversation);
    }

    private Message? create_message_from_row_opt(RowOption row_option, Conversation conversation) {
        if (!row_option.is_present()) return null;
        return create_message_from_row(row_option.inner, conversation);
    }

    private Message? create_message_from_row(Row row, Conversation conversation) {
        try {
            Message message = new Message.from_row(db, row);
            cache_message(message, conversation);
            return message;
        } catch (InvalidJidError e) {
            warning("Got message with invalid Jid: %s", e.message);
        }
        return null;
    }

    private void cache_message(Message message, Conversation conversation) {
        messages_by_db_id[message.id] = message;

        if (message.stanza_id != null) {
            if (!messages_by_stanza_id.has_key(conversation)) {
                messages_by_stanza_id[conversation] = new WeakMap<string, Message>();
            }
            messages_by_stanza_id[conversation][message.stanza_id] = message;
        }

        if (message.server_id != null) {
            if (!messages_by_server_id.has_key(conversation)) {
                messages_by_server_id[conversation] = new WeakMap<string, Message>();
            }
            messages_by_server_id[conversation][message.server_id] = message;
        }

        message_refs.insert(0, message);
        if (message_refs.size > 300) {
            message_refs.remove_at(message_refs.size - 1);
        }
    }

    public string? get_reference_id(Message message, Conversation conversation) {
        if (message.edit_to != null) {
            // This is a message edit, so the reference id should be the one of the original message
            if (message.type_ == Message.Type.CHAT) {
                return message.edit_to;
            } else {
                if (message.edit_to_id != 0) {
                    Message original_message = get_message_by_id(message.edit_to_id, conversation);
                    return original_message.server_id;
                } else {
                    // We don't know the original message, so taking the server id of the correction is the best we can do
                    return message.server_id;
                }
            }
        }

        if (message.type_ == Message.Type.CHAT) {
            return message.stanza_id;
        } else {
            return message.server_id;
        }
    }
}

}
