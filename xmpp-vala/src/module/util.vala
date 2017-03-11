namespace Xmpp {
    public string? get_bare_jid(string jid) {
        return jid.split("/")[0];
    }

    public bool is_bare_jid(string jid) {
        return !jid.contains("/");
    }

    public string? get_resource_part(string jid) {
        return jid.split("/")[1];
    }

    public string random_uuid() {
        uint8[] rand = new uint8[16];
        char[] str = new char[37];
        UUID.generate_random(rand);
        UUID.unparse_upper(rand, str);
        return (string) str;
    }
}