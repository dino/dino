using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

namespace Dino {

public class MessageProcessor : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageProcessor> IDENTITY = new ModuleIdentity<MessageProcessor>("message_processor");
    public string id { get { return IDENTITY.id; } }

    public signal void message_received(Entities.Message message, Conversation conversation);
    public signal void build_message_stanza(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void pre_message_send(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void message_sent(Entities.Message message, Conversation conversation);
    public signal void message_sent_or_received(Entities.Message message, Conversation conversation);
    public signal void history_synced(Account account);

    public HistorySync history_sync;
    public MessageListenerHolder received_pipeline = new MessageListenerHolder();

    private StreamInteractor stream_interactor;
    private Database db;

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageProcessor m = new MessageProcessor(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private MessageProcessor(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.history_sync = new HistorySync(db, stream_interactor);

        received_pipeline.connect(new DeduplicateMessageListener(this));
        received_pipeline.connect(new FilterMessageListener());
        received_pipeline.connect(new StoreMessageListener(this, stream_interactor));
        received_pipeline.connect(new StoreContentItemListener(stream_interactor));
        received_pipeline.connect(new MarkupListener(stream_interactor));

        stream_interactor.account_added.connect(on_account_added);

        stream_interactor.stream_negotiated.connect(send_unsent_chat_messages);
        stream_interactor.stream_resumed.connect(send_unsent_chat_messages);
    }

    private void convert_sending_to_unsent_msgs(Account account) {
        db.message.update()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.marked, "=", Message.Marked.SENDING)
                .set(db.message.marked, Message.Marked.UNSENT)
                .perform();
    }

    private void send_unsent_chat_messages(Account account) {
        var select = db.message.select()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.marked, "=", (int) Message.Marked.UNSENT)
                .with(db.message.type_, "=", (int) Message.Type.CHAT);
        send_unsent_messages(account, select);
    }

    public void send_unsent_muc_messages(Account account, Jid muc_jid) {
        var select = db.message.select()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.marked, "=", (int) Message.Marked.UNSENT)
                .with(db.message.counterpart_id, "=", db.get_jid_id(muc_jid));
        send_unsent_messages(account, select);
    }

