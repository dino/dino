using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

namespace Dino {


public class MessageCorrection : StreamInteractionModule, MessageListener {
    public static ModuleIdentity<MessageCorrection> IDENTITY = new ModuleIdentity<MessageCorrection>("message_correction");
    public string id { get { return IDENTITY.id; } }

    public signal void received_correction(ContentItem content_item);

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Conversation, HashMap<Jid, Message>> last_messages = new HashMap<Conversation, HashMap<Jid, Message>>(Conversation.hash_func, Conversation.equals_func);

    private HashMap<string, string> outstanding_correction_nodes = new HashMap<string, string>();

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageCorrection m = new MessageCorrection(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public MessageCorrection(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(this);
        stream_interactor.get_module(MessageProcessor.IDENTITY).build_message_stanza.connect(check_add_correction_node);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid.bare_jid, account, Conversation.Type.GROUPCHAT);
            if (conversation != null) {
                if (last_messages.has_key(conversation)) last_messages[conversation].unset(jid);
            }
        });
    }

    public void send_correction(Conversation conversation, Message old_message, string correction_text) {
        string stanza_id = old_message.edit_to ?? old_message.stanza_id;

        Message out_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(correction_text, conversation);
        out_message.edit_to = stanza_id;
        outstanding_correction_nodes[out_message.stanza_id] = stanza_id;
        stream_interactor.get_module(MessageStorage.IDENTITY).add_message(out_message, conversation);
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(out_message, conversation);

        db.message_correction.insert()
            .value(db.message_correction.message_id, out_message.id)
            .value(db.message_correction.to_stanza_id, stanza_id)
            .perform();

        db.content_item.update()
            .with(db.content_item.foreign_id, "=", old_message.id)
            .with(db.content_item.content_type, "=", 1)
            .set(db.content_item.foreign_id, out_message.id)
            .perform();

        on_received_correction(conversation, out_message.id);
    }

    public bool is_own_correction_allowed(Conversation conversation, Message message) {
        string stanza_id = message.edit_to ?? message.stanza_id;

        Jid? own_jid = null;
        if (conversation.type_ == Conversation.Type.CHAT) {
            own_jid = conversation.account.full_jid;
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            own_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        }

        if (own_jid == null) return false;

        return last_messages.has_key(conversation) &&
                last_messages[conversation].has_key(own_jid) &&
                last_messages[conversation][own_jid].stanza_id == stanza_id;
    }

    private void check_add_correction_node(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (outstanding_correction_nodes.has_key(message.stanza_id)) {
            LastMessageCorrection.set_replace_id(message_stanza, outstanding_correction_nodes[message.stanza_id]);
            outstanding_correction_nodes.unset(message.stanza_id);
        } else {
            if (!last_messages.has_key(conversation)) {
                last_messages[conversation] = new HashMap<Jid, Message>(Jid.hash_func, Jid.equals_func);
            }
            last_messages[conversation][message.from] = message;
        }
    }

    public string[] after_actions_const = new string[]{ "DEDUPLICATE", "DECRYPT", "FILTER_EMPTY" };
    public override string action_group { get { return "CORRECTION"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        if (conversation.type_ != Conversation.Type.CHAT) {
            // Don't process messages or corrections from MUC history
            DateTime? mam_delay = Xep.DelayedDelivery.get_time_for_message(stanza, message.from.bare_jid);
            if (mam_delay != null) return false;
        }

        string? replace_id = Xep.LastMessageCorrection.get_replace_id(stanza);
        if (replace_id == null) {
            if (!last_messages.has_key(conversation)) {
                last_messages[conversation] = new HashMap<Jid, Message>(Jid.hash_func, Jid.equals_func);
            }
            last_messages[conversation][message.from] = message;

            return false;
        }

        if (!last_messages.has_key(conversation) || !last_messages[conversation].has_key(message.from)) return false;
        Message original_message = last_messages[conversation][message.from];
        if (original_message.stanza_id != replace_id) return false;

        int message_id_to_be_updated = get_latest_correction_message_id(conversation.account.id, replace_id, db.get_jid_id(message.counterpart), message.counterpart.resourcepart);
        if (message_id_to_be_updated == -1) {
            message_id_to_be_updated = original_message.id;
        }

        db.message_correction.insert()
            .value(db.message_correction.message_id, message.id)
            .value(db.message_correction.to_stanza_id, replace_id)
            .perform();

        int current_correction_message_id = get_latest_correction_message_id(conversation.account.id, replace_id, db.get_jid_id(message.counterpart), message.counterpart.resourcepart);

        if (current_correction_message_id != message_id_to_be_updated) {
            db.content_item.update()
                    .with(db.content_item.foreign_id, "=", message_id_to_be_updated)
                    .with(db.content_item.content_type, "=", 1)
                    .set(db.content_item.foreign_id, current_correction_message_id)
                    .perform();
            message.edit_to = replace_id;

            on_received_correction(conversation, current_correction_message_id);

            return true;
        }

        return false;
    }

    private void on_received_correction(Conversation conversation, int message_id) {
        ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message_id);
        received_correction(content_item);
    }

    private int get_latest_correction_message_id(int account_id, string stanza_id, int counterpart_jid_id, string? counterpart_resource) {
        var qry = db.message_correction.select({db.message.id})
                .join_with(db.message, db.message.id, db.message_correction.message_id)
                .with(db.message.account_id, "=", account_id)
                .with(db.message.counterpart_id, "=", counterpart_jid_id)
                .with(db.message_correction.to_stanza_id, "=", stanza_id)
                .order_by(db.message.time, "DESC");

        if (counterpart_resource != null) {
            qry.with(db.message.counterpart_resource, "=", counterpart_resource);
        }
        RowOption row = qry.single().row();
        if (row.is_present()) {
            return row[db.message.id];
        }
        return -1;
    }

    private void on_account_added(Account account) {
        Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations(account);
        foreach (Conversation conversation in conversations) {
            if (conversation.type_ != Conversation.Type.CHAT) continue;

            HashMap<Jid, Message> last_conversation_messages = new HashMap<Jid, Message>(Jid.hash_func, Jid.equals_func);
            Gee.List<Message> messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation);
            for (int i = messages.size - 1; i > 0; i--) {
                Message message = messages[i];
                if (!last_conversation_messages.has_key(message.from) && message.edit_to == null) {
                    last_conversation_messages[message.from] = message;
                }
            }
            last_messages[conversation] = last_conversation_messages;
        }
    }
}

}
