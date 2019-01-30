using Gee;

namespace Xmpp.Xep.SrvRecordsTls {

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>("", "0363_srv_records_for_xmpp_over_tls");

    public override void attach(XmppStream stream) {
        stream.register_connection_provider(new TlsConnectionProvider());
    }

    public override void detach(XmppStream stream) { }

    public override bool mandatory_outstanding(XmppStream stream) { return false; }
    public override bool negotiation_active(XmppStream stream) { return false; }
    public override string get_ns() { return IDENTITY.ns; }
    public override string get_id() { return IDENTITY.id; }
}

public class TlsConnectionProvider : ConnectionProvider {
    private SrvTarget? srv_target;

    public async override int? get_priority(Jid remote_name) {
        GLib.List<SrvTarget>? xmpp_target = null;
        try {
            GLibFixes.Resolver resolver = GLibFixes.Resolver.get_default();
            xmpp_target = yield resolver.lookup_service_async("xmpps-client", "tcp", remote_name.to_string(), null);
        } catch (Error e) {
            return null;
        }
        xmpp_target.sort((a, b) => { return a.get_priority() - b.get_priority(); });
        srv_target = xmpp_target.nth(0).data;
        return xmpp_target.nth(0).data.get_priority();
    }

    public async override IOStream? connect(XmppStream stream, out string hostname) {
        SocketClient client = new SocketClient();
        try {
            hostname = srv_target.get_hostname();
            debug("Connecting to %s %i (tls)", hostname, srv_target.get_port());
            IOStream? io_stream = yield client.connect_to_host_async(hostname, srv_target.get_port());
            TlsConnection tls_connection = TlsClientConnection.new(io_stream, new NetworkAddress(stream.remote_name.to_string(), srv_target.get_port()));
#if ALPN_SUPPORT
            tls_connection.set_advertised_protocols(new string[]{"xmpp-client"});
#endif
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
