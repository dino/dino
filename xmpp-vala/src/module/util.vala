namespace Xmpp {
    public string get_bare_jid(string jid) {
        return jid.split("/")[0];
    }

    public bool is_bare_jid(string jid) {
        return !jid.contains("/");
    }

    public string? get_resource_part(string jid) {
        return jid.split("/")[1];
    }

    public string random_uuid() {
        uint32 b1 = Random.next_int();
        uint16 b2 = (uint16)Random.next_int();
        uint16 b3 = (uint16)(Random.next_int() | 0x4000u) & ~0xb000u;
        uint16 b4 = (uint16)(Random.next_int() | 0x8000u) & ~0x4000u;
        uint16 b5_1 = (uint16)Random.next_int();
        uint32 b5_2 = Random.next_int();
        return "%08x-%04x-%04x-%04x-%04x%08x".printf(b1, b2, b3, b4, b5_1, b5_2);
    }
}
