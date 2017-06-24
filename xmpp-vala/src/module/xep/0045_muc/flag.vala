using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Muc {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "muc");

    private HashMap<string, Gee.List<Feature>> room_features = new HashMap<string, Gee.List<Feature>>();
    private HashMap<string, string> room_names = new HashMap<string, string>();

    private HashMap<string, string> enter_ids = new HashMap<string, string>();
    private HashMap<string, string> own_nicks = new HashMap<string, string>();
    private HashMap<string, string> subjects = new HashMap<string, string>();
    private HashMap<string, string> subjects_by = new HashMap<string, string>();

    private HashMap<string, string> occupant_real_jids = new HashMap<string, string>();
    private HashMap<string, HashMap<string, Affiliation>> affiliations = new HashMap<string, HashMap<string, Affiliation>>();
    private HashMap<string, Role> occupant_role = new HashMap<string, Role>();

    public string? get_room_name(string jid) { return room_names.has_key(jid) ? room_names[jid] : null; }

    public bool has_room_feature(string jid, Feature feature) {
        return room_features.has_key(jid) && room_features[jid].contains(feature);
    }

    public string? get_real_jid(string full_jid) { return occupant_real_jids[full_jid]; }

    public Gee.List<string> get_offline_members(string full_jid) {
        Gee.List<string> ret = new ArrayList<string>();
        foreach (string muc_jid in affiliations.keys) {
            foreach (string jid in affiliations[muc_jid].keys) {
                if (!jid.has_prefix(muc_jid)) ret.add(jid);
            }
        }
        return ret;
    }

    public Affiliation? get_affiliation(string muc_jid, string full_jid) {
        if (affiliations.has_key(muc_jid) && affiliations[muc_jid].has_key(full_jid)) return affiliations[muc_jid][full_jid];
        return Affiliation.NONE;
    }

    public Role? get_occupant_role(string full_jid) {
        if (occupant_role.has_key(full_jid)) return occupant_role[full_jid];
        return Role.NONE;
    }

    public string? get_muc_nick(string bare_jid) { return own_nicks[bare_jid]; }

    public string? get_enter_id(string bare_jid) { return enter_ids[bare_jid]; }

    public bool is_muc(string jid) { return own_nicks[jid] != null; }

    public bool is_occupant(string jid) {
        string bare_jid = get_bare_jid(jid);
        return own_nicks.has_key(bare_jid) || enter_ids.has_key(bare_jid);
    }

    public bool is_muc_enter_outstanding() { return enter_ids.size != 0; }

    public string? get_muc_subject(string bare_jid) { return subjects[bare_jid]; }

    internal void set_room_name(string jid, string name) {
        room_names[jid] = name;
    }

    internal void set_room_features(string jid, Gee.List<Feature> features) {
        room_features[jid] = features;
    }

    internal void set_real_jid(string full_jid, string real_jid) { occupant_real_jids[full_jid] = real_jid; }

    internal void set_offline_member(string muc_jid, string real_jid, Affiliation affiliation) {
        set_affiliation(muc_jid, real_jid, affiliation);
    }

    internal void set_affiliation(string muc_jid, string full_jid, Affiliation affiliation) {
        if (!affiliations.has_key(muc_jid)) affiliations[muc_jid] = new HashMap<string, Affiliation>();
        if (affiliation == Affiliation.NONE) {
            affiliations[muc_jid].unset(full_jid);
        } else {
            affiliations[muc_jid][full_jid] = affiliation;
        }
    }

    internal void set_occupant_role(string full_jid, Role role) {
        occupant_role[full_jid] = role;
    }

    internal void set_muc_subject(string full_jid, string? subject) {
        string bare_jid = get_bare_jid(full_jid);
        subjects[bare_jid] = subject;
        subjects_by[bare_jid] = full_jid;
    }

    internal void start_muc_enter(string bare_jid, string presence_id) {
        enter_ids[bare_jid] = presence_id;
    }

    internal void finish_muc_enter(string bare_jid, string? nick = null) {
        if (nick != null) own_nicks[bare_jid] = nick;
        enter_ids.unset(bare_jid);
    }

    internal void left_muc(XmppStream stream, string muc) {
        own_nicks.unset(muc);
        subjects.unset(muc);
        subjects_by.unset(muc);
        Gee.List<string>? occupants = stream.get_flag(Presence.Flag.IDENTITY).get_resources(muc);
        if (occupants != null) {
            foreach (string occupant in occupants) {
                remove_occupant_info(occupant);
            }
        }
    }

    internal void remove_occupant_info(string full_jid) {
        occupant_real_jids.unset(full_jid);
        string bare_jid = get_bare_jid(full_jid);
        if (affiliations.has_key(full_jid)) affiliations[bare_jid].unset(full_jid);
        occupant_role.unset(full_jid);
    }

    internal override string get_ns() { return NS_URI; }

    internal override string get_id() { return IDENTITY.id; }
}

}
