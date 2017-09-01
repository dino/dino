using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Ping {
    private const string NS_URI = "urn:xmpp:ping";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0199_ping");

        public delegate void OnResult(XmppStream stream);
        public void send_ping(XmppStream stream, string jid, owned OnResult? listener) {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("ping", NS_URI).add_self_xmlns());
            iq.to = jid;
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream) => { listener(stream); });
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, new IqHandlerImpl());
        }

        public override void detach(XmppStream stream) { }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private class IqHandlerImpl : Iq.Handler, Object {
            public void on_iq_get(XmppStream stream, Iq.Stanza iq) {
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
            }
            public void on_iq_set(XmppStream stream, Iq.Stanza iq) { }
        }
    }
}
