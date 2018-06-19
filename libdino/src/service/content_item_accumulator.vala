using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class ContentItemAccumulator : StreamInteractionModule, Object {
    public static ModuleIdentity<ContentItemAccumulator> IDENTITY = new ModuleIdentity<ContentItemAccumulator>("content_item_accumulator");
    public string id { get { return IDENTITY.id; } }

    public signal void new_item();

    private StreamInteractor stream_interactor;
    private Gee.List<ContentFilter> filters = new ArrayList<ContentFilter>();
    private HashMap<ContentItemCollection, Conversation> collection_conversations = new HashMap<ContentItemCollection, Conversation>();

    public static void start(StreamInteractor stream_interactor) {
        ContentItemAccumulator m = new ContentItemAccumulator(stream_interactor);
        stream_interactor.add_module(m);
    }

    public ContentItemAccumulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_new_message);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(on_new_message);
        stream_interactor.get_module(FileManager.IDENTITY).received_file.connect(insert_file_transfer);
    }

    public void init(Conversation conversation, ContentItemCollection item_collection) {
        collection_conversations[item_collection] = conversation;
    }

    public Gee.List<ContentItem> populate_latest(ContentItemCollection item_collection, Conversation conversation, int n) {
        Gee.TreeSet<ContentItem> items = new Gee.TreeSet<ContentItem>(ContentItem.compare);

        Gee.List<Entities.Message>? messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation, n);
        if (messages != null) {
            foreach (Entities.Message message in messages) {
                items.add(new MessageItem(message, conversation));
            }
        }
        Gee.List<FileTransfer> transfers = stream_interactor.get_module(FileManager.IDENTITY).get_latest_transfers(conversation.account, conversation.counterpart, n);
        foreach (FileTransfer transfer in transfers) {
            items.add(new FileItem(transfer));
        }

        BidirIterator<ContentItem> iter = items.bidir_iterator();
        iter.last();
        int i = 0;
        while (i < n && iter.has_previous()) {
            iter.previous();
            i++;
        }
        Gee.List<ContentItem> ret = new ArrayList<ContentItem>();
        do {
            ret.add(iter.get());
        } while(iter.next());
        return ret;
    }

    public Gee.List<ContentItem> populate_before(ContentItemCollection item_collection, Conversation conversation, ContentItem item, int n) {
        Gee.TreeSet<ContentItem> items = new Gee.TreeSet<ContentItem>(ContentItem.compare);

        Gee.List<Entities.Message>? messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_before_message(conversation, item.display_time, n);
        if (messages != null) {
            foreach (Entities.Message message in messages) {
                items.add(new MessageItem(message, conversation));
            }
        }
        Gee.List<FileTransfer> transfers = stream_interactor.get_module(FileManager.IDENTITY).get_transfers_before(conversation.account, conversation.counterpart, item.display_time, n);
        foreach (FileTransfer transfer in transfers) {
            items.add(new FileItem(transfer));
        }

        BidirIterator<ContentItem> iter = items.bidir_iterator();
        iter.last();
        int i = 0;
        while (i < n && iter.has_previous()) {
            iter.previous();
            i++;
        }
        Gee.List<ContentItem> ret = new ArrayList<ContentItem>();
        do {
            ret.add(iter.get());
        } while(iter.next());
        return ret;
    }

    public void populate_after(Conversation conversation, ContentItem item, int n) {

    }

    public void add_filter(ContentFilter content_filter) {
        filters.add(content_filter);
    }

    private void on_new_message(Message message, Conversation conversation) {
        foreach (ContentItemCollection collection in collection_conversations.keys) {
            if (collection_conversations[collection].equals(conversation)) {
                MessageItem item = new MessageItem(message, conversation);
                insert_item(collection, item);
            }
        }
    }

    private void insert_file_transfer(FileTransfer file_transfer) {
        foreach (ContentItemCollection collection in collection_conversations.keys) {
            Conversation conversation = collection_conversations[collection];
            if (conversation.account.equals(file_transfer.account) && conversation.counterpart.equals_bare(file_transfer.counterpart)) {
                FileItem item = new FileItem(file_transfer);
                insert_item(collection, item);
            }
        }
    }

    private void insert_item(ContentItemCollection item_collection, ContentItem content_item) {
        bool insert = true;
        foreach (ContentFilter filter in filters) {
            if (filter.discard(content_item)) {
                insert = false;
            }
        }
        if (insert) {
            item_collection.insert_item(content_item);
        }
    }
}

public interface ContentItemCollection : Object {
    public abstract void insert_item(ContentItem item);
    public abstract void remove_item(ContentItem item);
}

public interface ContentFilter : Object {
    public abstract bool discard(ContentItem content_item);
}

public abstract class ContentItem : Object {
    public virtual string type_ { get; set; }
    public virtual Jid? jid { get; set; default=null; }
    public virtual DateTime? sort_time { get; set; default=null; }
    public virtual double seccondary_sort_indicator { get; set; }
    public virtual DateTime? display_time { get; set; default=null; }
    public virtual Encryption? encryption { get; set; default=null; }
    public virtual Entities.Message.Marked? mark { get; set; default=null; }

    public static int compare(ContentItem a, ContentItem b) {
        int res = a.sort_time.compare(b.sort_time);
        if (res == 0) {
            res = a.display_time.compare(b.display_time);
        }
        if (res == 0) {
            res = a.seccondary_sort_indicator - b.seccondary_sort_indicator > 0 ? 1 : -1;
        }
        return res;
    }
}

public class MessageItem : ContentItem {
    public const string TYPE = "message";
    public override string type_ { get; set; default=TYPE; }

    public Message message;
    public Conversation conversation;

    public MessageItem(Message message, Conversation conversation) {
        this.message = message;
        this.conversation = conversation;

        this.jid = message.from;
        this.sort_time = message.local_time;
        this.seccondary_sort_indicator = message.id + 0.0845;
        this.display_time = message.time;
        this.encryption = message.encryption;
        this.mark = message.marked;

        WeakRef weak_message = WeakRef(message);
        message.notify["marked"].connect(() => {
            Message? m = weak_message.get() as Message;
            if (m == null) return;
            mark = m.marked;
        });
    }
}

public class FileItem : ContentItem {
    public const string TYPE = "file";
    public override string type_ { get; set; default=TYPE; }

    public FileTransfer file_transfer;
    public Conversation conversation;

    public FileItem(FileTransfer file_transfer) {
        this.file_transfer = file_transfer;

        this.jid = file_transfer.direction == FileTransfer.DIRECTION_SENT ? file_transfer.account.bare_jid.with_resource(file_transfer.account.resourcepart) : file_transfer.counterpart;
        this.sort_time = file_transfer.time;
        this.seccondary_sort_indicator = file_transfer.id + 0.2903;
        this.display_time = file_transfer.time;
        this.encryption = file_transfer.encryption;
        this.mark = file_to_message_state(file_transfer.state);
        file_transfer.notify["state"].connect_after(() => {
            this.mark = file_to_message_state(file_transfer.state);
        });
    }

    private Entities.Message.Marked file_to_message_state(FileTransfer.State state) {
        switch (state) {
            case FileTransfer.State.IN_PROCESS:
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

}
