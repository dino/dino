public class Xmpp.DirectTlsXmppStream : TlsXmppStream {

    const string[] ADVERTISED_PROTOCOLS = {"xmpp-client", null};

    string host;
    uint16 port;
    TlsXmppStream.OnInvalidCertWrapper on_invalid_cert;

    public DirectTlsXmppStream(Jid remote_name, string host, uint16 port, TlsXmppStream.OnInvalidCertWrapper on_invalid_cert) {
        base(remote_name);
        this.host = host;
        this.port = port;
        this.on_invalid_cert = on_invalid_cert;
    }

    public override async void connect() throws IOStreamError {
        SocketClient client = new SocketClient();
        try {
            debug("Connecting to %s:%i (tls)", host, port);
            IOStream? io_stream = yield client.connect_to_host_async(host, port);
            TlsConnection tls_connection = TlsClientConnection.new(io_stream, new NetworkAddress(remote_name.to_string(), port));
#if GLIB_2_60
            tls_connection.set_advertised_protocols(ADVERTISED_PROTOCOLS);
#endif
            tls_connection.accept_certificate.connect(on_invalid_certificate);
            tls_connection.accept_certificate.connect((cert, flags) => on_invalid_cert.func(cert, flags));
            reset_stream(tls_connection);

            yield setup();

            attach_negotation_modules();
        } catch (Error e) {
            throw new IOStreamError.CONNECT("Failed connecting to %s:%i (tls): %s", host, port, e.message);
        }
    }
}
