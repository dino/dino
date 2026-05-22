using Gee;

namespace Xmpp.Xep.MucAffiliationsVersioning {

    public const string NS_URI = "urn:xmpp:muc:affiliations:1";

    public static StanzaNode get_join_presence_node(string? since) {
        var stanza_node = new StanzaNode.build("mav", NS_URI).add_self_xmlns();
        if (since != null) {
            stanza_node.put_attribute("since", since);
        }
        return stanza_node;
    }

    public static string? get_mav_since(StanzaNode outer_node) {
        StanzaNode? mav_node = outer_node.get_subnode("mav", MucAffiliationsVersioning.NS_URI);
        return mav_node != null ? mav_node.get_attribute("since", MucAffiliationsVersioning.NS_URI) : null;
    }

    public static string? get_mav_until(StanzaNode outer_node) {
        StanzaNode? mav_node = outer_node.get_subnode("mav", MucAffiliationsVersioning.NS_URI);
        return mav_node != null ? mav_node.get_attribute("until", MucAffiliationsVersioning.NS_URI) : null;
    }
}