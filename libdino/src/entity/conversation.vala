namespace Dino.Entities {
public class Conversation : Object {

    public signal void object_updated(Conversation conversation);

    public enum Encryption {
        UNENCRYPTED,
        PGP
    }

    public enum Type {
        CHAT,
        GROUPCHAT
    }

    public int id { get; set; }
    public Account account { get; private set; }
    public Jid counterpart { get; private set; }
    public bool active { get; set; }
    public DateTime last_active { get; set; }
    public Encryption encryption { get; set; }
    public Type? type_ { get; set; }
    public Message read_up_to { get; set; }

    public Conversation(Jid jid, Account account) {
        this.counterpart = jid;
        this.account = account;
        this.active = false;
        this.last_active = new DateTime.from_unix_utc(0);
        this.encryption = Encryption.UNENCRYPTED;
    }

    public Conversation.with_id(Jid jid, Account account, int id) {
        this.counterpart = jid;
        this.account = account;
        this.id = id;
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
}
}