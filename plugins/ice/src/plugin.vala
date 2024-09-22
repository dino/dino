using Gee;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

private extern const size_t NICE_ADDRESS_STRING_LEN;

public class Dino.Plugins.Ice.Plugin : RootInterface, Object {
    public Dino.Application app;

    public void registered(Dino.Application app) {
        Nice.debug_enable(true);
        this.app = app;
        app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
            list.add(new Module());
        });
        app.stream_interactor.stream_attached_modules.connect((account, stream) => {
            if (stream.get_module(Socks5Bytestreams.Module.IDENTITY) != null) {
                stream.get_module(Socks5Bytestreams.Module.IDENTITY).set_local_ip_address_handler(get_local_ip_addresses);
            }
            if (stream.get_module(JingleRawUdp.Module.IDENTITY) != null) {
                stream.get_module(JingleRawUdp.Module.IDENTITY).set_local_ip_address_handler(get_local_ip_addresses);
            }
        });
        app.stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    private async void on_stream_negotiated(Account account, XmppStream stream) {
        Module? ice_udp_module = stream.get_module(JingleIceUdp.Module.IDENTITY) as Module;
        if (ice_udp_module == null) return;
        Gee.List<Xep.ExternalServiceDiscovery.Service> services = yield ExternalServiceDiscovery.request_services(stream);
        foreach (Xep.ExternalServiceDiscovery.Service service in services) {
            if (service.transport == "udp" && (service.ty == "stun" || service.ty == "turn")) {
                InetAddress? ip = yield lookup_ipv4_addess(service.host);
                if (ip == null) continue;

                if (ip.is_any || ip.is_link_local || ip.is_loopback || ip.is_multicast || ip.is_site_local) {
                    warning("Ignoring STUN/TURN server at %s", service.host);
                    continue;
                }

                if (service.ty == "stun") {
                    debug("Server offers STUN server: %s:%u, resolved to %s", service.host, service.port, ip.to_string());
                    ice_udp_module.stun_ip = ip.to_string();
                    ice_udp_module.stun_port = service.port;
                } else if (service.ty == "turn") {
                    debug("Server offers TURN server: %s:%u, resolved to %s", service.host, service.port, ip.to_string());
                    ice_udp_module.turn_ip = ip.to_string();
                    ice_udp_module.turn_service = service;
                }
            }
        }
        if (ice_udp_module.stun_ip == null) {
            InetAddress ip = yield lookup_ipv4_addess("stun.dino.im");
            if (ip == null) return;

            debug("Using fallback STUN server: stun.dino.im:7886, resolved to %s", ip.to_string());

            ice_udp_module.stun_ip = ip.to_string();
            ice_udp_module.stun_port = 7886;
        }
    }

    public void shutdown() {
        // Nothing to do
    }

    private async InetAddress? lookup_ipv4_addess(string host) {
        try {
            Resolver resolver = Resolver.get_default();
            GLib.List<GLib.InetAddress>? ips = yield resolver.lookup_by_name_async(host);
            foreach (GLib.InetAddress ina in ips) {
                if (ina.get_family() != SocketFamily.IPV4) continue;
                return ina;
            }
        } catch (Error e) {
            warning("Failed looking up IP address of %s", host);
        }
        return null;
    }
}