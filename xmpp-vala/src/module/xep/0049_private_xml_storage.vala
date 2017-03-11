using Xmpp.Core;

namespace Xmpp.Xep.PrivateXmlStorage {
    private const string NS_URI = "jabber:iq:private";

    public class Module : XmppStreamModule {
        public const string ID = "0049_private_xml_storage";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public void store(XmppStream stream, StanzaNode node, StoreResponseListener listener) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.set(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, new IqStoreResponse(listener));
        }

        private class IqStoreResponse : Iq.ResponseListener, Object {
            StoreResponseListener listener;
            public IqStoreResponse(StoreResponseListener listener) {
                this.listener = listener;
            }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                listener.on_success(stream);
            }
        }

        public void retrieve(XmppStream stream, StanzaNode node, RetrieveResponseListener responseListener) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.get(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, new IqRetrieveResponse(responseListener));
        }

        private class IqRetrieveResponse : Iq.ResponseListener, Object {
            RetrieveResponseListener response_listener;
            public IqRetrieveResponse(RetrieveResponseListener response_listener) { this.response_listener = response_listener; }

            public void on_result(XmppStream stream, Iq.Stanza iq) {
                response_listener.on_result(stream, iq.stanza.get_subnode("query", NS_URI));
            }
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
        }

        public override void detach(XmppStream stream) { }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new PrivateXmlStorage.Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

    public interface StoreResponseListener : Object {
        public abstract void on_success(XmppStream stream);
    }

    public interface RetrieveResponseListener : Object {
        public abstract void on_result(XmppStream stream, StanzaNode stanzaNode);
    }
}
