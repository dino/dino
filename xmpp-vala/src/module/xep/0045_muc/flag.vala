using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Muc {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "muc");

    private HashMap<string, ListenerHolder> enter_listeners = new HashMap<string, ListenerHolder>();
    private HashMap<string, string> enter_ids = new HashMap<string, string>();
    private HashMap<string, string> own_nicks = new HashMap<string, string>();
    private HashMap<string, string> subjects = new HashMap<string, string>();
    private HashMap<string, string> subjects_by = new HashMap<string, string>();
    private HashMap<string, string> occupant_real_jids = new HashMap<string, string>();
    private HashMap<string, string> occupant_affiliation = new HashMap<string, string>();
    private HashMap<string, string> occupant_role = new HashMap<string, string>();

    public string? get_real_jid(string full_jid) { return occupant_real_jids[full_jid]; }

    public void set_real_jid(string full_jid, string real_jid) { occupant_real_jids[full_jid] = real_jid; }

    public string? get_occupant_affiliation(string full_jid) { return occupant_affiliation[full_jid]; }

    public void set_occupant_affiliation(string full_jid, string affiliation) { occupant_affiliation[full_jid] = affiliation; }

    public string? get_occupant_role(string full_jid) { return occupant_role[full_jid]; }

    public void set_occupant_role(string full_jid, string role) { occupant_role[full_jid] = role; }

    public string? get_muc_nick(string bare_jid) { return own_nicks[bare_jid]; }

    public string? get_enter_id(string bare_jid) { return enter_ids[bare_jid]; }

    public ListenerHolder? get_enter_listener(string bare_jid) { return enter_listeners[bare_jid]; }

    public bool is_muc(string jid) { return own_nicks[jid] != null; }

    public bool is_occupant(string jid) {
        string bare_jid = get_bare_jid(jid);
        return own_nicks.has_key(bare_jid) || enter_ids.has_key(bare_jid);
    }

    public bool is_muc_enter_outstanding() { return enter_ids.size != 0; }

    public string? get_muc_subject(string bare_jid) { return subjects[bare_jid]; }

    public void set_muc_subject(string full_jid, string subject) {
        string bare_jid = get_bare_jid(full_jid);
        subjects[bare_jid] = subject;
        subjects_by[bare_jid] = full_jid;
    }

    public void start_muc_enter(string bare_jid, string presence_id, ListenerHolder listener) {
        enter_listeners[bare_jid] = listener;
        enter_ids[bare_jid] = presence_id;
    }

    public void finish_muc_enter(string bare_jid, string? nick = null) {
        if (nick != null) own_nicks[bare_jid] = nick;
        enter_listeners.unset(bare_jid);
        enter_ids.unset(bare_jid);
    }

    public void remove_occupant_info(string full_jid) {
        occupant_real_jids.unset(full_jid);
        occupant_affiliation.unset(full_jid);
        occupant_role.unset(full_jid);
    }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}