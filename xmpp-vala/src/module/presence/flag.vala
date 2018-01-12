using Gee;

namespace Xmpp.Presence {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "presence");

    private HashMap<Jid, Gee.List<Jid>> resources = new HashMap<Jid, Gee.List<Jid>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, Presence.Stanza> presences = new HashMap<Jid, Presence.Stanza>(Jid.hash_func, Jid.equals_func);

    public Set<Jid> get_available_jids() {
        return resources.keys;
    }

    public Gee.List<Jid>? get_resources(Jid jid) {
        return resources[jid];
    }

    public Presence.Stanza? get_presence(Jid full_jid) {
        return presences[full_jid];
    }

    public void add_presence(Presence.Stanza presence) {
        if (!resources.has_key(presence.from)) {
            resources[presence.from] = new ArrayList<Jid>(Jid.equals_func);
        }
        if (resources[presence.from].contains(presence.from)) {
            resources[presence.from].remove(presence.from);
        }
        resources[presence.from].add(presence.from);
        presences[presence.from] = presence;
    }

    public void remove_presence(Jid jid) {
        if (resources.has_key(jid)) {
            if (jid.is_bare()) {
                foreach (Jid full_jid in resources[jid]) {
                    presences.unset(full_jid);
                }
                resources.unset(jid);
            } else {
                resources[jid].remove(jid);
                if (resources[jid].size == 0) {
                    resources.unset(jid);
                }
                presences.unset(jid);
            }
        }
    }

    public override string get_ns() {
        return NS_URI;
    }

    public override string get_id() {
        return IDENTITY.id;
    }
}

}