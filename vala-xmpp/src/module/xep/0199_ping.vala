using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Ping {
    private const string NS_URI = "urn:xmpp:ping";

    public class Module : XmppStreamModule {
        public const string ID = "0199_ping";

        public void send_ping(XmppStream stream, string jid, ResponseListener? listener = null) {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("ping", NS_URI).add_self_xmlns());
            iq.to = jid;
            Iq.Module.get_module(stream).send_iq(stream, iq, listener == null? null : new IqResponseListenerImpl(listener));
        }

        private class IqResponseListenerImpl : Iq.ResponseListener, Object {
            ResponseListener listener;
            public IqResponseListenerImpl(ResponseListener listener) {
                this.listener = listener;
            }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                listener.on_result(stream);
            }
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
            Iq.Module.get_module(stream).register_for_namespace(NS_URI, new IqHandlerImpl());
        }

        public override void detach(XmppStream stream) { }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private class IqHandlerImpl : Iq.Handler, Object {
            public void on_iq_get(XmppStream stream, Iq.Stanza iq) {
                Iq.Module.get_module(stream).send_iq(stream, new Iq.Stanza.result(iq));
            }
            public void on_iq_set(XmppStream stream, Iq.Stanza iq) { }
        }
    }

    public interface ResponseListener : Object {
        public abstract void on_result(XmppStream stream);
    }
}
