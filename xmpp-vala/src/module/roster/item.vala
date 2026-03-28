using Gee;

namespace Xmpp.Roster {

public class Item {

    public const string SUBSCRIPTION_NONE = "none";
    /** the user has a subscription to the contact's presence, but the contact does not have a subscription to the user's presence */
    public const string SUBSCRIPTION_TO = "to";
    /** the contact has a subscription to the user's presence, but the user does not have a subscription to the contact's presence */
    public const string SUBSCRIPTION_FROM = "from";
    public const string SUBSCRIPTION_BOTH = "both";
    public const string SUBSCRIPTION_REMOVE = "remove";

    public StanzaNode stanza_node;

    private Jid jid_;
    public Jid? jid {
        get {
            try {
                return jid_ ?? (jid_ = new Jid(stanza_node.get_attribute("jid")));
            } catch (InvalidJidError e) {
                warning("Ignoring invalid Jid in roster entry: %s", e.message);
                return null;
            }
        }
        set { stanza_node.set_attribute("jid", value.to_string()); }
    }

    public string? name {
        get { return stanza_node.get_attribute("name"); }
        set { if (value != null) stanza_node.set_attribute("name", value); }
    }

    public string? subscription {
        get { return stanza_node.get_attribute("subscription"); }
        set { if (value != null) stanza_node.set_attribute("subscription", value); }
    }

    public string? ask {
        get { return stanza_node.get_attribute("ask"); }
    }

    public bool subscription_requested {
        get { return this.ask != null; }
    }

    public Item() {
        stanza_node = new StanzaNode.build("item", NS_URI);
    }

    public Item.from_stanza_node(StanzaNode stanza_node) {
        this.stanza_node = stanza_node;
    }
}

}
