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
        message.persist(db);
        send_xmpp_message(message, conversation);
        message_sent(message, conversation);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.Message.Module.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received(account, message);
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
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(new_message);
        if (conversation != null) process_message(new_message, message);
    }

    private Entities.Message create_in_message(Account account, Xmpp.Message.Stanza message) {
        Entities.Message new_message = new Entities.Message(message.body);
        new_message.account = account;
        new_message.stanza_id = message.id;
        Jid from_jid = new Jid(message.from);
        if (!account.bare_jid.equals_bare(from_jid) ||
                stream_interactor.get_module(MucManager.IDENTITY).get_nick(from_jid.bare_jid, account) == from_jid.resourcepart) {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        } else {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        }
        new_message.counterpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.to) : new Jid(message.from);
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.from) : new Jid(message.to);
        new_message.stanza = message;
        Xep.DelayedDelivery.MessageFlag? deleyed_delivery_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        new_message.time = deleyed_delivery_flag != null ? deleyed_delivery_flag.datetime : new DateTime.now_local();
        new_message.local_time = new DateTime.now_local();
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
                if (new_message.direction == Entities.Message.DIRECTION_SENT) {
                    message_sent(new_message, conversation);
                } else {
                    message_received(new_message, conversation);
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
            } else {
                Core.XmppStream stream = stream_interactor.get_stream(account);
                if (stream != null) stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).get_entity_categories(stream, message.counterpart.bare_jid.to_string(), (stream, identities, store) => {
                    Triple<MessageProcessor, Entities.Message, Xmpp.Message.Stanza> triple = store as Triple<MessageProcessor, Entities.Message, Xmpp.Message.Stanza>;
                    Entities.Message m = triple.b;
                    if (identities == null) {
                        m.type_ = Entities.Message.Type.CHAT;
                        triple.a.process_message(m, triple.c);
                        return;
                    }
                    foreach (Xep.ServiceDiscovery.Identity identity in identities) {
                        if (identity.category == Xep.ServiceDiscovery.Identity.CATEGORY_CONFERENCE) {
                            m.type_ = Entities.Message.Type.GROUPCHAT_PM;
                        } else {
                            m.type_ = Entities.Message.Type.CHAT;
                        }
                        triple.a.process_message(m, triple.c);
                    }
                }, Triple.create(this, message, message_stanza));
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