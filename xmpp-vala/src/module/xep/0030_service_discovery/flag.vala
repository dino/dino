using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

    private HashMap<string, ArrayList<string>?> entity_features = new HashMap<string, ArrayList<string>?>();
    private HashMap<string, ArrayList<Identity>?> entity_identities = new HashMap<string, ArrayList<Identity>?>();
    public ArrayList<string> features = new ArrayList<string>();

    public ArrayList<Identity>? get_entity_categories(string jid) {
        return entity_identities.has_key(jid) ? entity_identities[jid] : null; // TODO isnt this default for hashmap
    }

    public bool? has_entity_identity(string jid, string category, string type) {
        if (!entity_identities.has_key(jid)) return null;
        if (entity_identities[jid] == null) return false;
        foreach (Identity identity in entity_identities[jid]) {
            if (identity.category == category && identity.type_ == type) return true;
        }
        return false;
    }

    public bool? has_entity_feature(string jid, string feature) {
        if (!entity_features.has_key(jid)) return null;
        if (entity_features[jid] == null) return false;
        return entity_features[jid].contains(feature);
    }

    public void set_entity_identities(string jid, ArrayList<Identity>? identities) {
        entity_identities[jid] = identities;
    }

    public void set_entity_features(string jid, ArrayList<string>? features) {
        entity_features[jid] = features;
    }

    public void add_own_feature(string feature) { features.add(feature); }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}