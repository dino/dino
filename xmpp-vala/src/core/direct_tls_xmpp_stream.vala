public class Xmpp.DirectTlsXmppStream : TlsXmppStream {

    string host;
    uint16 port;
    TlsXmppStream.OnInvalidCert on_invalid_cert_outer;

    public DirectTlsXmppStream(Jid remote_name, string host, uint16 port, TlsXmppStream.OnInvalidCert on_invalid_cert) {
        base(remote_name);
        this.host = host;
        this.port = port;
        this.on_invalid_cert_outer = on_invalid_cert;
    }

    public override async void connect() throws IOStreamError {
        SocketClient client = new SocketClient();
        try {
            debug("Connecting to %s %i (tls)", host, port);
            IOStream? io_stream = yield client.connect_to_host_async(host, port);
            TlsConnection tls_connection = TlsClientConnection.new(io_stream, new NetworkAddress(remote_name.to_string(), port));
#if ALPN_SUPPORT
            tls_connection.set_advertised_protocols(new string[]{"xmpp-client"});
#endif
            tls_connection.accept_certificate.connect(on_invalid_certificate);
            tls_connection.accept_certificate.connect(on_invalid_cert_outer);
            reset_stream(tls_connection);

            yield setup();

            attach_negotation_modules();
        } catch (Error e) {
            throw new IOStreamError.CONNECT("Failed connecting to %s:%i (tls): %s", host, port, e.message);
        }
    }
}