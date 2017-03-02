using Xmpp.Core;

namespace Xmpp.Xep.Bookmarks {

public class Conference {

    public const string ATTRIBUTE_AUTOJOIN = "autojoin";
    public const string ATTRIBUTE_JID = "jid";
    public const string ATTRIBUTE_NAME = "name";

    public const string NODE_NICK = "nick";
    public const string NODE_PASSWORD = "password";

    public StanzaNode stanza_node;

    public bool autojoin {
        get {
            string? attr = stanza_node.get_attribute(ATTRIBUTE_AUTOJOIN);
            return attr == "true" || attr == "1"; // "1" isn't standard, but it's used
        }
        set { stanza_node.set_attribute(ATTRIBUTE_AUTOJOIN, value.to_string()); }
    }

    public string jid {
        get { return stanza_node.get_attribute(ATTRIBUTE_JID); }
        set { stanza_node.set_attribute(ATTRIBUTE_JID, value); }
    }

    public string? name {
        get { return stanza_node.get_attribute(ATTRIBUTE_NAME); }
        set { stanza_node.set_attribute(ATTRIBUTE_NAME, value); }
    }

    public string? nick {
        get {
            StanzaNode? nick_node = stanza_node.get_subnode(NODE_NICK);
            return nick_node == null? null : nick_node.get_string_content();
        }
        set {
            StanzaNode? nick_node = stanza_node.get_subnode(NODE_NICK);
            if (nick_node == null) {
                nick_node = new StanzaNode.build(NODE_NICK, NS_URI);
                stanza_node.put_node(nick_node);
            }
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
            if (password_node == null) {
                password_node = new StanzaNode.build(NODE_PASSWORD);
                stanza_node.put_node(password_node);
            }
            password_node.put_node(new StanzaNode.text(value));
        }
    }

    public Conference.from_stanza_node(StanzaNode stanza_node) {
        this.stanza_node = stanza_node;
    }

    public Conference(string jid) {
        this.stanza_node = new StanzaNode.build("conference", NS_URI);
        this.jid = jid;
    }
}

}