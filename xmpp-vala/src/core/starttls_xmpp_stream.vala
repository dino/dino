public class Xmpp.StartTlsXmppStream : TlsXmppStream {

    private const string TLS_NS_URI = "urn:ietf:params:xml:ns:xmpp-tls";

    string host;
    uint16 port;
    TlsXmppStream.OnInvalidCertWrapper on_invalid_cert;

    public StartTlsXmppStream(Jid remote, string host, uint16 port, TlsXmppStream.OnInvalidCertWrapper on_invalid_cert) {
        base(remote);
        this.host = host;
        this.port = port;
        this.on_invalid_cert = on_invalid_cert;
    }

    public override async void connect() throws IOStreamError {
        try {
            SocketClient client = new SocketClient();
            debug("Connecting to %s:%i (starttls)", host, port);
            IOStream stream = yield client.connect_to_host_async(host, port);
            reset_stream(stream);

            yield setup();

            StanzaNode node = yield read();
            var starttls_node = node.get_subnode("starttls", TLS_NS_URI);
            if (starttls_node == null) {
                warning("%s does not offer starttls", remote_name.to_string());
            }

            write(new StanzaNode.build("starttls", TLS_NS_URI).add_self_xmlns());

            node = yield read();

            if (node.ns_uri != TLS_NS_URI || node.name != "proceed") {
                warning("Server did not 'proceed' starttls request");
            }

            try {
                var identity = new NetworkService("xmpp-client", "tcp", remote_name.to_string());
                var conn = TlsClientConnection.new(get_stream(), identity);
                reset_stream(conn);

                conn.accept_certificate.connect(on_invalid_certificate);
                conn.accept_certificate.connect((cert, flags) => on_invalid_cert.func(cert, flags));
            } catch (Error e) {
                stderr.printf("Failed to start TLS: %s\n", e.message);
            }

            yield setup();

            attach_negotation_modules();
        } catch (Error e) {
            throw new IOStreamError.CONNECT("Failed connecting to %s:%i (starttls): %s", host, port, e.message);
        }
    }
}
