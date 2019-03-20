using Gee;

namespace Xmpp.Xep.SrvRecordsTls {

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>("", "0363_srv_records_for_xmpp_over_tls");

    public override void attach(XmppStream stream) {
        stream.register_service_lookuper(new TlsServiceLookuper());
    }

    public override void detach(XmppStream stream) { }

    public override bool mandatory_outstanding(XmppStream stream) { return false; }
    public override bool negotiation_active(XmppStream stream) { return false; }
    public override string get_ns() { return IDENTITY.ns; }
    public override string get_id() { return IDENTITY.id; }
}

public class TlsServiceLookuper : ServiceLookuper {
    private GLib.List<SrvTarget>? xmpp_targets;

    public async override GLib.List<ConnectionProvider>? lookup(Jid remote_name) {
        GLib.List<TlsConnectionProvider> providers = new GLib.List<TlsConnectionProvider>();

        try {
            GLibFixes.Resolver resolver = GLibFixes.Resolver.get_default();
            xmpp_targets = yield resolver.lookup_service_async("xmpps-client", "tcp", remote_name.to_string(), null);
        } catch (Error e) {
            return null;
        }

        SrvTarget? target = null;
        for (int i = 0; i < xmpp_targets.length(); i++) {
            target = xmpp_targets.nth(i).data;
            TlsConnectionProvider? provider = new TlsConnectionProvider(target.get_hostname(), target.get_port());
            provider.set_priority(target.get_priority());
            providers.append(provider);
        }

        return providers;
    }
}

public class TlsConnectionProvider : ConnectionProvider {
    private int priority;
    private string hostname;
    private uint16 port;

    public TlsConnectionProvider(string hostname, uint16 port) {
        this.hostname = hostname;
        this.port = port;
    }

    public override int? get_priority() {
        return this.priority;
    }

    public void set_priority(int priority) {
        this.priority = priority;
    }

    public async override IOStream? connect(XmppStream stream) {
        try {
            SocketClient client = new SocketClient();
            client.set_timeout(timeout);
            IOStream? io_stream = yield client.connect_to_host_async(this.hostname, this.port);
            ((SocketConnection)io_stream).get_socket().set_timeout(0); // Back to zero if succeeded
            TlsConnection tls_connection = TlsClientConnection.new(io_stream, new NetworkAddress(stream.remote_name.to_string(), this.port));
            tls_connection.accept_certificate.connect(stream.get_module(Tls.Module.IDENTITY).on_invalid_certificate);
            stream.add_flag(new Tls.Flag() { finished=true });
            return tls_connection;
        } catch (Error e) {
            return null;
        }
    }

    public override string get_id() { return "srv_records"; }
}

}
