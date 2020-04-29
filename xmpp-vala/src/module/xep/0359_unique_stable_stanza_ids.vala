namespace Xmpp.Xep.UniqueStableStanzaIDs {

public const string NS_URI = "urn:xmpp:sid:0";

private const string HINT_NO_PERMANENT_STORE = "no-permanent-store";
private const string HINT_NO_STORE = "no-store";
private const string HINT_NO_COPY = "no-copy";
private const string HINT_STORE = "store";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0359_unique_and_stable_stanza_ids");

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

public static void set_origin_id(MessageStanza message, string origin_id) {
    StanzaNode hint_node = (new StanzaNode.build("origin-id", NS_URI)).add_self_xmlns().put_attribute("id", origin_id);
    message.stanza.put_node(hint_node);
}

public static string? get_origin_id(MessageStanza message) {
    StanzaNode? node = message.stanza.get_subnode("origin-id", NS_URI);
    if (node == null) return null;

    return node.get_attribute("id");
}

public static string? get_stanza_id(MessageStanza message, Jid by) {
    string by_str = by.to_string();
    foreach (StanzaNode node in message.stanza.get_subnodes("stanza-id", NS_URI)) {
        if (node.get_attribute("by") == by_str) {
            return node.get_attribute("id");
        }
    }
    return null;
}

}
