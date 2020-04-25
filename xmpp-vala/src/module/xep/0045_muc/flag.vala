using Gee;

namespace Xmpp.Xep.Muc {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "muc");

    private HashMap<Jid, Gee.List<Feature>> room_features = new HashMap<Jid, Gee.List<Feature>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, string> room_names = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

    private HashMap<Jid, string> enter_ids = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);
    public HashMap<Jid, Promise<JoinResult?>> enter_futures = new HashMap<Jid, Promise<JoinResult?>>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, string> own_nicks = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, string> subjects = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, Jid> subjects_by = new HashMap<Jid, Jid>(Jid.hash_bare_func, Jid.equals_bare_func);

    private HashMap<Jid, Jid> occupant_real_jids = new HashMap<Jid, Jid>(Jid.hash_func, Jid.equals_bare_func);
    private HashMap<Jid, HashMap<Jid, Affiliation>> affiliations = new HashMap<Jid, HashMap<Jid, Affiliation>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, Role> occupant_role = new HashMap<Jid, Role>(Jid.hash_func, Jid.equals_func);

    public string? get_room_name(Jid muc_jid) { return room_names.has_key(muc_jid.bare_jid) ? room_names[muc_jid.bare_jid] : null; }

    public bool has_room_feature(Jid muc_jid, Feature feature) {
        return room_features.has_key(muc_jid.bare_jid) && room_features[muc_jid.bare_jid].contains(feature);
    }

    public Jid? get_real_jid(Jid full_jid) { return occupant_real_jids[full_jid]; }

    public Gee.List<Jid> get_offline_members(Jid muc_jid) {
        Gee.List<Jid> ret = new ArrayList<Jid>(Jid.equals_func);
        HashMap<Jid, Affiliation>? muc_affiliations = affiliations[muc_jid.bare_jid];
        if (muc_affiliations != null) {
            foreach (Jid jid in muc_affiliations.keys) {
                if (!jid.equals_bare(muc_jid)) ret.add(jid);
            }
        }
        return ret;
    }

    public Affiliation get_affiliation(Jid muc_jid, Jid full_jid) {
        HashMap<Jid, Affiliation>? muc_affiliations = affiliations[muc_jid.bare_jid];
        if (muc_affiliations != null) return muc_affiliations[full_jid];
        return Affiliation.NONE;
    }

    public Role? get_occupant_role(Jid full_jid) {
        if (occupant_role.has_key(full_jid)) return occupant_role[full_jid];
        return Role.NONE;
    }

    public string? get_muc_nick(Jid muc_jid) { return own_nicks[muc_jid.bare_jid]; }

    public void set_muc_nick(Jid muc_jid) {
        if (muc_jid.is_full()) {
            own_nicks[muc_jid.bare_jid] = muc_jid.resourcepart;
        }
    }

    public string? get_enter_id(Jid muc_jid) { return enter_ids[muc_jid.bare_jid]; }

    public bool is_muc(Jid jid) { return own_nicks[jid] != null; }

    public bool is_occupant(Jid jid) {
        return own_nicks.has_key(jid.bare_jid) || enter_ids.has_key(jid.bare_jid);
    }

    public bool is_muc_enter_outstanding() { return enter_ids.size != 0; }

    public string? get_muc_subject(Jid muc_jid) { return subjects[muc_jid.bare_jid]; }

    internal void set_room_name(Jid muc_jid, string name) {
        room_names[muc_jid.bare_jid] = name;
    }

    internal void set_room_features(Jid muc_jid, Gee.List<Feature> features) {
        room_features[muc_jid.bare_jid] = features;
    }

    internal void set_real_jid(Jid full_jid, Jid real_jid) { occupant_real_jids[full_jid] = real_jid; }

    internal void set_offline_member(Jid muc_jid, Jid real_jid, Affiliation affiliation) {
        set_affiliation(muc_jid.bare_jid, real_jid.bare_jid, affiliation);
    }

    internal void set_affiliation(Jid muc_jid, Jid full_jid, Affiliation affiliation) {
        if (!affiliations.has_key(muc_jid.bare_jid)) affiliations[muc_jid.bare_jid] = new HashMap<Jid, Affiliation>(Jid.hash_func, Jid.equals_func);
        if (affiliation == Affiliation.NONE) {
            affiliations[muc_jid.bare_jid].unset(full_jid);
        } else {
            affiliations[muc_jid.bare_jid][full_jid] = affiliation;
        }
    }

    internal void set_occupant_role(Jid full_jid, Role role) {
        occupant_role[full_jid] = role;
    }

    internal void set_muc_subject(Jid full_jid, string? subject) {
        subjects[full_jid.bare_jid] = subject;
        subjects_by[full_jid.bare_jid] = full_jid;
    }

    internal void start_muc_enter(Jid jid, string presence_id) {
        enter_ids[jid.bare_jid] = presence_id;
    }

    internal void finish_muc_enter(Jid jid) {
        enter_ids.unset(jid.bare_jid);
    }

    internal void left_muc(XmppStream stream, Jid muc_jid) {
        own_nicks.unset(muc_jid);
        subjects.unset(muc_jid);
        subjects_by.unset(muc_jid);
        Gee.List<Jid>? occupants = stream.get_flag(Presence.Flag.IDENTITY).get_resources(muc_jid);
        if (occupants != null) {
            foreach (Jid occupant in occupants) {
                remove_occupant_info(occupant);
            }
        }
    }

    internal void remove_occupant_info(Jid jid) {
        occupant_real_jids.unset(jid);
        if (affiliations.has_key(jid)) affiliations[jid].unset(jid);
        occupant_role.unset(jid);
    }

    internal override string get_ns() { return NS_URI; }

    internal override string get_id() { return IDENTITY.id; }
}

}
