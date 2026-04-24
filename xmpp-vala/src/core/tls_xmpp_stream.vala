public abstract class Xmpp.TlsXmppStream : IoXmppStream {

    public TlsCertificateFlags? errors;
    private Jid? own_jid;

    public delegate bool OnInvalidCert(GLib.TlsCertificate peer_cert, GLib.TlsCertificateFlags errors);
    public class OnInvalidCertWrapper {
        public OnInvalidCert func;
        public OnInvalidCertWrapper(owned OnInvalidCert func) {
            this.func = (owned) func;
        }
    }

    protected TlsXmppStream(Jid remote_name, Jid? own_jid) {
        base(remote_name);
        this.own_jid = own_jid;
    }

    protected bool on_invalid_certificate(TlsCertificate peer_cert, TlsCertificateFlags errors) {
        this.errors = errors;

        string error_str = "";
        foreach (var f in new TlsCertificateFlags[]{TlsCertificateFlags.UNKNOWN_CA, TlsCertificateFlags.BAD_IDENTITY,
            TlsCertificateFlags.NOT_ACTIVATED, TlsCertificateFlags.EXPIRED, TlsCertificateFlags.REVOKED,
            TlsCertificateFlags.INSECURE, TlsCertificateFlags.GENERIC_ERROR, TlsCertificateFlags.VALIDATE_ALL}) {
            if (f in errors) {
                error_str += @"$(f), ";
            }
        }
        warning(@"[%p, %s] Tls Certificate Errors: %s", this, this.remote_name.to_string(), error_str);
        return false;
    }

    public override StanzaNode generate_root_node() {
        StanzaNode root_node = base.generate_root_node();
        if (own_jid != null) {
            root_node.put_attribute("from", own_jid.bare_jid.to_string());
        }
        return root_node;
    }
}