using Gee;

namespace Xmpp.Iq {

public class Stanza : Xmpp.Stanza {

    public const string TYPE_GET = "get";
    public const string TYPE_RESULT = "result";
    public const string TYPE_SET = "set";

    private Stanza(string? id = null) {
        base.outgoing(new StanzaNode.build("iq"));
        this.id = id ?? random_uuid();
    }

    public Stanza.get(StanzaNode stanza_node, string? id = null) {
        this(id);
        this.type_ = TYPE_GET;
        stanza.put_node(stanza_node);
    }

    public Stanza.result(Stanza request, StanzaNode? stanza_node = null) {
        this(request.id);
        this.to = request.from;
        this.type_ = TYPE_RESULT;
        if (stanza_node != null) {
            stanza.put_node(stanza_node);
        }
    }

    public Stanza.set(StanzaNode stanza_node, string? id = null) {
        this(id);
        this.type_ = TYPE_SET;
        stanza.put_node(stanza_node);
    }

    public Stanza.error(Stanza request, ErrorStanza error_stanza) {
        this(request.id);
        this.type_ = TYPE_ERROR;
        stanza.put_node(error_stanza.error_node);
    }
    public Stanza.from_stanza(StanzaNode stanza_node, Jid? my_jid) {
        base.incoming(stanza_node, my_jid);
    }
}

}
