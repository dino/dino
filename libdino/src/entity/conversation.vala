namespace Dino.Entities {

public class Conversation : Object {

    public signal void object_updated(Conversation conversation);

    public enum Type {
        CHAT,
        GROUPCHAT,
        GROUPCHAT_PM
    }

    public int id { get; set; }
    public Account account { get; private set; }
    public Jid counterpart { get; private set; }
    public bool active { get; set; default = false; }
    private DateTime? _last_active;
    public DateTime? last_active {
        get { return _last_active; }
        set {
            if (_last_active == null ||
                    (value != null && value.difference(_last_active) > 0)) {
                _last_active = value;
            }
        }
    }
    public Encryption encryption { get; set; default = Encryption.NONE; }
    public Type type_ { get; set; }
    public Message read_up_to { get; set; }

    private Database? db;

    public Conversation(Jid jid, Account account, Type type) {
        this.account = account;
        this.counterpart = jid;
        this.type_ = type;
    }

    public Conversation.from_row(Database db, Qlite.Row row) {
        this.db = db;

        id = row[db.conversation.id];
        account = db.get_account_by_id(row[db.conversation.account_id]);
        string? resource = row[db.conversation.resource];
        string jid = db.get_jid_by_id(row[db.conversation.jid_id]);
        counterpart = resource != null ? new Jid.with_resource(jid, resource) : new Jid(jid);
        active = row[db.conversation.active];
        int64? last_active = row[db.conversation.last_active];
        if (last_active != null) this.last_active = new DateTime.from_unix_local(last_active);
        type_ = (Conversation.Type) row[db.conversation.type_];
        encryption = (Encryption) row[db.conversation.encryption];
        int? read_up_to = row[db.conversation.read_up_to];
        if (read_up_to != null) this.read_up_to = db.get_message_by_id(read_up_to);

        notify.connect(on_update);
    }

    public void persist(Database db) {
        this.db = db;
        var insert = db.conversation.insert()
                .value(db.conversation.account_id, account.id)
                .value(db.conversation.jid_id, db.get_jid_id(counterpart))
                .value(db.conversation.type_, type_)
                .value(db.conversation.encryption, encryption)
                //.value(conversation.read_up_to, new_conversation.read_up_to)
                .value(db.conversation.active, active);
        if (counterpart.is_full()) {
            insert.value(db.conversation.resource, counterpart.resourcepart);
        }
        if (last_active != null) {
            insert.value(db.conversation.last_active, (long) last_active.to_unix());
        }
        id = (int) insert.perform();
        notify.connect(on_update);
    }

    public bool equals(Conversation? conversation) {
        if (conversation == null) return false;
        return equals_func(this, conversation);
    }

    public static bool equals_func(Conversation conversation1, Conversation conversation2) {
        return conversation1.counterpart.equals(conversation2.counterpart) && conversation1.account.equals(conversation2.account);
    }

    public static uint hash_func(Conversation conversation) {
        return conversation.counterpart.to_string().hash() ^ conversation.account.bare_jid.to_string().hash();
    }

    private void on_update(Object o, ParamSpec sp) {
        var update = db.conversation.update().with(db.conversation.id, "=", id);
        switch (sp.name) {
            case "type-":
                update.set(db.conversation.type_, type_); break;
            case "encryption":
                update.set(db.conversation.encryption, encryption); break;
            case "read-up-to":
                if (read_up_to != null) {
                    update.set(db.conversation.read_up_to, read_up_to.id);
                } else {
                    update.set_null(db.conversation.read_up_to);
                }
                break;
            case "active":
                update.set(db.conversation.active, active); break;
            case "last-active":
                if (last_active != null) {
                    update.set(db.conversation.last_active, (long) last_active.to_unix());
                } else {
                    update.set_null(db.conversation.last_active);
                }
                break;
        }
        update.perform();
    }
}

}