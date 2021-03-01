public class Xmpp.ClearTextXmppStream : TlsXmppStream {
    string host;
    uint16 port;

    public ClearTextXmppStream(Jid remote, string host, uint16 port) {
        base(remote);
        this.host = host;
        this.port = port;
    }

    public override async void connect() throws IOStreamError {
        SocketClient client = new SocketClient();

        debug("Connecting to %s:%i (cleartext)", host, port);
        try {
            IOStream stream = yield client.connect_to_host_async(host, port);
            reset_stream(stream);

            yield setup();

            attach_negotation_modules();
        } catch (Error e) {
            throw new IOStreamError.CONNECT("Failed connecting to %s:%i (cleartext): %s", this.host, this.port, e.message);
        }
    }
}
