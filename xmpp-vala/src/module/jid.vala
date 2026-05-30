namespace Xmpp {

public class Jid : Object {
    public string? localpart {
        get {
            if (level == Level.BARE) return part;
            if (level == Level.FULL && parent.level == Level.BARE) return parent.part;
            return null;
        }
    }
    public string domainpart {
        get {
            if (level == Level.DOMAIN) return part;
            return parent.domainpart;
        }
    }
    public string? resourcepart {
        get {
            if (level == Level.FULL) return part;
            return null;
        }
    }

    public Jid bare_jid {
        get {
            if (level == Level.FULL) return parent;
            return this;
        }
    }

    public Jid domain_jid {
        get {
            if (level == Level.DOMAIN) return this;
            return parent.domain_jid;
        }
    }

    private static WeakMap<string, Jid> INTERNED = new WeakMap<string, Jid>();

    enum Level {
        DOMAIN,
        BARE,
        FULL
    }
    private Level level;
    private Jid? parent;
    private string part;
    private string? jid;

    private Jid() {}

    private Jid.domain(string domainpart) throws InvalidJidError {
        this.level = Level.DOMAIN;
        this.part = domainpart;
        this.jid = this.part;
    }

    private Jid.bare(string localpart, Jid parent, string jid) throws InvalidJidError {
        this.level = Level.BARE;
        this.parent = parent;
        this.part = localpart;
        this.jid = jid;
    }

    private Jid.full(Jid parent, string resourcepart, string jid) throws InvalidJidError {
        this.level = Level.FULL;
        this.parent = parent;
        this.part = resourcepart;
        this.jid = jid;
    }

    private static Jid get_interned(string jid) {
        if (INTERNED == null) new Jid();
        return INTERNED.get(jid);
    }

    private static Jid from_domain(string domainpart) throws InvalidJidError {
        if (domainpart.length == 0) throw new InvalidJidError.EMPTY_DOMAIN("Domain is empty");

        Jid result = get_interned(domainpart);
        if (result != null) return result;

        int domain_length = domainpart.length;
        if (domainpart[domain_length - 1] == '.') domain_length--;
        string prepared_domainpart = prepare(idna_decode(domainpart, domain_length), ICU.PrepType.RFC3491_NAMEPREP);

        result = get_interned(prepared_domainpart);
        if (result != null) {
            INTERNED.set(domainpart, result);
            return result;
        }

        idna_verify(prepared_domainpart);
        result = new Jid.domain(prepared_domainpart);
        INTERNED.set(prepared_domainpart, result);
        INTERNED.set(domainpart, result);
        return result;
    }

    private static Jid from_bare(string localpart, Jid parent) throws InvalidJidError {
        if (localpart.length == 0) throw new InvalidJidError.EMPTY_LOCAL("Localpart is empty but non-null");
        if (parent.level != Level.DOMAIN) throw new InvalidJidError.UNKNOWN("Parent of bare jid was not a domain");

        string prepared_localpart = prepare(localpart, ICU.PrepType.RFC3920_NODEPREP);
        string prepared_jid = "%s@%s".printf(prepared_localpart, parent.part);

        Jid result = get_interned(prepared_jid);
        if (result != null) return result;

        result = new Jid.bare(prepared_localpart, parent, prepared_jid);
        INTERNED.set(prepared_jid, result);
        return result;
    }

    private static Jid from_full(Jid parent, string resourcepart) throws InvalidJidError {
        if (resourcepart.length == 0) throw new InvalidJidError.EMPTY_RESOURCE("Resource is empty but non-null");
        if (parent.level > Level.BARE) throw new InvalidJidError.UNKNOWN("Parent of full jid was not a bare jid or domain");

        string prepared_resourcepart = prepare(resourcepart, ICU.PrepType.RFC3920_RESOURCEPREP);
        string prepared_jid = "%s/%s".printf(parent.jid, prepared_resourcepart);

        Jid result = get_interned(prepared_jid);
        if (result != null) return result;

        result = new Jid.full(parent, prepared_resourcepart, prepared_jid);
        INTERNED.set(prepared_jid, result);
        return result;
    }

    public static Jid from_string(string jid) throws InvalidJidError {
        Jid result = get_interned(jid);
        if (result != null) return result;

        int slash_index = jid.index_of("/");
        int at_index = jid.index_of("@");
        if (at_index > slash_index && slash_index != -1) at_index = -1;
        string resourcepart = slash_index < 0 ? null : jid.slice(slash_index + 1, jid.length);
        string localpart = at_index < 0 ? null : jid.slice(0, at_index);
        string domainpart;
        if (at_index < 0) {
            if (slash_index < 0) {
                domainpart = jid;
            } else {
                domainpart = jid.slice(0, slash_index);
            }
        } else {
            if (slash_index < 0) {
                domainpart = jid.slice(at_index + 1, jid.length);
            } else {
                domainpart = jid.slice(at_index + 1, slash_index);
            }
        }
        result = from_components(localpart, domainpart, resourcepart);
        INTERNED.set(jid, result);
        return result;
    }

    public static Jid from_components(string? localpart, string domainpart, string? resourcepart) throws InvalidJidError {
        Jid jid = from_domain(domainpart);
        if (localpart != null) {
            jid = from_bare(localpart, jid);
        }
        if (resourcepart != null) {
            jid = from_full(jid, resourcepart);
        }
        return jid;
    }

    private static string idna_decode(string src, int src_length = -1) throws InvalidJidError {
        ICU.ErrorCode status = ICU.ErrorCode.ZERO_ERROR;
        ICU.IDNAInfo info;
        char[] dest = new char[src.length * 2];
        ICU.IDNA.openUTS46(ICU.IDNAOptions.DEFAULT, ref status).nameToUnicodeUTF8(src, src_length, dest, out info, ref status);
        if (status == ICU.ErrorCode.INVALID_CHAR_FOUND) {
            throw new InvalidJidError.INVALID_CHAR("Found invalid character");
        } else if (status.is_failure() || info.errors > 0) {
            throw new InvalidJidError.UNKNOWN(@"Unknown error: $(status.errorName())");
        }
        return (string) dest;
    }

    private static void idna_verify(string src) throws InvalidJidError {
        ICU.ErrorCode status = ICU.ErrorCode.ZERO_ERROR;
        ICU.IDNAInfo info;
        char[] dest = new char[src.length * 2];
        ICU.IDNA.openUTS46(ICU.IDNAOptions.DEFAULT, ref status).nameToASCII_UTF8(src, -1, dest, out info, ref status);
        if (status == ICU.ErrorCode.INVALID_CHAR_FOUND) {
            throw new InvalidJidError.INVALID_CHAR("Found invalid character");
        } else if (status.is_failure() || info.errors > 0) {
            throw new InvalidJidError.UNKNOWN(@"Unknown error: $(status.errorName())");
        }
    }

    private static string? prepare(string? src, ICU.PrepType type, bool strict = false) throws InvalidJidError {
        if (src == null) return src;
        try {
            ICU.ParseError error;
            ICU.ErrorCode status = ICU.ErrorCode.ZERO_ERROR;
            ICU.PrepProfile profile = ICU.PrepProfile.openByType(type, ref status);
            ICU.String src16 = ICU.String.from_string(src);
            int32 dest16_capacity = src16.len() * 2 + 1;
            ICU.String dest16 = ICU.String.alloc(dest16_capacity);
            long dest16_length = profile.prepare(src16, src16.len(), dest16, dest16_capacity, strict ? ICU.PrepOptions.DEFAULT : ICU.PrepOptions.ALLOW_UNASSIGNED, out error, ref status);
            if (status == ICU.ErrorCode.INVALID_CHAR_FOUND) {
                throw new InvalidJidError.INVALID_CHAR("Found invalid character");
            } else if (status == ICU.ErrorCode.STRINGPREP_PROHIBITED_ERROR) {
                throw new InvalidJidError.INVALID_CHAR("Found prohibited character");
            } else if (status != ICU.ErrorCode.ZERO_ERROR) {
                throw new InvalidJidError.UNKNOWN(@"Unknown error: $(status.errorName())");
            } else if (dest16_length < 0) {
                throw new InvalidJidError.UNKNOWN("Unknown error");
            }
            return dest16.to_string();
        } catch (ConvertError e) {
            throw new InvalidJidError.INVALID_CHAR(@"Conversion error: $(e.message)");
        }
    }

    public Jid with_resource(string? resourcepart) throws InvalidJidError {
        if (resourcepart == null) return bare_jid;
        return Jid.from_full(bare_jid, resourcepart);
    }

    public bool is_domain() {
        return level == Level.DOMAIN;
    }

    public bool is_bare() {
        return level <= Level.BARE;
    }

    public bool is_full() {
        return level == Level.FULL;
    }

    public unowned string to_string() {
        return jid;
    }

    public bool equals_bare(Jid? jid) {
        return jid != null && equals_bare_func(this, jid);
    }

    public bool equals(Jid? jid) {
        return jid != null && equals_func(this, jid);
    }

    public static new bool equals_bare_func(Jid jid1, Jid jid2) {
        return equals_func(jid1.bare_jid, jid2.bare_jid);
    }

    public static bool equals_func(Jid? jid1, Jid? jid2) {
        if (jid1 == null && jid2 == null) return true;
        if (jid1 == null || jid2 == null) return false;
        if (jid1 == jid2) return true;
        bool res = jid1.level == jid2.level && jid1.part == jid2.part && equals_func(jid1.parent, jid2.parent);
        if (res) warning("JIDs considered equal, but are not same instance");
        return res;
    }

    public static new uint hash_bare_func(Jid jid) {
        return jid.bare_jid.to_string().hash();
    }

    public static new uint hash_func(Jid jid) {
        return jid.to_string().hash();
    }
}

public errordomain InvalidJidError {
    EMPTY_DOMAIN,
    EMPTY_RESOURCE,
    EMPTY_LOCAL,
    INVALID_CHAR,
    UNKNOWN
}

}
