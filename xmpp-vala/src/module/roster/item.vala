using Gee;

namespace Xmpp.Roster {

public class Item {

    public const string NODE_JID = "jid";
    public const string NODE_NAME = "name";
    public const string NODE_SUBSCRIPTION = "subscription";

    public const string SUBSCRIPTION_NONE = "none";
    public const string SUBSCRIPTION_TO = "to";
    public const string SUBSCRIPTION_FROM = "from";
    public const string SUBSCRIPTION_BOTH = "both";
    public const string SUBSCRIPTION_REMOVE = "remove";

    public StanzaNode stanza_node;

    private Jid jid_;
    public Jid jid {
        get { return jid_ ?? (jid_ = Jid.parse(stanza_node.get_attribute(NODE_JID))); }
        set { stanza_node.set_attribute(NODE_JID, value.to_string()); }
    }

    public string? name {
        get { return stanza_node.get_attribute(NODE_NAME); }
        set { if (value != null) stanza_node.set_attribute(NODE_NAME, value); }
    }

    public string? subscription {
        get { return stanza_node.get_attribute(NODE_SUBSCRIPTION); }
        set { if (value != null) stanza_node.set_attribute(NODE_SUBSCRIPTION, value); }
    }

    public Item() {
        stanza_node = new StanzaNode.build("item", NS_URI);
    }

    public Item.from_stanza_node(StanzaNode stanza_node) {
        this.stanza_node = stanza_node;
    }
}

}
