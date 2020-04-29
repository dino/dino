using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

    public HashMap<Jid, Gee.List<string>?> entity_features = new HashMap<Jid, Gee.List<string>?>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, Gee.Set<Identity>?> entity_identities = new HashMap<Jid, Gee.Set<Identity>?>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, Gee.List<Item>?> entity_items = new HashMap<Jid, Gee.List<Item>?>(Jid.hash_func, Jid.equals_func);

    private Gee.Set<string> own_features_ = new HashSet<string>();
    public Gee.List<string> own_features {
        owned get {
            var ret = new ArrayList<string>();
            foreach (var feature in own_features_) ret.add(feature);
            return ret;
        }
    }

    private Gee.Set<Identity> own_identities_ = new HashSet<Identity>(Identity.hash_func, Identity.equals_func);
    public Gee.Set<Identity> own_identities {
        owned get { return own_identities_.read_only_view; }
    }

    public Gee.Set<Identity>? get_entity_identities(Jid jid) {
        return entity_identities.has_key(jid) ? entity_identities[jid].read_only_view : null; // TODO isn’t this default for hashmap
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

    public void set_entity_identities(Jid jid, Gee.Set<Identity>? identities) {
        entity_identities[jid] = identities;
    }

    public void set_entity_features(Jid jid, Gee.List<string>? features) {
        entity_features[jid] = features;
    }

    public void set_entity_items(Jid jid, Gee.List<Item>? features) {
        entity_items[jid] = features;
    }

    public void add_own_feature(string feature) {
        if (own_features_.contains(feature)) {
            warning("Tried to add the feature %s a second time".printf(feature));
            return;
        }
        own_features_.add(feature);
    }

    public void remove_own_feature(string feature) {
        own_features_.remove(feature);
    }

    public void add_own_identity(Identity identity) { own_identities_.add(identity); }
    public void remove_own_identity(Identity identity) { own_identities_.remove(identity); }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}
