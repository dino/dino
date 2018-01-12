namespace Xmpp {

public class Jid {
    public string? localpart;
    public string domainpart;
    public string? resourcepart;

    public Jid bare_jid {
        owned get { return is_bare() ? this : new Jid.components(localpart, domainpart, null); }
    }

    public Jid domain_jid {
        owned get { return is_domain() ? this : new Jid.components(null, domainpart, null); }
    }

    private string jid;

    public Jid(string jid) {
        Jid? parsed = Jid.parse(jid);
        string? localpart = parsed != null ? (owned) parsed.localpart : null;
        string domainpart = parsed != null ? (owned) parsed.domainpart : jid;
        string? resourcepart = parsed != null ? (owned) parsed.resourcepart : null;
        this.intern(jid, (owned) localpart, (owned) domainpart, (owned) resourcepart);
    }

    private Jid.intern(owned string jid, owned string? localpart, owned string domainpart, owned string? resourcepart) {
        this.jid = (owned) jid;
        this.localpart = (owned) localpart;
        this.domainpart = (owned) domainpart;
        this.resourcepart = (owned) resourcepart;
    }

    public Jid.components(owned string? localpart, owned string domainpart, owned string? resourcepart) {
        string jid = domainpart;
        if (localpart != null) {
            jid = @"$localpart@$jid";
        }
        if (resourcepart != null) {
            jid = @"$jid/$resourcepart";
        }
        this.jid = jid;
        this.localpart = (owned) localpart;
        this.domainpart = (owned) domainpart;
        this.resourcepart = (owned) resourcepart;
    }

    public static Jid? parse(string jid) {
        int slash_index = jid.index_of("/");
        string resourcepart = slash_index == -1 ? null : jid.slice(slash_index + 1, jid.length);
        string bare_jid = slash_index == -1 ? jid : jid.slice(0, slash_index);
        int at_index = bare_jid.index_of("@");
        string localpart = at_index == -1 ? null : bare_jid.slice(0, at_index);
        string domainpart = at_index == -1 ? bare_jid : bare_jid.slice(at_index + 1, bare_jid.length);

        if (domainpart == "") return null;
        if (slash_index != -1 && resourcepart == "") return null;
        if (at_index != -1 && localpart == "") return null;

        return new Jid.intern(jid, (owned) localpart, (owned) domainpart, (owned) resourcepart);
    }

    public Jid with_resource(string? resourcepart) {
        return new Jid.components(localpart, domainpart, resourcepart);
    }

    public bool is_domain() {
        return localpart == null && resourcepart == null;
    }

    public bool is_bare() {
        return localpart != null && resourcepart == null;
    }

    public bool is_full() {
        return localpart != null && resourcepart != null;
    }

    public string to_string() {
        return jid;
    }

    public bool equals_bare(Jid? jid) {
        return jid != null && equals_bare_func(this, jid);
    }

    public bool equals(Jid? jid) {
        return jid != null && equals_func(this, jid);
    }

    public static new bool equals_bare_func(Jid jid1, Jid jid2) {
        return jid1.bare_jid.to_string() == jid2.bare_jid.to_string();
    }

    public static bool equals_func(Jid jid1, Jid jid2) {
        return jid1.to_string() == jid2.to_string();
    }

    public static new uint hash_bare_func(Jid jid) {
        return jid.bare_jid.to_string().hash();
    }

    public static new uint hash_func(Jid jid) {
        return jid.to_string().hash();
    }
}

}
