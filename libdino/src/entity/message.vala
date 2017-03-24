using Gee;

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
        HEADLINE,
        NORMAL
    }

    public int? id { get; set; }
    public Account account { get; set; }
    public Jid? counterpart { get; set; }
    public Jid? ourpart { get; set; }
    public Jid? from {
        get { return direction == DIRECTION_SENT ? account.bare_jid : counterpart; }
    }
    public Jid? to {
        get { return direction == DIRECTION_SENT ? counterpart : account.bare_jid; }
    }
    public bool direction { get; set; }
    public string? real_jid { get; set; }
    public Type type_ { get; set; }
    public string? body { get; set; }
    public string? stanza_id { get; set; }
    public DateTime? time { get; set; }
    /** UTC **/
    public DateTime? local_time { get; set; }
    public Encryption encryption { get; set; default = Encryption.NONE; }
    public Marked marked { get; set; default = Marked.NONE; }
    public Xmpp.Message.Stanza stanza { get; set; }

    private Database? db;

    public Message(string? body, Type type) {
        this.id = -1;
        this.body = body;
        this.type_ = type;
    }

    public Message.from_row(Database db, Qlite.Row row) {
        this.db = db;

        id = row[db.message.id];
        stanza_id = row[db.message.stanza_id];
        string from = db.get_jid_by_id(row[db.message.counterpart_id]);
        string from_resource = row[db.message.counterpart_resource];
        counterpart = from_resource != null ? new Jid(from + "/" + from_resource) : new Jid(from);
        direction = row[db.message.direction];
        type_ = (Message.Type) row[db.message.type_];
        time = new DateTime.from_unix_local(row[db.message.time]);
        local_time = new DateTime.from_unix_local(row[db.message.time]);
        body = row[db.message.body];
        account = db.get_account_by_id(row[db.message.account_id]); // TODO dont have to generate acc new
        marked = (Message.Marked) row[db.message.marked];
        encryption = (Encryption) row[db.message.encryption];
        real_jid = db.real_jid.select({db.real_jid.real_jid}).with(db.real_jid.message_id, "=", id)[db.real_jid.real_jid];

        notify.connect(on_update);
    }

    public void persist(Database db) {
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
        id = (int) builder.perform();

        if (real_jid != null) {
            db.real_jid.insert()
                .value(db.real_jid.message_id, id)
                .value(db.real_jid.real_jid, real_jid)
                .perform();
        }
        notify.connect(on_update);
    }

    public void set_type_string(string type) {
    switch (type) {
            case Xmpp.Message.Stanza.TYPE_CHAT:
                type_ = Type.CHAT; break;
            case Xmpp.Message.Stanza.TYPE_GROUPCHAT:
                type_ = Type.GROUPCHAT; break;
            default:
                type_ = Type.NORMAL; break;
        }
    }

    public new string get_type_string() {
    switch (type_) {
            case Type.CHAT:
                return Xmpp.Message.Stanza.TYPE_CHAT;
            case Type.GROUPCHAT:
                return Xmpp.Message.Stanza.TYPE_GROUPCHAT;
            default:
                return Xmpp.Message.Stanza.TYPE_NORMAL;
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
                .value(db.real_jid.real_jid, real_jid)
                .perform();
        }
    }
}

}