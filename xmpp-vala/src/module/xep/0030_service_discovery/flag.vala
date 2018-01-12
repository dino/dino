using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

    private HashMap<Jid, Gee.List<string>?> entity_features = new HashMap<Jid, Gee.List<string>?>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, Gee.List<Identity>?> entity_identities = new HashMap<Jid, Gee.List<Identity>?>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, Gee.List<Item>?> entity_items = new HashMap<Jid, Gee.List<Item>?>(Jid.hash_func, Jid.equals_func);
    public Gee.List<string> features = new ArrayList<string>();

    public Gee.List<Identity>? get_entity_categories(Jid jid) {
        return entity_identities.has_key(jid) ? entity_identities[jid] : null; // TODO isn’t this default for hashmap
    }

    public bool? has_entity_identity(Jid jid, string category, string type) {
        if (!entity_identities.has_key(jid)) return null;
        if (entity_identities[jid] == null) return false;
        foreach (Identity identity in entity_identities[jid]) {
            if (identity.category == category && identity.type_ == type) return true;
        }
        return false;
    }

    public bool? has_entity_feature(Jid jid, string feature) {
        if (!entity_features.has_key(jid)) return null;
        if (entity_features[jid] == null) return false;
        return entity_features[jid].contains(feature);
    }

    public void set_entity_identities(Jid jid, Gee.List<Identity>? identities) {
        entity_identities[jid] = identities;
    }

    public void set_entity_features(Jid jid, Gee.List<string>? features) {
        entity_features[jid] = features;
    }

    public void set_entity_items(Jid jid, Gee.List<Item>? features) {
        entity_items[jid] = features;
    }

    public void add_own_feature(string feature) { features.add(feature); }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}
