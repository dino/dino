using Gee;

using Xmpp.Core;

namespace Xmpp.Message {

public class Stanza : Xmpp.Stanza {
    public const string NODE_BODY = "body";
    public const string NODE_SUBJECT = "subject";
    public const string NODE_THREAD = "thread";

    public const string TYPE_CHAT = "chat";
    public const string TYPE_GROUPCHAT = "groupchat";
    public const string TYPE_HEADLINE = "headline";
    public const string TYPE_NORMAL = "normal";

    public bool rerun_parsing = false;
    private ArrayList<MessageFlag> flags = new ArrayList<MessageFlag>();

    public string body {
        get {
            StanzaNode? body_node = stanza.get_subnode(NODE_BODY);
            return body_node == null? null : body_node.get_string_content();
        }
        set {
            StanzaNode? body_node = stanza.get_subnode(NODE_BODY);
            if (body_node == null) {
                body_node = new StanzaNode.build(NODE_BODY);
                stanza.put_node(body_node);
            }
            body_node.sub_nodes.clear();
            body_node.put_node(new StanzaNode.text(value));
        }
    }

    public Stanza(string id = UUID.generate_random_unparsed()) {
        base.outgoing(new StanzaNode.build("message"));
        stanza.set_attribute(ATTRIBUTE_ID, id);
    }

    public Stanza.from_stanza(StanzaNode stanza_node, string my_jid) {
        base.incoming(stanza_node, my_jid);
    }

    public void add_flag(MessageFlag flag) {
        flags.add(flag);
    }

    public MessageFlag? get_flag(string ns, string id) {
        foreach (MessageFlag flag in flags) {
            if (flag.get_ns() == ns && flag.get_id() == id) return flag;
        }
        return null;
    }
}

public abstract class MessageFlag : Object {
    public abstract string get_ns();

    public abstract string get_id();
}

}