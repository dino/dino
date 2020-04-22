namespace Xmpp.Xep.LastMessageCorrection {

private const string NS_URI = "urn:xmpp:message-correct:0";

public static void set_replace_id(MessageStanza message, string replace_id) {
    StanzaNode hint_node = (new StanzaNode.build("replace", NS_URI)).add_self_xmlns().put_attribute("id", replace_id);
    message.stanza.put_node(hint_node);
}

public static string? get_replace_id(MessageStanza message) {
    StanzaNode? node = message.stanza.get_subnode("replace", NS_URI);
    if (node == null) return null;

    return node.get_attribute("id");
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0308_last_message_correction");

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
