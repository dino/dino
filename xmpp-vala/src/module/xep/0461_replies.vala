namespace Xmpp.Xep.Replies {

    public const string NS_URI = "urn:xmpp:reply:0";

    public class ReplyTo {
        public Jid to_jid { get; set; }
        public string to_message_id { get; set; }

        public ReplyTo(Jid to_jid, string to_message_id) {
            this.to_jid = to_jid;
            this.to_message_id = to_message_id;
        }
    }

    public static void set_reply_to(MessageStanza message, ReplyTo reply_to) {
        StanzaNode reply_node = (new StanzaNode.build("reply", NS_URI))
                .add_self_xmlns()
                .put_attribute("to", reply_to.to_jid.to_string())
                .put_attribute("id", reply_to.to_message_id);
        message.stanza.put_node(reply_node);
    }

    public ReplyTo? get_reply_to(MessageStanza message) {
        StanzaNode? reply_node = message.stanza.get_subnode("reply", NS_URI);
        if (reply_node == null) return null;

        string? to_str = reply_node.get_attribute("to");
        if (to_str == null) return null;
        try {
            Jid to_jid = new Jid(to_str);

            string? id = reply_node.get_attribute("id");
            if (id == null) return null;

            return new ReplyTo(to_jid, id);
        } catch (InvalidJidError e) {
            return null;
        }
        return null;
    }
}