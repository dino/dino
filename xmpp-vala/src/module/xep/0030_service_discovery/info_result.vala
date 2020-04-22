using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public class InfoResult {
    public Iq.Stanza iq { get; private set; }

    public Gee.List<string> features {
        owned get {
            ArrayList<string> ret = new ArrayList<string>();
            foreach (StanzaNode feature_node in iq.stanza.get_subnode("query", NS_URI_INFO).get_subnodes("feature", NS_URI_INFO)) {
                ret.add(feature_node.get_attribute("var", NS_URI_INFO));
            }
            return ret;
        }
        set {
            foreach (string feature in value) {
                add_feature(feature);
            }
        }
    }

    public Gee.Set<Identity> identities {
        owned get {
            HashSet<Identity> ret = new HashSet<Identity>();
            foreach (StanzaNode feature_node in iq.stanza.get_subnode("query", NS_URI_INFO).get_subnodes("identity", NS_URI_INFO)) {
                ret.add(new Identity(feature_node.get_attribute("category", NS_URI_INFO),
                                        feature_node.get_attribute("type", NS_URI_INFO),
                                        feature_node.get_attribute("name", NS_URI_INFO)));
            }
            return ret;
        }
        set {
            foreach (Identity identity in value) {
                add_identity(identity);
            }
        }
    }

    public InfoResult(Iq.Stanza iq_request) {
        iq = new Iq.Stanza.result(iq_request);
        string? node = iq_request.stanza.get_subnode("query", NS_URI_INFO).get_attribute("node");
        StanzaNode query = new StanzaNode.build("query", NS_URI_INFO).add_self_xmlns();
        if (node != null) {
            query.set_attribute("node", node);
        }
        iq.stanza.put_node(query);
    }

    private InfoResult.from_iq(Iq.Stanza iq) {
        this.iq = iq;
    }

    public static InfoResult? create_from_iq(Iq.Stanza iq) {
        if (iq.is_error()) return null;
        StanzaNode query_node = iq.stanza.get_subnode("query", NS_URI_INFO);
        if (query_node == null) return null;
        StanzaNode feature_node = query_node.get_subnode("feature", NS_URI_INFO);
        if (feature_node == null) return null;
        StanzaNode identity_node = query_node.get_subnode("identity", NS_URI_INFO);
        if (identity_node == null) return null;
        return new ServiceDiscovery.InfoResult.from_iq(iq);
    }

    public void add_feature(string feature) {
        iq.stanza.get_subnode("query", NS_URI_INFO).put_node(new StanzaNode.build("feature", NS_URI_INFO).put_attribute("var", feature));
    }

    public void add_identity(Identity identity) {
        StanzaNode identity_node = new StanzaNode.build("identity", NS_URI_INFO)
                .put_attribute("category", identity.category)
                .put_attribute("type", identity.type_);
        if (identity.name != null) {
            identity_node.put_attribute("name", identity.name);
        }
        iq.stanza.get_subnode("query", NS_URI_INFO).put_node(identity_node);
    }
}

}
