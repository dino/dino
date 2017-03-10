using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class MessageManager : StreamInteractionModule, Object {
    public const string ID = "message_manager";

    public signal void pre_message_received(Entities.Message message, Conversation conversation);
    public signal void message_received(Entities.Message message, Conversation conversation);
    public signal void message_sent(Entities.Message message, Conversation conversation);

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Conversation, ArrayList<Entities.Message>> messages = new HashMap<Conversation, ArrayList<Entities.Message>>(Conversation.hash_func, Conversation.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageManager m = new MessageManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private MessageManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            if (state == ConnectionManager.ConnectionState.CONNECTED) send_unsent_messages(account);
        });
    }

    public void send_message(string text, Conversation conversation) {
        Entities.Message message = create_out_message(text, conversation);
        add_message(message, conversation);
        db.add_message(message, conversation.account);
        send_xmpp_message(message, conversation);
        message_sent(message, conversation);
    }

    public Gee.List<Entities.Message>? get_messages(Conversation conversation) {
        if (messages.has_key(conversation) && messages[conversation].size > 0) {
            Gee.List<Entities.Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, 50, messages[conversation][0]);
            db_messages.add_all(messages[conversation]);
            return db_messages;
        } else {
            Gee.List<Entities.Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, 50, null);
            return db_messages;
        }
    }

    public Entities.Message? get_last_message(Conversation conversation) {
        if (messages.has_key(conversation) && messages[conversation].size > 0) {
            return messages[conversation][messages[conversation].size - 1];
        } else {
            Gee.List<Entities.Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, 1, null);
            if (db_messages.size >= 1) {
                return db_messages[0];
            }
        }
        return null;
    }

    public Gee.List<Entities.Message>? get_messages_before(Conversation? conversation, Entities.Message before) {
        Gee.List<Entities.Message> db_messages = db.get_messages(conversation.counterpart, conversation.account, 20, before);
        return db_messages;
    }

    public string get_id() {
        return ID;
    }

    public static MessageManager? get_instance(StreamInteractor stream_interactor) {
        return (MessageManager) stream_interactor.get_module(ID);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.Message.Module.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received(account, message);
        });
        stream_interactor.stream_negotiated.connect(send_unsent_messages);
    }

    private void send_unsent_messages(Account account) {
        Gee.List<Entities.Message> unsend_messages = db.get_unsend_messages(account);
        foreach (Entities.Message message in unsend_messages) {
            Conversation conversation = ConversationManager.get_instance(stream_interactor).get_conversation(message.counterpart, account);
            send_xmpp_message(message, conversation, true);
        }
    }

    private void on_message_received(Account account, Xmpp.Message.Stanza message) {
        if (message.body == null) return;

        Entities.Message new_message = new Entities.Message();
        new_message.account = account;
        new_message.stanza_id = message.id;
        Jid from_jid = new Jid(message.from);
        if (!account.bare_jid.equals_bare(from_jid) ||
                MucManager.get_instance(stream_interactor).get_nick(from_jid.bare_jid, account) == from_jid.resourcepart) {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        } else {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        }
        new_message.counterpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.to) : new Jid(message.from);
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? new Jid(message.from) : new Jid(message.to);
        new_message.body = message.body;
        new_message.stanza = message;
        new_message.set_type_string(message.type_);
        Xep.DelayedDelivery.MessageFlag? deleyed_delivery_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        new_message.time = deleyed_delivery_flag != null ? deleyed_delivery_flag.datetime : new DateTime.now_utc();
        new_message.local_time = new DateTime.now_utc();
        if (Xep.Pgp.MessageFlag.get_flag(message) != null) {
            new_message.encryption = Entities.Message.Encryption.PGP;
        }
        Conversation conversation = ConversationManager.get_instance(stream_interactor).get_add_conversation(new_message.counterpart, account);
        pre_message_received(new_message, conversation);

        bool is_uuid = new_message.stanza_id != null && Regex.match_simple("""[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}""", new_message.stanza_id);
        if ((is_uuid && !db.contains_message_by_stanza_id(new_message.stanza_id)) ||
            (!is_uuid && !db.contains_message(new_message, conversation.account))) {
            db.add_message(new_message, conversation.account);
            add_message(new_message, conversation);
            if (new_message.time.difference(conversation.last_active) > 0) {
                conversation.last_active = new_message.time;
            }
            if (new_message.direction == Entities.Message.DIRECTION_SENT) {
                message_sent(new_message, conversation);
            } else {
                message_received(new_message, conversation);
            }
        }
    }

    private void add_message(Entities.Message message, Conversation conversation) {
        if (!messages.has_key(conversation)) {
            messages[conversation] = new ArrayList<Entities.Message>(Entities.Message.equals_func);
        }
        messages[conversation].add(message);
    }

    private Entities.Message create_out_message(string text, Conversation conversation) {
        Entities.Message message = new Entities.Message();
        message.stanza_id = random_uuid();
        message.account = conversation.account;
        message.body = text;
        message.time = new DateTime.now_utc();
        message.local_time = new DateTime.now_utc();
        message.direction = Entities.Message.DIRECTION_SENT;
        message.counterpart = conversation.counterpart;
        message.ourpart = new Jid(conversation.account.bare_jid.to_string() + "/" + conversation.account.resourcepart);

        if (conversation.encryption == Conversation.Encryption.PGP) {
            message.encryption = Entities.Message.Encryption.PGP;
        }
        return message;
    }

    private void send_xmpp_message(Entities.Message message, Conversation conversation, bool delayed = false) {
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
            if (message.encryption == Entities.Message.Encryption.PGP) {
                string? key_id = PgpManager.get_instance(stream_interactor).get_key_id(conversation.account, message.counterpart);
                if (key_id != null) {
                    bool encrypted = Xep.Pgp.Module.get_module(stream).encrypt(new_message, key_id);
                    if (!encrypted) {
                        message.marked = Entities.Message.Marked.WONTSEND;
                        return;
                    }
                }
            }
            if (delayed) {
                Xmpp.Xep.DelayedDelivery.Module.get_module(stream).set_message_delay(new_message, message.time);
            }
            Xmpp.Message.Module.get_module(stream).send_message(stream, new_message);
            message.stanza_id = new_message.id;
            message.stanza = new_message;
        } else {
            message.marked = Entities.Message.Marked.UNSENT;
        }
    }
}

}