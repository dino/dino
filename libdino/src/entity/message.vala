using Gee;

using Xmpp;

public class Dino.Entities.Message : Object {

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
    public DateTime? local_time { get; set; }
    public Encryption encryption { get; set; default = Encryption.NONE; }
    public Marked marked { get; set; default = Marked.NONE; }
    public Xmpp.Message.Stanza stanza { get; set; }

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
}
