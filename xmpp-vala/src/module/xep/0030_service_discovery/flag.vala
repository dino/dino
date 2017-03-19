using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

    private HashMap<string, ArrayList<string>> entity_features = new HashMap<string, ArrayList<string>>();
    public ArrayList<string> features = new ArrayList<string>();

    public bool? has_entity_feature(string jid, string feature) {
        if (!entity_features.has_key(jid)) return null;
        return entity_features[jid].contains(feature);
    }

    public void set_entitiy_features(string jid, ArrayList<string> features) {
        entity_features[jid] = features;
    }

    public void add_own_feature(string feature) { features.add(feature); }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}