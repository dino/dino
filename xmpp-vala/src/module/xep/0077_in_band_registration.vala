using Gee;

namespace Xmpp.Xep.InBandRegistration {

public const string NS_URI = "jabber:iq:register";

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0077_in_band_registration");

    public async Form? get_from_server(XmppStream stream, Jid jid) {
        StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns();
        Iq.Stanza request_form_iq = new Iq.Stanza.get(query_node) { to=jid };
        request_form_iq.to = jid;

        Iq.Stanza iq_result = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, request_form_iq);
        return new Form.from_node(stream, iq_result);
    }

    public async string? submit_to_server(XmppStream stream, Jid jid, Form form) {
        StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns();
        query_node.put_node(form.get_submit_node());
        Iq.Stanza iq = new Iq.Stanza.set(query_node) { to=jid };

        Iq.Stanza iq_result = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
        if (iq_result.is_error()) {
            ErrorStanza? error_stanza = iq_result.get_error();
            return error_stanza.text ?? "Error";
        }

        return null;
    }

    public override bool mandatory_outstanding(XmppStream stream) { return false; }

    public override bool negotiation_active(XmppStream stream) { return false; }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Form : DataForms.DataForm {
    public string? oob = null;

    internal Form.from_node(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? x_node = iq.stanza.get_deep_subnode(NS_URI + ":query", DataForms.NS_URI + ":x");
        base.from_node(x_node ?? new StanzaNode.build("x", NS_URI).add_self_xmlns());

        oob = iq.stanza.get_deep_string_content(NS_URI + ":query", "jabber:x:oob:x", "url");
    }
}

}
