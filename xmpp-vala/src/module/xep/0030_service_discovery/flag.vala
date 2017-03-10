using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ServiceDiscovery {

public class Flag : XmppStreamFlag {
    public const string ID = "service_discovery";

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

    public static Flag? get_flag(XmppStream stream) { return (Flag?) stream.get_flag(NS_URI, ID); }

    public static bool has_flag(XmppStream stream) { return get_flag(stream) != null; }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return ID; }
}

}