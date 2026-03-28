namespace Xmpp.Xep.MessageAttaching {
    public const string NS_URI = "urn:xmpp:message-attaching:1";

    public static string? get_attach_to(StanzaNode node) {
        StanzaNode? attach_to = node.get_subnode("attach-to", NS_URI);
        if (attach_to == null) return null;

        return attach_to.get_attribute("id", NS_URI);
    }

    public static StanzaNode to_stanza_node(string id) {
        return new StanzaNode.build("attach-to", NS_URI).add_self_xmlns()
                .put_attribute("id", id, NS_URI);
    }
}