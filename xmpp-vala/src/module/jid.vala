namespace Xmpp {

public class Jid {
    public string? localpart;
    public string domainpart;
    public string? resourcepart;

    public Jid bare_jid {
    owned get { return is_bare() ? this : new Jid.intern(null, localpart, domainpart, null); }
    }

    public Jid domain_jid {
    owned get { return is_domain() ? this : new Jid.intern(domainpart, null, domainpart, null); }
    }

    private string jid;

    public Jid(string jid) throws InvalidJidError {
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

        this.components(localpart, domainpart, resourcepart);
    }

    private Jid.intern(owned string? jid, owned string? localpart, owned string domainpart, owned string? resourcepart) {
        this.jid = (owned) jid;
        this.localpart = (owned) localpart;
        this.domainpart = (owned) domainpart;
        this.resourcepart = (owned) resourcepart;
    }

    public Jid.components(string? localpart, string domainpart, string? resourcepart) throws InvalidJidError {
        // TODO verify and normalize all parts
        if (domainpart.length == 0) throw new InvalidJidError.EMPTY_DOMAIN("Domain is empty");
        if (localpart != null && localpart.length == 0) throw new InvalidJidError.EMPTY_LOCAL("Localpart is empty but non-null");
        if (resourcepart != null && resourcepart.length == 0) throw new InvalidJidError.EMPTY_RESOURCE("Resource is empty but non-null");
        string domain = domainpart[domainpart.length - 1] == '.' ? domainpart.substring(0, domainpart.length - 1) : domainpart;
        if (domain.contains("xn--")) {
            domain = idna_decode(domain);
        }
        this.localpart = prepare(localpart, ICU.PrepType.RFC3920_NODEPREP);
        this.domainpart = prepare(domain, ICU.PrepType.RFC3491_NAMEPREP);
        this.resourcepart = prepare(resourcepart, ICU.PrepType.RFC3920_RESOURCEPREP);
        idna_verify(this.domainpart);
    }

    private static string idna_decode(string src) throws InvalidJidError {
        ICU.ErrorCode status = ICU.ErrorCode.ZERO_ERROR;
        ICU.IDNAInfo info;
        char[] dest = new char[src.length * 2];
        ICU.IDNA.openUTS46(ICU.IDNAOptions.DEFAULT, ref status).nameToUnicodeUTF8(src, -1, dest, out info, ref status);
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
        return new Jid.components(localpart, domainpart, resourcepart);
    }

    public bool is_domain() {
        return localpart == null && resourcepart == null;
    }

    public bool is_bare() {
        return resourcepart == null;
    }

    public bool is_full() {
        return localpart != null && resourcepart != null;
    }

    public string to_string() {
        if (jid == null) {
            if (localpart != null && resourcepart != null) {
                jid = @"$localpart@$domainpart/$resourcepart";
            } else if (localpart != null) {
                jid = @"$localpart@$domainpart";
            } else if (resourcepart != null) {
                jid = @"$domainpart/$resourcepart";
            } else {
                jid = domainpart;
            }
        }
        return jid;
    }

    public bool equals_bare(Jid? jid) {
        return jid != null && equals_bare_func(this, jid);
    }

    public bool equals(Jid? jid) {
        return jid != null && equals_func(this, jid);
    }

    public static new bool equals_bare_func(Jid jid1, Jid jid2) {
        return jid1.localpart == jid2.localpart && jid1.domainpart == jid2.domainpart;
    }

    public static bool equals_func(Jid jid1, Jid jid2) {
        return equals_bare_func(jid1, jid2) && jid1.resourcepart == jid2.resourcepart;
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
