namespace Xmpp.Xep.Bookmarks {

public class Conference : Object {

    public const string ATTRIBUTE_AUTOJOIN = "autojoin";
    public const string ATTRIBUTE_JID = "jid";
    public const string ATTRIBUTE_NAME = "name";

    public const string NODE_NICK = "nick";
    public const string NODE_PASSWORD = "password";

    public StanzaNode stanza_node;

    public bool autojoin {
        get {
            string? attr = stanza_node.get_attribute(ATTRIBUTE_AUTOJOIN);
            return attr == "true" || attr == "1";
        }
        set { stanza_node.set_attribute(ATTRIBUTE_AUTOJOIN, value.to_string()); }
    }

    private Jid jid_;
    public Jid jid {
        get { return jid_ ?? (jid_ = Jid.parse(stanza_node.get_attribute(ATTRIBUTE_JID))); }
        set { stanza_node.set_attribute(ATTRIBUTE_JID, value.to_string()); }
    }

    public string? name {
        get { return stanza_node.get_attribute(ATTRIBUTE_NAME); }
        set {
            if (value == null) return; // TODO actually remove
            stanza_node.set_attribute(ATTRIBUTE_NAME, value);
        }
    }

    public string? nick {
        get {
            StanzaNode? nick_node = stanza_node.get_subnode(NODE_NICK);
            return nick_node == null? null : nick_node.get_string_content();
        }
        set {
            StanzaNode? nick_node = stanza_node.get_subnode(NODE_NICK);
            if (value == null) {
                if (nick_node != null) stanza_node.sub_nodes.remove(nick_node);
                return;
            }
            if (nick_node == null) {
                nick_node = new StanzaNode.build(NODE_NICK, NS_URI);
                stanza_node.put_node(nick_node);
            }
            nick_node.sub_nodes.clear();
            nick_node.put_node(new StanzaNode.text(value));
        }
    }

    public string? password {
        get {
            StanzaNode? password_node = stanza_node.get_subnode(NODE_PASSWORD);
            return password_node == null? null : password_node.get_string_content();
        }
        set {
            StanzaNode? password_node = stanza_node.get_subnode(NODE_PASSWORD);
            if (value == null) {
                if (password_node != null) stanza_node.sub_nodes.remove(password_node);
                return;
            }
            if (password_node == null) {
                password_node = new StanzaNode.build(NODE_PASSWORD);
                stanza_node.put_node(password_node);
            }
            password_node.put_node(new StanzaNode.text(value));
        }
    }

    public Conference(Jid jid) {
        this.stanza_node = new StanzaNode.build("conference", NS_URI);
        this.jid = jid;
    }

    public static Conference? create_from_stanza_node(StanzaNode stanza_node) {
        if (stanza_node.get_attribute(ATTRIBUTE_JID) != null) {
            return new Conference.from_stanza_node(stanza_node);
        }
        return null;
    }

    private Conference.from_stanza_node(StanzaNode stanza_node) {
        this.stanza_node = stanza_node;
    }
}

}
