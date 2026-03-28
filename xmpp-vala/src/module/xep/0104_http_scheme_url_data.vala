using Xmpp;

namespace Xmpp.Xep.HttpSchemeForUrlData {
    public const string NS_URI = "http://jabber.org/protocol/url-data";

    // If there are multiple URLs, this will only return the first one
    public static string? get_url(StanzaNode node) {
        StanzaNode? url_data_node = node.get_subnode("url-data", NS_URI);
        if (url_data_node == null) return null;

        return url_data_node.get_attribute("target");
    }

    public static StanzaNode to_stanza_node(string url) {
        return new StanzaNode.build("url-data", NS_URI).add_self_xmlns()
                .put_attribute("target", url, NS_URI);

    }
}