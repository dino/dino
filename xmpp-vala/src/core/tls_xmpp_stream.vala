public abstract class Xmpp.TlsXmppStream : IoXmppStream {

    public TlsCertificateFlags? errors;

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
        warning(@"Tls Certificate Errors: $(error_str)");
        return false;
    }
}