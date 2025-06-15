using Xmpp;
using Dino.Entities;

namespace Dino {

public class MessageRetraction : StreamInteractionModule, MessageListener {
    public static ModuleIdentity<MessageRetraction> IDENTITY = new ModuleIdentity<MessageRetraction>("message_retraction");
    public string id { get { return IDENTITY.id; } }

    public signal void received_retraction(ContentItem content_item);

    private StreamInteractor stream_interactor;
    private Database db;

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageRetraction m = new MessageRetraction(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public MessageRetraction(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(this);
    }

    public string[] after_actions_const = new string[]{};
    public override string action_group { get { return "RETRACTION"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        string? retract_id = Xep.MessageRetraction.get_retract_id(stanza);

        if (retract_id == null) {
            return false;
        }

        var target_msg = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_server_id(retract_id, conversation);

        var allowed = false;
        if (target_msg.from != null && target_msg.from.equals(message.from)) {
            // user retracts their own message
            allowed = true;
        }
        else if (conversation.type_ == Conversation.Type.GROUPCHAT && message.from.equals(conversation.counterpart)) {
            // retracted by moderator per XEP-0425
            allowed = true;
        }

        if (!allowed) return false;

        if (target_msg != null) {
            target_msg.retracted = true;

            on_received_retraction(conversation, target_msg.id);
        }

        return true;
    }

    private void on_received_retraction(Conversation conversation, int message_id) {
        ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_foreign(conversation, 1, message_id);
        if (content_item != null) {
            received_retraction(content_item);
        }
    }
}

}
