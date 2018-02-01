namespace Xmpp.Presence {

public class Stanza : Xmpp.Stanza {

    public const string NODE_PRIORITY = "priority";
    public const string NODE_STATUS = "status";
    public const string NODE_SHOW = "show";

    public const string SHOW_ONLINE = "online";
    public const string SHOW_AWAY = "away";
    public const string SHOW_CHAT = "chat";
    public const string SHOW_DND = "dnd";
    public const string SHOW_XA = "xa";

    public const string TYPE_AVAILABLE = "available";
    public const string TYPE_PROBE = "probe";
    public const string TYPE_SUBSCRIBE = "subscribe";
    public const string TYPE_SUBSCRIBED = "subscribed";
    public const string TYPE_UNAVAILABLE = "unavailable";
    public const string TYPE_UNSUBSCRIBE = "unsubscribe";
    public const string TYPE_UNSUBSCRIBED = "unsubscribed";

    public int priority {
        get {
            StanzaNode? priority_node = stanza.get_subnode(NODE_PRIORITY);
            if (priority_node == null) {
                return 0;
            } else {
                return int.parse(priority_node.get_string_content());
            }
        }
        set {
            StanzaNode? priority_node = stanza.get_subnode(NODE_PRIORITY);
            if (priority_node == null) {
                priority_node = new StanzaNode.build(NODE_PRIORITY);
                stanza.put_node(priority_node);
            }
            priority_node.val = value.to_string();
        }
    }

    public string? status {
        get {
            StanzaNode? status_node = stanza.get_subnode(NODE_STATUS);
            return status_node != null ? status_node.get_string_content() : null;
        }
        set {
            StanzaNode? status_node = stanza.get_subnode(NODE_STATUS);
            if (status_node == null) {
                status_node = new StanzaNode.build(NODE_STATUS);
                stanza.put_node(status_node);
            }
            status_node.val = value;
        }
    }

    public string show {
        get {
            StanzaNode? show_node = stanza.get_subnode(NODE_SHOW);
            return show_node != null ? show_node.get_string_content() : SHOW_ONLINE;
        }
        set {
            if (value != SHOW_ONLINE) {
                StanzaNode? show_node = stanza.get_subnode(NODE_SHOW);
                if (show_node == null) {
                    show_node = new StanzaNode.build(NODE_SHOW);
                    stanza.put_node(show_node);
                }
                show_node.val = value;
            }
        }
    }

    public override string? type_ {
        get {
            return base.type_ ?? TYPE_AVAILABLE;
        }
        set { base.type_ = value; }
    }

    public Stanza(string? id = null) {
        stanza = new StanzaNode.build("presence");
        this.id = id ?? random_uuid();
    }

    public Stanza.from_stanza(StanzaNode stanza_node, Jid my_jid) {
        base.incoming(stanza_node, my_jid);
    }
}

}