    private void send_unsent_messages(Account account, QueryBuilder select) {
        foreach (Row row in select) {
            try {
                Message message = new Message.from_row(db, row);
                Conversation? msg_conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart, account, Util.get_conversation_type_for_message(message));
                if (msg_conv != null) {
                    Message cached_msg = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(message.id, msg_conv);
                    send_xmpp_message(cached_msg ?? message, msg_conv, true);
                }
            } catch (InvalidJidError e) {
                warning("Ignoring message with invalid Jid: %s", e.message);
            }
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received.begin(account, message);
        });

        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_error.connect((stream, message_stanza, error_stanza) => {
            Message? message = null;

            Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversations(message_stanza.from, account);
            foreach (Conversation conversation in conversations) {
                message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_stanza_id(message_stanza.id, conversation);
                if (message != null) break;
            }
            if (message == null) return;
            // We don't care about delivery errors if our counterpart already ACKed the message.
            if (message.marked in Message.MARKED_RECEIVED) return;

            warning("Message delivery error from %s. Type: %s, Condition: %s, Text: %s", message_stanza.from.to_string(), error_stanza.type_ ?? "-", error_stanza.condition, error_stanza.text ?? "-");
            if (error_stanza.condition == Xmpp.ErrorStanza.CONDITION_RECIPIENT_UNAVAILABLE && error_stanza.type_ == Xmpp.ErrorStanza.TYPE_CANCEL) return;

            message.marked = Message.Marked.ERROR;
        });

        convert_sending_to_unsent_msgs(account);
    }

    private async void on_message_received(Account account, Xmpp.MessageStanza message_stanza) {

        // If it's a message from MAM, it's going to be processed by HistorySync which calls run_pipeline_announce later.
        if (history_sync.process(account, message_stanza)) return;

        run_pipeline_announce.begin(account, message_stanza);
    }

    public async void run_pipeline_announce(Account account, Xmpp.MessageStanza message_stanza) {
        Entities.Message message = yield parse_message_stanza(account, message_stanza);

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
        if (conversation == null) return;

        bool abort = yield received_pipeline.run(message, message_stanza, conversation);
        if (abort) return;

        if (message.direction == Entities.Message.DIRECTION_RECEIVED) {
            message_received(message, conversation);
        } else if (message.direction == Entities.Message.DIRECTION_SENT) {
            message_sent(message, conversation);
        }

        message_sent_or_received(message, conversation);
    }

    public async Entities.Message parse_message_stanza(Account account, Xmpp.MessageStanza message) {
        string? body = message.body;
        if (body != null) body = body.strip();
        Entities.Message new_message = new Entities.Message(body);
        new_message.account = account;
        new_message.stanza_id = Xep.UniqueStableStanzaIDs.get_origin_id(message) ?? message.id;

        Jid? counterpart_override = null;
        if (message.from.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(message.from.bare_jid, account))) {
            new_message.direction = Entities.Message.DIRECTION_SENT;
            counterpart_override = message.from.bare_jid;
        } else if (account.bare_jid.equals_bare(message.from)) {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        } else {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        }
        new_message.counterpart = counterpart_override ?? (new_message.direction == Entities.Message.DIRECTION_SENT ? message.to : message.from);
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? message.from : message.to;

        Xmpp.MessageArchiveManagement.MessageFlag? mam_message_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message);
        EntityInfo entity_info = stream_interactor.get_module(EntityInfo.IDENTITY);
        if (mam_message_flag != null && mam_message_flag.mam_id != null) {
            bool server_does_mam = entity_info.has_feature_cached(account, account.bare_jid, Xmpp.MessageArchiveManagement.NS_URI);
            if (server_does_mam) {
                new_message.server_id = mam_message_flag.mam_id;
            }
        } else if (message.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
            bool server_supports_sid = (yield entity_info.has_feature(account, new_message.counterpart.bare_jid, Xep.UniqueStableStanzaIDs.NS_URI)) ||
                    (yield entity_info.has_feature(account, new_message.counterpart.bare_jid, Xmpp.MessageArchiveManagement.NS_URI));
            if (server_supports_sid) {
                new_message.server_id = Xep.UniqueStableStanzaIDs.get_stanza_id(message, new_message.counterpart.bare_jid);
            }
        } else if (message.type_ == Xmpp.MessageStanza.TYPE_CHAT) {
            bool server_supports_sid = (yield entity_info.has_feature(account, account.bare_jid, Xep.UniqueStableStanzaIDs.NS_URI)) ||
                    (yield entity_info.has_feature(account, account.bare_jid, Xmpp.MessageArchiveManagement.NS_URI));
            if (server_supports_sid) {
                new_message.server_id = Xep.UniqueStableStanzaIDs.get_stanza_id(message, account.bare_jid);
            }
        }

        if (mam_message_flag != null) new_message.local_time = mam_message_flag.server_time;
        DateTime now = new DateTime.from_unix_utc(new DateTime.now_utc().to_unix()); // Remove milliseconds. They are not stored in the db and might lead to ordering issues when compared with times from the db.
        if (new_message.local_time == null || new_message.local_time.compare(now) > 0) new_message.local_time = now;

        Xep.DelayedDelivery.MessageFlag? delayed_message_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        if (delayed_message_flag != null) new_message.time = delayed_message_flag.datetime;
        if (new_message.time == null || new_message.time.compare(new_message.local_time) > 0) new_message.time = new_message.local_time;

        new_message.type_ = yield determine_message_type(account, message, new_message);

        return new_message;
    }

    private async Entities.Message.Type determine_message_type(Account account, Xmpp.MessageStanza message_stanza, Entities.Message message) {
        if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
            return Entities.Message.Type.GROUPCHAT;
        }
        if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_CHAT) {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart.bare_jid, account);
            if (conversation != null) {
                if (conversation.type_ == Conversation.Type.CHAT) {
                    return Entities.Message.Type.CHAT;
                } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    return Entities.Message.Type.GROUPCHAT_PM;
                }
            } else {
                XmppStream stream = stream_interactor.get_stream(account);
                if (stream != null) {
                    Gee.Set<Xep.ServiceDiscovery.Identity>? identities = yield stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).get_entity_identities(stream, message.counterpart.bare_jid);
                    if (identities == null) {
                        return Entities.Message.Type.CHAT;
                    }
                    foreach (Xep.ServiceDiscovery.Identity identity in identities) {
                        if (identity.category == Xep.ServiceDiscovery.Identity.CATEGORY_CONFERENCE) {
                            return Entities.Message.Type.GROUPCHAT_PM;
                        } else {
                            return Entities.Message.Type.CHAT;
                        }
                    }
                }
            }
        }
        return Entities.Message.Type.CHAT;
    }

    private bool is_duplicate(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        Account account = conversation.account;

        // Deduplicate by server_id
        if (message.server_id != null) {
            QueryBuilder builder =  db.message.select()
                    .with(db.message.server_id, "=", message.server_id)
                    .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                    .with(db.message.account_id, "=", account.id);

            // If the message is a duplicate
            if (builder.count() > 0) {
                history_sync.on_server_id_duplicate(account, stanza, message);
                return true;
            }
        }

        // Deduplicate messages by uuid
        bool is_uuid = message.stanza_id != null && Regex.match_simple("""[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}""", message.stanza_id);
        if (is_uuid) {
            QueryBuilder builder =  db.message.select()
                    .with(db.message.stanza_id, "=", message.stanza_id)
                    .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                    .with(db.message.account_id, "=", account.id);
            if (message.direction == Message.DIRECTION_RECEIVED) {
                if (message.counterpart.resourcepart != null) {
                    builder.with(db.message.counterpart_resource, "=", message.counterpart.resourcepart);
                } else {
                    builder.with_null(db.message.counterpart_resource);
                }
            } else if (message.direction == Message.DIRECTION_SENT) {
                if (message.ourpart.resourcepart != null) {
                    builder.with(db.message.our_resource, "=", message.ourpart.resourcepart);
                } else {
                    builder.with_null(db.message.our_resource);
                }
            }
            bool duplicate = builder.single().row().is_present();
            return duplicate;
        }

        // Deduplicate messages based on content and metadata
        QueryBuilder builder = db.message.select()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                .with(db.message.body, "=", message.body)
                .with(db.message.time, "<", (long) message.time.add_minutes(1).to_unix())
                .with(db.message.time, ">", (long) message.time.add_minutes(-1).to_unix());
        if (message.stanza_id != null) {
            builder.with(db.message.stanza_id, "=", message.stanza_id);
        } else {
            builder.with_null(db.message.stanza_id);
        }
        if (message.counterpart.resourcepart != null) {
            builder.with(db.message.counterpart_resource, "=", message.counterpart.resourcepart);
        } else {
            builder.with_null(db.message.counterpart_resource);
        }
        return builder.count() > 0;
    }

    private class DeduplicateMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "FILTER_EMPTY", "MUC" };
        public override string action_group { get { return "DEDUPLICATE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private MessageProcessor outer;

        public DeduplicateMessageListener(MessageProcessor outer) {
            this.outer = outer;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            return outer.is_duplicate(message, stanza, conversation);
        }
    }

    private class FilterMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DECRYPT" };
        public override string action_group { get { return "FILTER_EMPTY"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            return message.body == null &&
                    Xep.StatelessFileSharing.get_file_shares(stanza) == null;
        }
    }

    private class StoreMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "DECRYPT", "FILTER_EMPTY" };
        public override string action_group { get { return "STORE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private MessageProcessor outer;
        private StreamInteractor stream_interactor;

        public StoreMessageListener(MessageProcessor outer, StreamInteractor stream_interactor) {
            this.outer = outer;
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            stream_interactor.get_module(MessageStorage.IDENTITY).add_message(message, conversation);
            return false;
        }
    }

    private class MarkupListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "Markup"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public MarkupListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            Gee.List<MessageMarkup.Span> markups = MessageMarkup.get_spans(stanza);
            message.persist_markups(markups, message.id);
            return false;
        }
    }

    private class StoreContentItemListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "DECRYPT", "FILTER_EMPTY", "STORE", "RETRACTION", "CORRECTION", "MESSAGE_REINTERPRETING" };
        public override string action_group { get { return "STORE_CONTENT_ITEM"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public StoreContentItemListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (message.body == null) return true;
            stream_interactor.get_module(ContentItemStore.IDENTITY).insert_message(message, conversation);
            return false;
        }
    }

    public Entities.Message create_out_message(string? text, Conversation conversation) {
        Entities.Message message = new Entities.Message(text);
        message.type_ = Util.get_message_type_for_conversation(conversation);
        message.stanza_id = random_uuid();
        message.account = conversation.account;
        message.body = text;
        DateTime now = new DateTime.from_unix_utc(new DateTime.now_utc().to_unix()); // Remove milliseconds. They are not stored in the db and might lead to ordering issues when compared with times from the db.
        message.time = now;
        message.local_time = now;
        message.direction = Entities.Message.DIRECTION_SENT;
        message.counterpart = conversation.counterpart;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            message.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            message.real_jid = conversation.account.bare_jid;
        } else {
            message.ourpart = conversation.account.full_jid;
        }
        message.marked = Entities.Message.Marked.UNSENT;
        message.encryption = conversation.encryption;

        stream_interactor.get_module(MessageStorage.IDENTITY).add_message(message, conversation);

        return message;
    }

    public void send_xmpp_message(Entities.Message message, Conversation conversation, bool delayed = false) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        message.marked = Entities.Message.Marked.SENDING;

        if (stream == null) {
            message.marked = Entities.Message.Marked.UNSENT;
            return;
        }

        MessageStanza new_message = new MessageStanza(message.stanza_id);
        new_message.to = message.counterpart;
        new_message.body = message.body;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            new_message.type_ = MessageStanza.TYPE_GROUPCHAT;
        } else {
            new_message.type_ = MessageStanza.TYPE_CHAT;
        }

        if (message.quoted_item_id != 0) {
            ContentItem? quoted_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, message.quoted_item_id);
            if (quoted_content_item != null) {
                Jid? quoted_sender = message.from;
                string? quoted_stanza_id = stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_id_for_content_item(conversation, quoted_content_item);
                if (quoted_sender != null && quoted_stanza_id != null) {
                    Xep.Replies.set_reply_to(new_message, new Xep.Replies.ReplyTo(quoted_sender, quoted_stanza_id));
                }

                foreach (var fallback in message.get_fallbacks()) {
                    Xep.FallbackIndication.set_fallback(new_message, fallback);
                }
            }
        }

        MessageMarkup.add_spans(new_message, message.get_markups());

        build_message_stanza(message, new_message, conversation);
        pre_message_send(message, new_message, conversation);
        if (message.marked == Entities.Message.Marked.UNSENT || message.marked == Entities.Message.Marked.WONTSEND) return;
        if (delayed) {
            DelayedDelivery.Module.set_message_delay(new_message, message.time);
        }

        // Set an origin ID if a MUC doen't guarantee to keep IDs
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
            if (flag == null) {
                message.marked = Entities.Message.Marked.UNSENT;
                return;
            }
            if(!flag.has_room_feature(conversation.counterpart, Xep.Muc.Feature.STABLE_ID)) {
                UniqueStableStanzaIDs.set_origin_id(new_message, message.stanza_id);
            }
        }

        if (conversation.get_send_typing_setting(stream_interactor) == Conversation.Setting.ON) {
            ChatStateNotifications.add_state_to_message(new_message, ChatStateNotifications.STATE_ACTIVE);
        }

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, new_message, (_, res) => {
            try {
                stream.get_module(MessageModule.IDENTITY).send_message.end(res);
                if (message.marked == Message.Marked.SENDING) {
                    message.marked = Message.Marked.SENT;
                }

                // The server might not have given us the resource we asked for. In that case, store the actual resource the message was sent with. Relevant for deduplication.
                Jid? current_own_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
                if (!conversation.type_.is_muc_semantic() && current_own_jid != null && !current_own_jid.equals(message.ourpart)) {
                    message.ourpart = current_own_jid;
                }
            } catch (IOError e) {
                message.marked = Entities.Message.Marked.UNSENT;

                if (stream != stream_interactor.get_stream(conversation.account)) {
                    Timeout.add_seconds(3, () => {
                        send_unsent_chat_messages(conversation.account);
                        return false;
                    });
                }
            }
        });
    }
}

public abstract class MessageListener : Xmpp.OrderedListener {

    public abstract async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation);
}

public class MessageListenerHolder : Xmpp.ListenerHolder {

    public async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        foreach (OrderedListener ol in listeners) {
            MessageListener l = ol as MessageListener;
            bool stop = yield l.run(message, stanza, conversation);
            if (stop) return true;
        }
        return false;
    }
}

}
