namespace Xmpp {
    string? get_bare_jid(string jid) {
        return jid.split("/")[0];
    }

    bool is_bare_jid(string jid) {
        return !jid.contains("/");
    }

    string? get_resource_part(string jid) {
        return jid.split("/")[1];
    }
}