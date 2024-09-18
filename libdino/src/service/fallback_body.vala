using Gee;
using Qlite;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

public class Dino.FallbackBody : StreamInteractionModule, Object {
    public static ModuleIdentity<FallbackBody> IDENTITY = new ModuleIdentity<FallbackBody>("fallback-body");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    private ReceivedMessageListener received_message_listener;

    public static void start(StreamInteractor stream_interactor, Database db) {
        FallbackBody m = new FallbackBody(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private FallbackBody(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.received_message_listener = new ReceivedMessageListener(stream_interactor, db);

        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "Quote"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;
        private Database db;

        public ReceivedMessageListener(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            Gee.List<Xep.FallbackIndication.Fallback> fallbacks = Xep.FallbackIndication.get_fallbacks(stanza);
            if (fallbacks.is_empty) return false;

            foreach (var fallback in fallbacks) {
                if (fallback.ns_uri != Xep.Replies.NS_URI) continue; // TODO what if it's not
            }
            message.set_fallbacks(fallbacks);

            return false;
        }
    }

    public static string get_quoted_fallback_body(ContentItem content_item) {
        string fallback = "> ";

        if (content_item.type_ == MessageItem.TYPE) {
            Message? quoted_message = ((MessageItem) content_item).message;
            fallback += Dino.message_body_without_reply_fallback(quoted_message);
            fallback = fallback.replace("\n", "\n> ");
        } else if (content_item.type_ == FileItem.TYPE) {
            FileTransfer? quoted_file = ((FileItem) content_item).file_transfer;
            fallback += quoted_file.file_name;
        }
        fallback += "\n";

        return fallback;
    }
}