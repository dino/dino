using Gee;

namespace Xmpp.Xep.PrivateXmlStorage {
    private const string NS_URI = "jabber:iq:private";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0049_private_xml_storage");

        public delegate void OnSuccess(XmppStream stream);
        public void store(XmppStream stream, StanzaNode node, owned OnSuccess listener) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.set(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
                listener(stream);
            });
        }

        public delegate void OnResponse(XmppStream stream, StanzaNode? node);
        public void retrieve(XmppStream stream, StanzaNode node, owned OnResponse listener) {
            StanzaNode queryNode = new StanzaNode.build("query", NS_URI).add_self_xmlns().put_node(node);
            Iq.Stanza iq = new Iq.Stanza.get(queryNode);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
                listener(stream, iq.stanza.get_subnode("query", NS_URI));
            });
        }

        public override void attach(XmppStream stream) { }

        public override void detach(XmppStream stream) { }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
