/* Legacy. RFC 3921 3*/
namespace Xmpp.Session {
private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-session";

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "session");

    public override void attach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.connect(on_bound_resource);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.disconnect(on_bound_resource);
    }

    public override bool mandatory_outstanding(XmppStream stream) { return false; }

    public override bool negotiation_active(XmppStream stream) {
        return stream.has_flag(Flag.IDENTITY) && !stream.get_flag(Flag.IDENTITY).finished;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private async void on_bound_resource(XmppStream stream, Jid my_jid) {
        StanzaNode? session_node = stream.features.get_subnode("session", NS_URI);
        if (session_node != null && session_node.get_subnode("optional", NS_URI) == null) {
            stream.add_flag(new Flag());
            Iq.Stanza iq = new Iq.Stanza.set(new StanzaNode.build("session", NS_URI).add_self_xmlns()) { to=stream.remote_name };

            Iq.Stanza result_iq = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
            if (!result_iq.is_error()) {
                stream.get_flag(Flag.IDENTITY).finished = true;
            }
        }
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "session");
    public bool finished = false;

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
