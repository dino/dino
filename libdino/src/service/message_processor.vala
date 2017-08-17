using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class MessageProcessor : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageProcessor> IDENTITY = new ModuleIdentity<MessageProcessor>("message_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void pre_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation);
    public signal void message_received(Entities.Message message, Conversation conversation);
    public signal void out_message_created(Entities.Message message, Conversation conversation);
    public signal void pre_message_send(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation);
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

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.Message.Module.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received(account, message);
        });
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.MessageArchiveManagement.Module.IDENTITY).feature_available.connect( (stream) => {
            DateTime start_time = account.mam_earliest_synced.to_unix() > 60 ? account.mam_earliest_synced.add_minutes(-1) : account.mam_earliest_synced;
            stream.get_module(Xep.MessageArchiveManagement.Module.IDENTITY).query_archive(stream, null, start_time, null);
        });
    }

    private void send_unsent_messages(Account account) {
        Gee.List<Entities.Message> unsend_messages = db.get_unsend_messages(account);
        foreach (Entities.Message message in unsend_messages) {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart, account);
            if (conversation != null) {
                send_xmpp_message(message, conversation, true);
            }
        }
    }

    private void on_message_received(Account account, Xmpp.Message.Stanza message) {
        if (message.body == null) return;

        Entities.Message new_message = create_in_message(account, message);

        determine_message_type(account, message, new_message);
    }

    private Entities.Message create_in_message(Account account, Xmpp.Message.Stanza message) {
        Entities.Message new_message = new Entities.Message(message.body);
        new_message.account = account;
        new_message.stanza_id = message.id;
        Jid from_jid = new Jid(message.from);
        if (!account.bare_jid.equals_bare(from_jid) ||
                from_jid.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(from_jid.bare_jid, account))) {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        } else {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        }
        new_message.counterpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.to) : new Jid(message.from);
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.from) : new Jid(message.to);
        new_message.stanza = message;

        Xep.MessageArchiveManagement.MessageFlag? mam_message_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
        if (mam_message_flag != null) new_message.local_time = mam_message_flag.server_time;
        if (new_message.local_time == null || new_message.local_time.compare(new DateTime.now_local()) > 0) new_message.local_time = new DateTime.now_local();

        Xep.DelayedDelivery.MessageFlag? delayed_message_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        if (delayed_message_flag != null) new_message.time = delayed_message_flag.datetime;
        if (new_message.time == null || new_message.time.compare(new_message.local_time) > 0) new_message.time = new_message.local_time;

        return new_message;
    }

    private void process_message(Entities.Message new_message, Xmpp.Message.Stanza stanza) {
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(new_message);
        if (conversation != null) {
            pre_message_received(new_message, stanza, conversation);

            bool is_uuid = new_message.stanza_id != null && Regex.match_simple("""[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}""", new_message.stanza_id);
            if ((is_uuid && !db.contains_message_by_stanza_id(new_message.stanza_id, conversation.account)) ||
                    (!is_uuid && !db.contains_message(new_message, conversation.account))) {
                stream_interactor.get_module(MessageStorage.IDENTITY).add_message(new_message, conversation);

                bool is_mam_message = Xep.MessageArchiveManagement.MessageFlag.get_flag(stanza) != null;
                bool is_recent = new_message.local_time.compare(new DateTime.now_utc().add_hours(-24)) > 0;
                if (!is_mam_message || is_recent) {
                    print(new_message.local_time.to_string() + "\n");
                    if (new_message.direction == Entities.Message.DIRECTION_SENT) {
                        message_sent(new_message, conversation);
                    } else {
                        message_received(new_message, conversation);
                    }
                }

                Core.XmppStream? stream = stream_interactor.get_stream(conversation.account);
                Xep.MessageArchiveManagement.Flag? mam_flag = stream != null ? stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) : null;
                if (is_mam_message || (mam_flag != null && mam_flag.cought_up == true)) {
                    conversation.account.mam_earliest_synced = new_message.local_time;
                }
            }
        }
    }

    private void determine_message_type(Account account, Xmpp.Message.Stanza message_stanza, Entities.Message message) {
        if (message_stanza.type_ == Xmpp.Message.Stanza.TYPE_GROUPCHAT) {
            message.type_ = Entities.Message.Type.GROUPCHAT;
            process_message(message, message_stanza);
        } else if (message_stanza.type_ == Xmpp.Message.Stanza.TYPE_CHAT) {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart.bare_jid, account);
            if (conversation != null) {
                if (conversation.type_ == Conversation.Type.CHAT) {
                    message.type_ = Entities.Message.Type.CHAT;
                } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    message.type_ = Entities.Message.Type.GROUPCHAT_PM;
                }
                process_message(message, message_stanza);
            } else {
                Core.XmppStream stream = stream_interactor.get_stream(account);
                if (stream != null) stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).get_entity_categories(stream, message.counterpart.bare_jid.to_string(), (stream, identities) => {
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
        message.time = new DateTime.now_local();
        message.local_time = new DateTime.now_local();
        message.direction = Entities.Message.DIRECTION_SENT;
        message.counterpart = conversation.counterpart;
        message.ourpart = new Jid(conversation.account.bare_jid.to_string() + "/" + conversation.account.resourcepart);
        message.marked = Entities.Message.Marked.UNSENT;
        message.encryption = conversation.encryption;

        out_message_created(message, conversation);
        return message;
    }

    public void send_xmpp_message(Entities.Message message, Conversation conversation, bool delayed = false) {
        lock (lock_send_unsent) {
            Core.XmppStream stream = stream_interactor.get_stream(conversation.account);
            message.marked = Entities.Message.Marked.NONE;
            if (stream != null) {
                Xmpp.Message.Stanza new_message = new Xmpp.Message.Stanza(message.stanza_id);
                new_message.to = message.counterpart.to_string();
                new_message.body = message.body;
                if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    new_message.type_ = Xmpp.Message.Stanza.TYPE_GROUPCHAT;
                } else {
                    new_message.type_ = Xmpp.Message.Stanza.TYPE_CHAT;
                }
                pre_message_send(message, new_message, conversation);
                if (message.marked == Entities.Message.Marked.UNSENT || message.marked == Entities.Message.Marked.WONTSEND) return;
                if (delayed) {
                    Xmpp.Xep.DelayedDelivery.Module.set_message_delay(new_message, message.time);
                }
                stream.get_module(Xmpp.Message.Module.IDENTITY).send_message(stream, new_message);
                message.stanza_id = new_message.id;
                message.stanza = new_message;
            } else {
                message.marked = Entities.Message.Marked.UNSENT;
            }
        }
    }
}

}
