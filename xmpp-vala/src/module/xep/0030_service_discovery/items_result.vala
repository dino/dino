using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public class ItemsResult {
    public Iq.Stanza iq { get; private set; }

    public ArrayList<Item> items {
        owned get {
            ArrayList<Item> ret = new ArrayList<Item>();
            foreach (StanzaNode feature_node in iq.stanza.get_subnode("query", NS_URI_ITEMS).get_subnodes("item", NS_URI_ITEMS)) {
                try {
                    ret.add(new Item(new Jid(feature_node.get_attribute("jid", NS_URI_ITEMS)),
                                feature_node.get_attribute("name", NS_URI_ITEMS),
                                feature_node.get_attribute("node", NS_URI_ITEMS)));
                } catch (InvalidJidError e) {
                    warning("Ignoring service at invalid Jid: %s", e.message);
                }
            }
            return ret;
        }
    }

    private ItemsResult.from_iq(Iq.Stanza iq) {
        this.iq = iq;
    }

    public static ItemsResult? create_from_iq(Iq.Stanza iq) {
        if (iq.type_ != Iq.Stanza.TYPE_RESULT) return null;

        if (iq.stanza.get_subnode("query", NS_URI_ITEMS) == null) return null;

        return new ItemsResult.from_iq(iq);
    }
}

}
