using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.PrivateXmlStorage {
    private const string NS_URI = "jabber:iq:private";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0049_private_xml_storage");

        [CCode (has_target = false)] public delegate void OnSuccess(XmppStream stream, Object? reference);
        public void store(XmppStream stream, StanzaNode node, OnSuccess listener, Object? reference) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.set(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, on_store_response, Tuple.create(listener, reference));
        }

        [CCode (has_target = false)] public delegate void OnResponse(XmppStream stream, StanzaNode node, Object? reference);
        public void retrieve(XmppStream stream, StanzaNode node, OnResponse listener, Object? reference) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.get(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, on_retrieve_response, Tuple.create(listener, reference));
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
        }

        public override void detach(XmppStream stream) { }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new PrivateXmlStorage.Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private static void on_store_response(XmppStream stream, Iq.Stanza iq, Object? o) {
            Tuple<OnSuccess, Object> tuple = o as Tuple<OnSuccess, Object>;
            tuple.a(stream, tuple.b);
        }

        private static void on_retrieve_response(XmppStream stream, Iq.Stanza iq, Object? o) {
            Tuple<OnResponse, Object> tuple = o as Tuple<OnResponse, Object>;
            tuple.a(stream, iq.stanza.get_subnode("query", NS_URI), tuple.b);
        }
    }
}
