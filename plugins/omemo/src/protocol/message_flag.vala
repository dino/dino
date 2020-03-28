using Xmpp;

namespace Dino.Plugins.Omemo {

public class MessageFlag : Xmpp.MessageFlag {
    public const string id = "omemo";

    public bool decrypted = false;

    public static MessageFlag? get_flag(MessageStanza message) {
        return (MessageFlag) message.get_flag(V1.NS_URI, id);
    }

    public override string get_ns() {
        return V1.NS_URI;
    }

    public override string get_id() {
        return id;
    }
}

}