using Gee;

namespace Xmpp.Xep.InBandRegistration {

public const string NS_URI = "jabber:iq:register";

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0077_in_band_registration");

    public async Form? get_from_server(XmppStream stream, Jid jid) {
        Iq.Stanza request_form_iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI).add_self_xmlns());
        request_form_iq.to = jid;
        SourceFunc callback = get_from_server.callback;
        Form? form = null;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, request_form_iq, (stream, response_iq) => {
            form = new Form.from_node(stream, response_iq);
            Idle.add((owned)callback);
        });
        yield;
        return form;
    }

    public async string? submit_to_server(XmppStream stream, Jid jid, Form form) {
        StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns();
        query_node.put_node(form.get_submit_node());
        Iq.Stanza iq = new Iq.Stanza.set(query_node);
        iq.to = jid;
        string? error_message = null;
        SourceFunc callback = submit_to_server.callback;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, response_iq) => {
            if (response_iq.is_error()) {
                ErrorStanza? error_stanza = response_iq.get_error();
                error_message = error_stanza.text ?? "Error";
            }
            Idle.add((owned)callback);
        });
        yield;
        return error_message;
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
