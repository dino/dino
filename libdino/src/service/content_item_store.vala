using Gee;

using Dino.Entities;
using Qlite;
using Xmpp;

namespace Dino {

public class ContentItemStore : StreamInteractionModule, Object {
    public static ModuleIdentity<ContentItemStore> IDENTITY = new ModuleIdentity<ContentItemStore>("content_item_store");
    public string id { get { return IDENTITY.id; } }

    public signal void new_item(ContentItem item, Conversation conversation);

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Conversation, ContentItemCollection> collection_conversations = new HashMap<Conversation, ContentItemCollection>(Conversation.hash_func, Conversation.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        ContentItemStore m = new ContentItemStore(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public ContentItemStore(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(FileManager.IDENTITY).received_file.connect(insert_file_transfer);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(announce_message);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(announce_message);
        stream_interactor.get_module(Calls.IDENTITY).call_incoming.connect(insert_call);
        stream_interactor.get_module(Calls.IDENTITY).call_outgoing.connect(insert_call);
    }

    public void init(Conversation conversation, ContentItemCollection item_collection) {
        collection_conversations[conversation] = item_collection;
    }

    public void uninit(Conversation conversation, ContentItemCollection item_collection) {
        collection_conversations.unset(conversation);
    }

    public Gee.List<ContentItem> get_items_from_query(QueryBuilder select, Conversation conversation) {
        Gee.TreeSet<ContentItem> items = new Gee.TreeSet<ContentItem>(ContentItem.compare_func);

        foreach (var row in select) {
            int provider = row[db.content_item.content_type];
            int foreign_id = row[db.content_item.foreign_id];
            DateTime time = new DateTime.from_unix_utc(row[db.content_item.time]);
            switch (provider) {
                case 1:
                    Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(foreign_id, conversation);
                    if (message != null) {
                        var message_item = new MessageItem(message, conversation, row[db.content_item.id]);
                        message_item.time = time; // In case of message corrections, the original time should be used
                        items.add(message_item);
                    }
                    break;
                case 2:
                    FileTransfer? file_transfer = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_file_by_id(foreign_id, conversation);
                    if (file_transfer != null) {
                        Message? message = null;
                        if (file_transfer.provider == 0 && file_transfer.info != null) {
                            message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(int.parse(file_transfer.info), conversation);
                        }
                        var file_item = new FileItem(file_transfer, conversation, row[db.content_item.id], message);
                        items.add(file_item);
                    }
                    break;
                case 3:
                    Call? call = stream_interactor.get_module(CallStore.IDENTITY).get_call_by_id(foreign_id, conversation);
                    if (call != null) {
                        var call_item = new CallItem(call, conversation, row[db.content_item.id]);
                        items.add(call_item);
                    }
                    break;
            }
        }

        Gee.List<ContentItem> ret = new ArrayList<ContentItem>();
        foreach (ContentItem item in items) {
            ret.add(item);
        }
        return ret;
    }

    public ContentItem? get_item(Conversation conversation, int type, int foreign_id) {
        QueryBuilder select = db.content_item.select()
            .with(db.content_item.content_type, "=", type)
            .with(db.content_item.foreign_id, "=", foreign_id);

        Gee.List<ContentItem> item = get_items_from_query(select, conversation);

        return item.size > 0 ? item[0] : null;
    }

    public ContentItem? get_item_by_id(Conversation conversation, int id) {
        QueryBuilder select = db.content_item.select()
                .with(db.content_item.id, "=", id);

        Gee.List<ContentItem> item = get_items_from_query(select, conversation);

        return item.size > 0 ? item[0] : null;
    }

    public ContentItem? get_latest(Conversation conversation) {
        Gee.List<ContentItem> items = get_n_latest(conversation, 1);
        if (items.size > 0) {
            return items.get(0);
        }
        return null;
    }

    public Gee.List<ContentItem> get_n_latest(Conversation conversation, int count) {
        QueryBuilder select = db.content_item.select()
            .with(db.content_item.conversation_id, "=", conversation.id)
            .with(db.content_item.hide, "=", false)
            .order_by(db.content_item.time, "DESC")
            .order_by(db.content_item.id, "DESC")
            .limit(count);

        return get_items_from_query(select, conversation);
    }

    public Gee.List<ContentItem> get_before(Conversation conversation, ContentItem item, int count) {
        long time = (long) item.time.to_unix();
        QueryBuilder select = db.content_item.select()
            .where(@"time < ? OR (time = ? AND id < ?)", { time.to_string(), time.to_string(), item.id.to_string() })
            .with(db.content_item.conversation_id, "=", conversation.id)
            .with(db.content_item.hide, "=", false)
            .order_by(db.content_item.time, "DESC")
            .order_by(db.content_item.id, "DESC")
            .limit(count);

        return get_items_from_query(select, conversation);
    }

    public Gee.List<ContentItem> get_after(Conversation conversation, ContentItem item, int count) {
        long time = (long) item.time.to_unix();
        QueryBuilder select = db.content_item.select()
            .where(@"time > ? OR (time = ? AND id > ?)", { time.to_string(), time.to_string(), item.id.to_string() })
            .with(db.content_item.conversation_id, "=", conversation.id)
            .with(db.content_item.hide, "=", false)
            .order_by(db.content_item.time, "ASC")
            .order_by(db.content_item.id, "ASC")
            .limit(count);

        return get_items_from_query(select, conversation);
    }

    public void insert_message(Message message, Conversation conversation, bool hide = false) {
        MessageItem item = new MessageItem(message, conversation, -1);
        item.id = db.add_content_item(conversation, message.time, message.local_time, 1, message.id, hide);
    }

    private void announce_message(Message message, Conversation conversation) {
        QueryBuilder select = db.content_item.select();
        select.with(db.content_item.foreign_id, "=", message.id);
        select.with(db.content_item.content_type, "=", 1);
        select.with(db.content_item.hide, "=", false);
        foreach (Row row in select) {
            MessageItem item = new MessageItem(message, conversation, row[db.content_item.id]);
            if (collection_conversations.has_key(conversation)) {
                collection_conversations.get(conversation).insert_item(item);
            }
            new_item(item, conversation);
            break;
        }
    }

    private void insert_file_transfer(FileTransfer file_transfer, Conversation conversation) {
        FileItem item = new FileItem(file_transfer, conversation, -1);
        item.id = db.add_content_item(conversation, file_transfer.time, file_transfer.local_time, 2, file_transfer.id, false);
        if (collection_conversations.has_key(conversation)) {
            collection_conversations.get(conversation).insert_item(item);
        }
        new_item(item, conversation);
    }

    private void insert_call(Call call, CallState call_state, Conversation conversation) {
        CallItem item = new CallItem(call, conversation, -1);
        item.id = db.add_content_item(conversation, call.time, call.local_time, 3, call.id, false);
        if (collection_conversations.has_key(conversation)) {
            collection_conversations.get(conversation).insert_item(item);
        }
        new_item(item, conversation);
    }

    public bool get_item_hide(ContentItem content_item) {
        return db.content_item.row_with(db.content_item.id, content_item.id)[db.content_item.hide, false];
    }

    public void set_item_hide(ContentItem content_item, bool hide) {
        db.content_item.update()
            .with(db.content_item.id, "=", content_item.id)
            .set(db.content_item.hide, hide)
            .perform();
    }
}

public interface ContentItemCollection : Object {
    public abstract void insert_item(ContentItem item);
    public abstract void remove_item(ContentItem item);
}

public abstract class ContentItem : Object {
    public int id { get; set; }
    public string type_ { get; set; }
    public Jid jid { get; set; }
    public DateTime time { get; set; }
    public Encryption encryption { get; set; }
    public Entities.Message.Marked mark { get; set; }

    ContentItem(int id, string ty, Jid jid, DateTime time, Encryption encryption, Entities.Message.Marked mark) {
        this.id = id;
        this.type_ = ty;
        this.jid = jid;
        this.time = time;
        this.encryption = encryption;
        this.mark = mark;
    }

    public int compare(ContentItem c) {
        return compare_func(this, c);
    }

    public static int compare_func(ContentItem a, ContentItem b) {
        int res = a.time.compare(b.time);
        if (res == 0) {
            res = a.id - b.id > 0 ? 1 : -1;
        }
        return res;
    }
}

public class MessageItem : ContentItem {
    public const string TYPE = "message";

    public Message message;
    public Conversation conversation;

    public MessageItem(Message message, Conversation conversation, int id) {
        base(id, TYPE, message.from, message.time, message.encryption, message.marked);

        this.message = message;
        this.conversation = conversation;
        message.bind_property("marked", this, "mark");
    }
}

public class FileItem : ContentItem {
    public const string TYPE = "file";

    public FileTransfer file_transfer;
    public Conversation conversation;

    public FileItem(FileTransfer file_transfer, Conversation conversation, int id, Message? message = null) {
        Entities.Message.Marked mark = Entities.Message.Marked.NONE;
        if (message != null) {
            mark = message.marked;
        } else if (file_transfer.direction == FileTransfer.DIRECTION_SENT) {
            mark = file_to_message_state(file_transfer.state);
        }
        base(id, TYPE, file_transfer.from, file_transfer.time, file_transfer.encryption, mark);

        this.file_transfer = file_transfer;
        this.conversation = conversation;

        // TODO those don't work
        if (message != null) {
            message.bind_property("marked", this, "mark");
        } else if (file_transfer.direction == FileTransfer.DIRECTION_SENT) {
            file_transfer.bind_property("state", this, "mark", BindingFlags.DEFAULT, (_, from_value, ref to_value) => {
                to_value = file_to_message_state((FileTransfer.State)from_value.get_enum());
                return true;
            });
        }
    }

    private static Entities.Message.Marked file_to_message_state(FileTransfer.State state) {
        switch (state) {
            case FileTransfer.State.IN_PROGRESS:
                return Entities.Message.Marked.UNSENT;
            case FileTransfer.State.COMPLETE:
                return Entities.Message.Marked.NONE;
            case FileTransfer.State.NOT_STARTED:
                return Entities.Message.Marked.UNSENT;
            case FileTransfer.State.FAILED:
                return Entities.Message.Marked.WONTSEND;
        }
        assert_not_reached();
    }
}

public class CallItem : ContentItem {
    public const string TYPE = "call";

    public Call call;
    public Conversation conversation;

    public CallItem(Call call, Conversation conversation, int id) {
        base(id, TYPE, call.proposer, call.time, call.encryption, Message.Marked.NONE);

        this.call = call;
        this.conversation = conversation;

        call.bind_property("encryption", this, "encryption");
    }
}

}
