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
    public HashMap<Conversation, Gee.List<ContentItem>> unmatched_corrections = new HashMap<Conversation, Gee.List<ContentItem>>(Conversation.hash_func, Conversation.equals_func);

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
        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(cache_unmatched_correction);
    }

    public void set_correction(Conversation conversation, Message message, Message old_message) {
        string reference_stanza_id = old_message.edit_to ?? old_message.stanza_id;

        outstanding_correction_nodes[message.stanza_id] = reference_stanza_id;

        db.message_correction.insert()
                .value(db.message_correction.message_id, message.id)
                .value(db.message_correction.to_stanza_id, reference_stanza_id)
                .perform();

        db.content_item.update()
                .with(db.content_item.foreign_id, "=", old_message.id)
                .with(db.content_item.content_type, "=", 1)
                .set(db.content_item.foreign_id, message.id)
                .perform();
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
        // Check if we already know a newer correction for this message
        if (unmatched_corrections.has_key(conversation) && unmatched_corrections[conversation].size > 0) {
            ContentItem? remove_from_list = null;
            bool? ret = null;
            foreach (var unmatched_correction_item in unmatched_corrections[conversation]) {
                MessageItem unmatched_correction_message_item = unmatched_correction_item as MessageItem;
                if (unmatched_correction_message_item != null) {
                    if (MessageStorage.get_reference_id(message) == unmatched_correction_message_item.message.edit_to) {
                        debug("Matching original message to correction retrospectively %s", unmatched_correction_message_item.message.edit_to);
                        remove_from_list = unmatched_correction_item;
                        ret = process_wrong_order_correction(conversation, message, unmatched_correction_message_item);
                    } else if (unmatched_correction_message_item.message.edit_to == message.edit_to) {
                        debug("Got another correction to the same (unknown) original message %s", message.edit_to);
                        ret = process_wrong_order_correction(conversation, message, unmatched_correction_message_item);
                    }
                }
            }
            if (remove_from_list != null) unmatched_corrections[conversation].remove(remove_from_list);
            if (ret != null) return ret;
        }

        string? replace_id = Xep.LastMessageCorrection.get_replace_id(stanza);

        // Store the latest message for every resource. This enables the corrections-allowed-check specified in the XEP.
        // This is only needed for MUCs - In case the MUC doesn't support occupant ids, the last message can still be corrected.
        if (replace_id == null && conversation.type_.is_muc_semantic()) {
            // Don't process messages or corrections from MUC history or MUC MAM
            if (Xep.DelayedDelivery.get_time_for_message(stanza, message.from.bare_jid) == null &&
                    Xmpp.MessageArchiveManagement.MessageFlag.get_flag(stanza) == null) {
                if (!last_messages.has_key(conversation)) {
                    last_messages[conversation] = new HashMap<Jid, Message>(Jid.hash_func, Jid.equals_func);
                }
                last_messages[conversation][message.from] = message;
            }
        }

        if (replace_id != null) {
            message.edit_to = replace_id; // This isn't persisted here, but later after verifying that it's an allowed edit TODO?
            return process_unverified_in_order_correction(conversation, message, replace_id);
        }
        return false;
    }

    private bool process_wrong_order_correction(Conversation conversation, Message earlier_message, MessageItem correction_item) {
        if (!is_correction_acceptable(earlier_message, correction_item.message)) {
            return false;
        }

        db.message_correction.insert()
                .value(db.message_correction.message_id, correction_item.message.id)
                .value(db.message_correction.to_stanza_id, correction_item.message.edit_to)
                .perform();

        db.content_item.update()
                .with(db.content_item.id, "=", correction_item.id)
                .set(db.content_item.time, (long) earlier_message.time.to_unix())
                .set(db.content_item.local_time, (long) earlier_message.local_time.to_unix())
                .perform();

        on_received_correction(conversation, correction_item.message.id);

        return true;
    }

    private bool process_unverified_in_order_correction(Conversation conversation, Message correction_message, string replace_id) {
        // Legacy logic for MUCs without occupant id support
        if (conversation.type_.is_muc_semantic()) {
            if (last_messages.has_key(conversation) && last_messages[conversation].has_key(correction_message.from)) {
                var last_message = last_messages[conversation][correction_message.from];
                bool acceptable = last_message.stanza_id == replace_id;
                if (acceptable) {
                    return process_in_order_correction(conversation, last_messages[conversation][correction_message.from], correction_message);
                }
            }
        }

        Message? original_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_stanza_id(replace_id, conversation);
        if (original_message != null && is_correction_acceptable(original_message, correction_message)) {
            correction_message.edit_to = replace_id;
            return process_in_order_correction(conversation, original_message, correction_message);
        }
        return false;
    }

    private bool process_in_order_correction(Conversation conversation, Message original_message, Message correction_message) {
        ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_content_item_for_message(conversation, original_message);

        db.message_correction.insert()
                .value(db.message_correction.message_id, correction_message.id)
                .value(db.message_correction.to_stanza_id, correction_message.edit_to)
                .perform();

        int current_correction_message_id = get_latest_correction_message_id(conversation, original_message);
        if (content_item != null) {
            db.content_item.update()
                    .with(db.content_item.id, "=", content_item.id)
                    .with(db.content_item.content_type, "=", 1)
                    .set(db.content_item.foreign_id, current_correction_message_id)
                    .perform();

            on_received_correction(conversation, current_correction_message_id);

            return true;
        } else {
            warning("Got no content item for %s", correction_message.edit_to);
        }

        return false;
    }

    public void on_received_correction(Conversation conversation, int message_id) {
        ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_foreign(conversation, 1, message_id);
        if (content_item != null) {
            received_correction(content_item);
        }
    }

    public int get_latest_correction_message_id(Conversation conversation, Message message) {
        var qry = db.message_correction.select({db.message.id})
                .join_with(db.message, db.message.id, db.message_correction.message_id)
                .with(db.message.account_id, "=", conversation.account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(conversation.counterpart))
                .with(db.message_correction.to_stanza_id, "=", message.edit_to ?? message.stanza_id)
                .order_by(db.message.time, "DESC");

        if (message.occupant_db_id != -1) {
            qry.outer_join_with(db.message_occupant_id, db.message_occupant_id.message_id, db.message.id)
                .with(db.message_occupant_id.occupant_id, "=", message.occupant_db_id);
        } else if (message.counterpart.resourcepart != null) {
            qry.with(db.message.counterpart_resource, "=", message.counterpart.resourcepart);
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

    private void cache_unmatched_correction(ContentItem content_item, Conversation conversation) {
        MessageItem message_item = content_item as MessageItem;
        if (message_item == null || message_item.message.edit_to == null) return;

        // Check if this is an unmatched correction
        if (content_item.time != message_item.time) return;

        debug(@"Caching unmatched correction $(message_item.message.server_id) $(message_item.id)");
        if (!unmatched_corrections.has_key(conversation)) unmatched_corrections[conversation] = new ArrayList<ContentItem>();
        unmatched_corrections[conversation].add(content_item);
    }
}

    // Accepts MUC corrections iff the occupant id matches
    // Accepts 1:1 corrections iff the bare jid matches
    private bool is_correction_acceptable(Message original_message, Message correction_message) {
        bool acceptable = (original_message.type_.is_muc_semantic() && original_message.occupant_db_id != -1 && original_message.occupant_db_id == correction_message.occupant_db_id) ||
                (original_message.type_ == Message.Type.CHAT && original_message.from.equals_bare(correction_message.from));
        if (!acceptable) warning("Got unacceptable correction (%i to %i from %s)", correction_message.id, original_message.id, correction_message.from.to_string());
        return acceptable;
    }

}
