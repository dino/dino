public class Xmpp.DirectTlsXmppStream : TlsXmppStream {

    string host;
    uint16 port;

    public DirectTlsXmppStream(Jid remote, string host, uint16 port) {
        this.remote_name = remote;
        this.host = host;
        this.port = port;
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
            reset_stream(tls_connection);

            yield setup();

            attach_negotation_modules();
        } catch (Error e) {
            throw new IOStreamError.CONNECT("Failed connecting to %s:%i (tls): %s", host, port, e.message);
        }
    }
}