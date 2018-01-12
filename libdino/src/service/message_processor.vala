using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class MessageProcessor : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageProcessor> IDENTITY = new ModuleIdentity<MessageProcessor>("message_processor");
    public string id { get { return IDENTITY.id; } }

    public signal void pre_message_received(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void message_received(Entities.Message message, Conversation conversation);
    public signal void build_message_stanza(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void pre_message_send(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void message_sent(Entities.Message message, Conversation conversation);

    private StreamInteractor stream_interactor;
    private Database db;
    private Object lock_send_unsent;

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageProcessor m = new MessageProcessor(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private MessageProcessor(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            if (state == ConnectionManager.ConnectionState.CONNECTED) send_unsent_messages(account);
        });
    }

    public void send_message(string text, Conversation conversation) {
        Entities.Message message = create_out_message(text, conversation);
        stream_interactor.get_module(MessageStorage.IDENTITY).add_message(message, conversation);
        send_xmpp_message(message, conversation);
        message_sent(message, conversation);
    }

    public void send_unsent_messages(Account account, Jid? jid = null) {
        Gee.List<Entities.Message> unsend_messages = db.get_unsend_messages(account, jid);
        foreach (Entities.Message message in unsend_messages) {
            Conversation? msg_conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart, account);
            if (msg_conv != null) {
                send_xmpp_message(message, msg_conv, true);
            }
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received(account, message);
        });
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.MessageArchiveManagement.Module.IDENTITY).feature_available.connect( (stream) => {
            DateTime start_time = account.mam_earliest_synced.to_unix() > 60 ? account.mam_earliest_synced.add_minutes(-1) : account.mam_earliest_synced;
            stream.get_module(Xep.MessageArchiveManagement.Module.IDENTITY).query_archive(stream, null, start_time, null);
        });
    }

    private void on_message_received(Account account, Xmpp.MessageStanza message) {
        if (message.body == null) return;

        Entities.Message new_message = create_in_message(account, message);
        if (new_message == null) return;

        determine_message_type(account, message, new_message);
    }

    private Entities.Message? create_in_message(Account account, Xmpp.MessageStanza message) {
        Entities.Message new_message = new Entities.Message(message.body);
        new_message.account = account;
        new_message.stanza_id = message.id;
        if (!account.bare_jid.equals_bare(message.from) ||
                message.from.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(message.from.bare_jid, account))) {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        } else {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        }
        new_message.counterpart = new_message.direction == Entities.Message.DIRECTION_SENT ? message.to : message.from;
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? message.from : message.to;
        new_message.stanza = message;

        // Slack non-standard behavior
        if (account.domainpart.index_of("xmpp.slack.com") == account.domainpart.length - 14) {
            if (new_message.counterpart.equals_bare(account.bare_jid)) {
                // Ignore messages from us, because we neither know which conversation they belong to, nor can match
                // them to one of our send messages because of timestamp mismatches.
                return null;
            }
            if (new_message.direction == Entities.Message.DIRECTION_RECEIVED && message.type_ == "chat" && new_message.body.index_of("["+account.localpart+"] ") == 0) {
                // That is the best thing we can do, although allowing for attacks.
                new_message.direction = Entities.Message.DIRECTION_SENT;
                new_message.body = new_message.body.substring(account.localpart.length + 3);
            }
            if (message.stanza.get_attribute("ts") != null) {
                new_message.time = new DateTime.from_unix_utc((int64) double.parse(message.stanza.get_attribute("ts")));
            }
        }

        Xep.MessageArchiveManagement.MessageFlag? mam_message_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
        if (mam_message_flag != null) new_message.local_time = mam_message_flag.server_time;
        if (new_message.local_time == null || new_message.local_time.compare(new DateTime.now_utc()) > 0) new_message.local_time = new DateTime.now_utc();

        Xep.DelayedDelivery.MessageFlag? delayed_message_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        if (delayed_message_flag != null) new_message.time = delayed_message_flag.datetime;
        if (new_message.time == null || new_message.time.compare(new_message.local_time) > 0) new_message.time = new_message.local_time;

        return new_message;
    }

    private void process_message(Entities.Message new_message, Xmpp.MessageStanza stanza) {
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(new_message);
        if (conversation != null) {
            pre_message_received(new_message, stanza, conversation);

            bool is_uuid = new_message.stanza_id != null && Regex.match_simple("""[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}""", new_message.stanza_id);
            if ((is_uuid && !db.contains_message_by_stanza_id(new_message.stanza_id, conversation.account)) ||
                    (!is_uuid && !db.contains_message(new_message, conversation.account))) {
                stream_interactor.get_module(MessageStorage.IDENTITY).add_message(new_message, conversation);

                if (new_message.direction == Entities.Message.DIRECTION_SENT) {
                    message_sent(new_message, conversation);
                } else {
                    message_received(new_message, conversation);
                }

                bool is_mam_message = Xep.MessageArchiveManagement.MessageFlag.get_flag(stanza) != null;
                XmppStream? stream = stream_interactor.get_stream(conversation.account);
                Xep.MessageArchiveManagement.Flag? mam_flag = stream != null ? stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) : null;
                if (is_mam_message || (mam_flag != null && mam_flag.cought_up == true)) {
                    conversation.account.mam_earliest_synced = new_message.local_time;
                }
            }
        }
    }

    private void determine_message_type(Account account, Xmpp.MessageStanza message_stanza, Entities.Message message) {
        if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
            message.type_ = Entities.Message.Type.GROUPCHAT;
            process_message(message, message_stanza);
        } else if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_CHAT) {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart.bare_jid, account);
            if (conversation != null) {
                if (conversation.type_ == Conversation.Type.CHAT) {
                    message.type_ = Entities.Message.Type.CHAT;
                } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    message.type_ = Entities.Message.Type.GROUPCHAT_PM;
                }
                process_message(message, message_stanza);
            } else {
                XmppStream stream = stream_interactor.get_stream(account);
                if (stream != null) stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).get_entity_categories(stream, message.counterpart.bare_jid, (stream, identities) => {
                    if (identities == null) {
                        message.type_ = Entities.Message.Type.CHAT;
                        process_message(message, message_stanza);
                        return;
                    }
                    foreach (Xep.ServiceDiscovery.Identity identity in identities) {
                        if (identity.category == Xep.ServiceDiscovery.Identity.CATEGORY_CONFERENCE) {
                            message.type_ = Entities.Message.Type.GROUPCHAT_PM;
                        } else {
                            message.type_ = Entities.Message.Type.CHAT;
                        }
                    }
                    process_message(message, message_stanza);
                });
            }
        }
    }

    private Entities.Message create_out_message(string text, Conversation conversation) {
        Entities.Message message = new Entities.Message(text);
        message.type_ = Util.get_message_type_for_conversation(conversation);
        message.stanza_id = random_uuid();
        message.account = conversation.account;
        message.body = text;
        message.time = new DateTime.now_utc();
        message.local_time = new DateTime.now_utc();
        message.direction = Entities.Message.DIRECTION_SENT;
        message.counterpart = conversation.counterpart;
        if (conversation.type_ in new Conversation.Type[]{Conversation.Type.GROUPCHAT, Conversation.Type.GROUPCHAT_PM}) {
            message.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            message.real_jid = conversation.account.bare_jid;
        } else {
            message.ourpart = conversation.account.bare_jid.with_resource(conversation.account.resourcepart);
        }
        message.marked = Entities.Message.Marked.UNSENT;
        message.encryption = conversation.encryption;
        return message;
    }

    public void send_xmpp_message(Entities.Message message, Conversation conversation, bool delayed = false) {
        lock (lock_send_unsent) {
            XmppStream stream = stream_interactor.get_stream(conversation.account);
            message.marked = Entities.Message.Marked.NONE;
            if (stream != null) {
                Xmpp.MessageStanza new_message = new Xmpp.MessageStanza(message.stanza_id);
                new_message.to = message.counterpart;
                new_message.body = message.body;
                if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    new_message.type_ = Xmpp.MessageStanza.TYPE_GROUPCHAT;
                } else {
                    new_message.type_ = Xmpp.MessageStanza.TYPE_CHAT;
                }
                build_message_stanza(message, new_message, conversation);
                pre_message_send(message, new_message, conversation);
                if (message.marked == Entities.Message.Marked.UNSENT || message.marked == Entities.Message.Marked.WONTSEND) return;
                if (delayed) {
                    Xmpp.Xep.DelayedDelivery.Module.set_message_delay(new_message, message.time);
                }
                stream.get_module(Xmpp.MessageModule.IDENTITY).send_message(stream, new_message);
                message.stanza_id = new_message.id;
                message.stanza = new_message;
            } else {
                message.marked = Entities.Message.Marked.UNSENT;
            }
        }
    }
}

}
