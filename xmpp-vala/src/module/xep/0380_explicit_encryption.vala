namespace Xmpp.Xep.ExplicitEncryption {
public const string NS_URI = "urn:xmpp:eme:0";

public static void add_encryption_tag_to_message(MessageStanza message, string ns, string? name = null) {
    StanzaNode encryption = new StanzaNode.build("encryption", NS_URI).add_self_xmlns()
        .put_attribute("namespace", ns);

    if(name != null)
        encryption.put_attribute("name", name);

    message.stanza.put_node(encryption);
}

public static string? get_encryption_tag(MessageStanza message) {
    StanzaNode? encryption_node = message.stanza.get_subnode("encryption", NS_URI);
    if (encryption_node != null) {
        return encryption_node.get_attribute("namespace", NS_URI);
    }
    return null;
}
    
}
