namespace Xmpp.Xep.MessageRetraction {

    public const string NS_URI = "urn:xmpp:message-retract:1";

    public static string? get_retract_id(MessageStanza message) {
        StanzaNode? retract_node = message.stanza.get_subnode("retract", NS_URI);
        if (retract_node == null) return null;

        return retract_node.get_attribute("id");
    }

    public static void set_retract_id(MessageStanza message, string message_id) {
        StanzaNode retract_node = (new StanzaNode.build("retract", NS_URI))
                .add_self_xmlns()
                .put_attribute("id", message_id);
        message.stanza.put_node(retract_node);
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0424_message_retraction");

        public override void attach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }

        public override string get_ns() { return NS_URI; }

        public override string get_id() { return IDENTITY.id; }
    }
}