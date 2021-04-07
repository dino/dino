public abstract class Xmpp.TlsXmppStream : IoXmppStream {

    public TlsCertificateFlags? errors;

    public delegate bool OnInvalidCert(GLib.TlsCertificate peer_cert, GLib.TlsCertificateFlags errors);
    public class OnInvalidCertWrapper {
        public OnInvalidCert func;
        public OnInvalidCertWrapper(owned OnInvalidCert func) {
            this.func = (owned) func;
        }
    }

    protected TlsXmppStream(Jid remote_name) {
        base(remote_name);
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
}