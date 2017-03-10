using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ServiceDiscovery {

public class ItemsResult {
    public Iq.Stanza iq { get; private set; }

    public ArrayList<Item> items {
        owned get {
            ArrayList<Item> ret = new ArrayList<Item>();
            foreach (StanzaNode feature_node in iq.stanza.get_subnode("query", NS_URI_ITEMS).get_subnodes("identity", NS_URI_INFO)) {
                ret.add(new Item(feature_node.get_attribute("jid", NS_URI_ITEMS),
                                        feature_node.get_attribute("name", NS_URI_ITEMS),
                                        feature_node.get_attribute("node", NS_URI_ITEMS)));
            }
            return ret;
        }
    }

    public ItemsResult.from_iq(Iq.Stanza iq) {
        this.iq = iq;
    }
}

}