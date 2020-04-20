using Gee;
using Xmpp;

namespace Dino.Entities {

public class Message : Object {

    public const bool DIRECTION_SENT = true;
    public const bool DIRECTION_RECEIVED = false;

    public enum Marked {
        NONE,
        RECEIVED,
        READ,
        ACKNOWLEDGED,
        UNSENT,
        WONTSEND
    }

    public enum Type {
        ERROR,
        CHAT,
        GROUPCHAT,
        GROUPCHAT_PM,
        UNKNOWN;

        public bool is_muc_semantic() {
            return this == GROUPCHAT || this == GROUPCHAT_PM;
        }
    }

    public int id { get; set; default = -1; }
    public Account account { get; set; }
    public Jid? counterpart { get; set; }
    public Jid? ourpart { get; set; }
    public Jid? from {
        get { return direction == DIRECTION_SENT ? ourpart : counterpart; }
    }
    public Jid? to {
        get { return direction == DIRECTION_SENT ? counterpart : ourpart; }
    }
    public bool direction { get; set; }
    public Jid? real_jid { get; set; }
    public Type type_ { get; set; default = Type.UNKNOWN; }
    public string? body { get; set; }
    public string? stanza_id { get; set; }
    public string? server_id { get; set; }
    public DateTime? time { get; set; }
    /** UTC **/
    public DateTime? local_time { get; set; }
    public Encryption encryption { get; set; default = Encryption.NONE; }
    private Marked marked_ = Marked.NONE;
    public Marked marked {
        get { return marked_; }
        set {
            if (value == Marked.RECEIVED && marked == Marked.READ) return;
            marked_ = value;
        }
    }
    public string? edit_to = null;

    private Database? db;

    public Message(string? body) {
        this.body = body;
    }

    public Message.from_row(Database db, Qlite.Row row) throws InvalidJidError {
        this.db = db;

        id = row[db.message.id];
        account = db.get_account_by_id(row[db.message.account_id]);
        stanza_id = row[db.message.stanza_id];
        server_id = row[db.message.server_id];
        type_ = (Message.Type) row[db.message.type_];

        counterpart = db.get_jid_by_id(row[db.message.counterpart_id]);
        string counterpart_resource = row[db.message.counterpart_resource];
        if (counterpart_resource != null) counterpart = counterpart.with_resource(counterpart_resource);

        string our_resource = row[db.message.our_resource];
        if (type_.is_muc_semantic() && our_resource != null) {
            ourpart = counterpart.with_resource(our_resource);
        } else if (our_resource != null) {
            ourpart = account.bare_jid.with_resource(our_resource);
        } else {
            ourpart = account.bare_jid;
        }
        direction = row[db.message.direction];
        time = new DateTime.from_unix_utc(row[db.message.time]);
        local_time = new DateTime.from_unix_utc(row[db.message.local_time]);
        body = row[db.message.body];
        marked = (Message.Marked) row[db.message.marked];
        encryption = (Encryption) row[db.message.encryption];
        string? real_jid_str = row[db.real_jid.real_jid];
        if (real_jid_str != null) real_jid = new Jid(real_jid_str);

        edit_to = row[db.message_correction.to_stanza_id];

        notify.connect(on_update);
    }

    public void persist(Database db) {
        if (id != -1) return;

        this.db = db;
        Qlite.InsertBuilder builder = db.message.insert()
            .value(db.message.account_id, account.id)
            .value(db.message.counterpart_id, db.get_jid_id(counterpart))
            .value(db.message.counterpart_resource, counterpart.resourcepart)
            .value(db.message.our_resource, ourpart.resourcepart)
            .value(db.message.direction, direction)
            .value(db.message.type_, type_)
            .value(db.message.time, (long) time.to_unix())
            .value(db.message.local_time, (long) local_time.to_unix())
            .value(db.message.body, body)
            .value(db.message.encryption, encryption)
            .value(db.message.marked, marked);
        if (stanza_id != null) builder.value(db.message.stanza_id, stanza_id);
        if (server_id != null) builder.value(db.message.server_id, server_id);
        id = (int) builder.perform();

        if (real_jid != null) {
            db.real_jid.insert()
                .value(db.real_jid.message_id, id)
                .value(db.real_jid.real_jid, real_jid.to_string())
                .perform();
        }
        notify.connect(on_update);
    }

    public void set_type_string(string type) {
    switch (type) {
            case Xmpp.MessageStanza.TYPE_CHAT:
                type_ = Type.CHAT; break;
            case Xmpp.MessageStanza.TYPE_GROUPCHAT:
                type_ = Type.GROUPCHAT; break;
        }
    }

    public new string get_type_string() {
    switch (type_) {
            case Type.CHAT:
                return Xmpp.MessageStanza.TYPE_CHAT;
            case Type.GROUPCHAT:
                return Xmpp.MessageStanza.TYPE_GROUPCHAT;
            default:
                return Xmpp.MessageStanza.TYPE_NORMAL;
        }
    }

    public bool equals(Message? m) {
        if (m == null) return false;
        return equals_func(this, m);
    }

    public static bool equals_func(Message m1, Message m2) {
        if (m1.stanza_id == m2.stanza_id &&
                m1.body == m2.body) {
            return true;
        }
        return false;
    }

    public static uint hash_func(Message message) {
        return message.body.hash();
    }

    private void on_update(Object o, ParamSpec sp) {
        Qlite.UpdateBuilder update_builder = db.message.update().with(db.message.id, "=", id);
        switch (sp.name) {
            case "stanza-id":
                update_builder.set(db.message.stanza_id, stanza_id); break;
            case "server-id":
                update_builder.set(db.message.server_id, server_id); break;
            case "counterpart":
                update_builder.set(db.message.counterpart_id, db.get_jid_id(counterpart));
                update_builder.set(db.message.counterpart_resource, counterpart.resourcepart); break;
            case "ourpart":
                update_builder.set(db.message.our_resource, ourpart.resourcepart); break;
            case "direction":
                update_builder.set(db.message.direction, direction); break;
            case "type-":
                update_builder.set(db.message.type_, type_); break;
            case "time":
                update_builder.set(db.message.time, (long) time.to_unix()); break;
            case "local-time":
                update_builder.set(db.message.local_time, (long) local_time.to_unix()); break;
            case "body":
                update_builder.set(db.message.body, body); break;
            case "encryption":
                update_builder.set(db.message.encryption, encryption); break;
            case "marked":
                update_builder.set(db.message.marked, marked); break;
        }
        update_builder.perform();

        if (sp.get_name() == "real-jid") {
            db.real_jid.insert().or("REPLACE")
                .value(db.real_jid.message_id, id)
                .value(db.real_jid.real_jid, real_jid.to_string())
                .perform();
        }
    }
}

}
