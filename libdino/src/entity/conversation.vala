using Xmpp;

namespace Dino.Entities {

public class Conversation : Object {

    public signal void object_updated(Conversation conversation);

    public enum Type {
        CHAT,
        GROUPCHAT,
        GROUPCHAT_PM;

        public bool is_muc_semantic() {
            return this == GROUPCHAT || this == GROUPCHAT_PM;
        }
    }

    public int id { get; set; }
    public Type type_ { get; set; }
    public Account account { get; private set; }
    public Jid counterpart { get; private set; }
    public string? nickname { get; set; }
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
    public Message? read_up_to { get; set; }
    public int read_up_to_item { get; set; default=-1; }

    public enum NotifySetting { DEFAULT, ON, OFF, HIGHLIGHT }
    public NotifySetting notify_setting { get; set; default = NotifySetting.DEFAULT; }

    public enum Setting { DEFAULT, ON, OFF }
    public Setting send_typing { get; set; default = Setting.DEFAULT; }

    public Setting send_marker { get; set; default = Setting.DEFAULT; }

    private Database? db;

    public Conversation(Jid jid, Account account, Type type) {
        this.account = account;
        this.counterpart = jid;
        this.type_ = type;
    }

    public Conversation.from_row(Database db, Qlite.Row row) throws InvalidJidError {
        this.db = db;

        id = row[db.conversation.id];
        type_ = (Conversation.Type) row[db.conversation.type_];
        account = db.get_account_by_id(row[db.conversation.account_id]);
        string? resource = row[db.conversation.resource];
        counterpart = db.get_jid_by_id(row[db.conversation.jid_id]);
        if (type_ == Conversation.Type.GROUPCHAT_PM) counterpart = counterpart.with_resource(resource);
        nickname = type_ == Conversation.Type.GROUPCHAT ? resource : null;
        active = row[db.conversation.active];
        int64? last_active = row[db.conversation.last_active];
        if (last_active != null) this.last_active = new DateTime.from_unix_utc(last_active);
        encryption = (Encryption) row[db.conversation.encryption];
        int? read_up_to = row[db.conversation.read_up_to];
        if (read_up_to != null) this.read_up_to = db.get_message_by_id(read_up_to);
        read_up_to_item = row[db.conversation.read_up_to_item];
        notify_setting = (NotifySetting) row[db.conversation.notification];
        send_typing = (Setting) row[db.conversation.send_typing];
        send_marker = (Setting) row[db.conversation.send_marker];

        notify.connect(on_update);
    }

    public void persist(Database db) {
        this.db = db;
        var insert = db.conversation.insert()
                .value(db.conversation.account_id, account.id)
                .value(db.conversation.jid_id, db.get_jid_id(counterpart))
                .value(db.conversation.type_, type_)
                .value(db.conversation.encryption, encryption)
                .value(db.conversation.active, active)
                .value(db.conversation.notification, notify_setting)
                .value(db.conversation.send_typing, send_typing)
                .value(db.conversation.send_marker, send_marker);
        if (read_up_to != null) {
            insert.value(db.conversation.read_up_to, read_up_to.id);
        }
        if (read_up_to_item != -1) {
            insert.value(db.conversation.read_up_to_item, read_up_to_item);
        }
        if (nickname != null) {
            insert.value(db.conversation.resource, nickname);
        }
        if (counterpart.is_full()) {
            insert.value(db.conversation.resource, counterpart.resourcepart);
        }
        if (last_active != null) {
            insert.value(db.conversation.last_active, (long) last_active.to_unix());
        }
        id = (int) insert.perform();
        notify.connect(on_update);
    }

    public NotifySetting get_notification_setting(StreamInteractor stream_interactor) {
        return notify_setting != NotifySetting.DEFAULT ? notify_setting : get_notification_default_setting(stream_interactor);
    }

    public NotifySetting get_notification_default_setting(StreamInteractor stream_interactor) {
        if (!Application.get_default().settings.notifications) return NotifySetting.OFF;

        if (type_ == Type.GROUPCHAT) {
            if (stream_interactor.get_module(MucManager.IDENTITY).is_private_room(this.account, this.counterpart)) {
                return NotifySetting.ON;
            } else {
                return NotifySetting.HIGHLIGHT;
            }
        }
        return NotifySetting.ON;
    }

    public Setting get_send_typing_setting(StreamInteractor stream_interactor) {
        if (send_typing != Setting.DEFAULT) return send_typing;

        if (stream_interactor.get_module(MucManager.IDENTITY).is_public_room(this.account, this.counterpart)) return Setting.OFF;

        return Application.get_default().settings.send_typing ? Setting.ON : Setting.OFF;
    }

    public Setting get_send_marker_setting(StreamInteractor stream_interactor) {
        if (send_marker != Setting.DEFAULT) return send_marker;

        if (stream_interactor.get_module(MucManager.IDENTITY).is_public_room(this.account, this.counterpart)) return Setting.OFF;

        return Application.get_default().settings.send_marker ? Setting.ON : Setting.OFF;
    }

    public bool equals(Conversation? conversation) {
        if (conversation == null) return false;
        return equals_func(this, conversation);
    }

    public static bool equals_func(Conversation conversation1, Conversation conversation2) {
        return conversation1.counterpart.equals(conversation2.counterpart) && conversation1.account.equals(conversation2.account) && conversation1.type_ == conversation2.type_;
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
            case "read-up-to-item":
                if (read_up_to_item != -1) {
                    update.set(db.conversation.read_up_to_item, read_up_to_item);
                } else {
                    update.set_null(db.conversation.read_up_to_item);
                }
                break;
            case "nickname":
                update.set(db.conversation.resource, nickname); break;
            case "active":
                update.set(db.conversation.active, active); break;
            case "last-active":
                if (last_active != null) {
                    update.set(db.conversation.last_active, (long) last_active.to_unix());
                } else {
                    update.set_null(db.conversation.last_active);
                }
                break;
            case "notify-setting":
                update.set(db.conversation.notification, notify_setting); break;
            case "send-typing":
                update.set(db.conversation.send_typing, send_typing); break;
            case "send-marker":
                update.set(db.conversation.send_marker, send_marker); break;
        }
        update.perform();
    }
}

}
