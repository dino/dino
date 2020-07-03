using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

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
