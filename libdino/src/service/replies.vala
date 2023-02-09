using Gee;
using Qlite;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

public class Dino.Replies : StreamInteractionModule, Object {
    public static ModuleIdentity<Replies> IDENTITY = new ModuleIdentity<Replies>("reply");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Conversation, HashMap<string, Gee.List<Message>>> unmapped_replies = new HashMap<Conversation, HashMap<string, Gee.List<Message>>>();

    private ReceivedMessageListener received_message_listener;

    public static void start(StreamInteractor stream_interactor, Database db) {
        Replies m = new Replies(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private Replies(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.received_message_listener = new ReceivedMessageListener(stream_interactor, this);

        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
    }

    public ContentItem? get_quoted_content_item(Message message, Conversation conversation) {
        if (message.quoted_item_id == 0) return null;

        RowOption row_option = db.reply.select().with(db.reply.message_id, "=", message.id).row();
        if (row_option.is_present()) {
            return stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, row_option[db.reply.quoted_content_item_id]);
        }
        return null;
    }

    public void set_message_is_reply_to(Message message, ContentItem reply_to) {
        message.quoted_item_id = reply_to.id;

        db.reply.upsert()
                .value(db.reply.message_id, message.id, true)
                .value(db.reply.quoted_content_item_id, reply_to.id)
                .value_null(db.reply.quoted_message_stanza_id)
                .value_null(db.reply.quoted_message_from)
                .perform();
    }

    private void on_incoming_message(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        // Check if a previous message was in reply to this one
        var reply_qry = db.reply.select();
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            reply_qry.with(db.reply.quoted_message_stanza_id, "=", message.server_id);
        } else {
            reply_qry.with(db.reply.quoted_message_stanza_id, "=", message.stanza_id);
        }
        reply_qry.join_with(db.message, db.reply.message_id, db.message.id)
                .with(db.message.account_id, "=", conversation.account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message.time, ">", (long)message.time.to_unix())
                .order_by(db.message.time, "DESC");

        foreach (Row reply_row in reply_qry) {
            ContentItem? message_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_foreign(conversation, 1, message.id);
            Message? reply_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(reply_row[db.message.id], conversation);
            if (message_item != null && reply_message != null) {
                set_message_is_reply_to(reply_message, message_item);
            }
        }

        // Handle if this message is a reply
        Xep.Replies.ReplyTo? reply_to = Xep.Replies.get_reply_to(stanza);
        if (reply_to == null) return;

        ContentItem? quoted_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_content_item_for_message_id(conversation, reply_to.to_message_id);
        if (quoted_content_item == null) return;

        set_message_is_reply_to(message, quoted_content_item);
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE", "STORE_CONTENT_ITEM" };
        public override string action_group { get { return "Quote"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private Replies outer;

        public ReceivedMessageListener(StreamInteractor stream_interactor, Replies outer) {
            this.outer = outer;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            outer.on_incoming_message(message, stanza, conversation);
            return false;
        }
    }
}

namespace Dino {
    public string message_body_without_reply_fallback(Message message) {
        string body = message.body;
        foreach (var fallback in message.get_fallbacks()) {
            if (fallback.ns_uri == Xep.Replies.NS_URI && message.quoted_item_id > 0) {
                body = body[0:fallback.locations[0].from_char] + body[fallback.locations[0].to_char:body.length];
            }
        }
        return body;
    }
}
