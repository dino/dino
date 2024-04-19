using Gee;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

private extern const size_t NICE_ADDRESS_STRING_LEN;

public class Dino.Plugins.Ice.Plugin : RootInterface, Object {
    private const int64 delay_min = 300; // 10mn
    private const int64 delay_max = (int64) uint.MAX;

    private class TimerPayload {
        public Account account { get; set; }
        public uint timeout_handle_id;

        public TimerPayload(Account account, uint timeout_handle_id) {
            this.account = account;
            this.timeout_handle_id = timeout_handle_id;
        }
    }

    private HashMap<XmppStream, TimerPayload> timeouts = new HashMap<XmppStream, TimerPayload>(XmppStream.hash_func, XmppStream.equals_func);

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
        app.stream_interactor.connection_manager.connection_state_changed.connect(on_connection_state_changed);
    }

    private async void external_discovery_refresh_services(Account account, XmppStream stream) {
        Module? ice_udp_module = stream.get_module(JingleIceUdp.Module.IDENTITY) as Module;
        if (ice_udp_module == null) return;
        Gee.List<Xep.ExternalServiceDiscovery.Service> services = yield ExternalServiceDiscovery.request_services(stream);
        foreach (Xep.ExternalServiceDiscovery.Service service in services) {
            if (service.transport == "udp" && (service.ty == "stun" || service.ty == "turn")) {
                InetAddress ip = yield lookup_ipv4_addess(service.host);
                if (ip == null) continue;

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

        if (ice_udp_module.turn_service != null) {
            DateTime? expires = ice_udp_module.turn_service.expires;
            if (expires != null) {
                int64 delay = (expires.to_unix() - new DateTime.now_utc().to_unix()) / 2;

                if (delay >= delay_min && delay <= delay_max) {
                    debug("Next server external service discovery in %lds (because of TURN credentials' expiry time)", (long) delay);

                    uint timeout_handle_id = Timeout.add_seconds((uint) delay, () => {
                            on_timeout(stream);
                            return false;
                        });
                    timeouts[stream] = new TimerPayload(account, timeout_handle_id);
                    timeouts[stream].account = account;
                    timeouts[stream].timeout_handle_id = timeout_handle_id;
                } else {
                    warning("Bogus TURN credentials' expiry time (delay value = %ld), *not* planning next service discovery", (long) delay);
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

    public void on_timeout(XmppStream stream) {
        if (!timeouts.has_key(stream)) return;
        TimerPayload pl = timeouts[stream];
        timeouts.unset(stream);
        external_discovery_refresh_services.begin(pl.account, stream);
    }

    public void on_connection_state_changed(Account account, ConnectionManager.ConnectionState state) {
        switch(state)
        {
            case ConnectionManager.ConnectionState.DISCONNECTED:
                XmppStream? stream = app.stream_interactor.connection_manager.get_stream(account);
                if (stream == null) return;
                if (!timeouts.has_key(stream)) return;

                Source.remove(timeouts[stream].timeout_handle_id);
                timeouts.unset(stream);
            break;
            case ConnectionManager.ConnectionState.CONNECTED:
                XmppStream? stream = app.stream_interactor.connection_manager.get_stream(account);
                external_discovery_refresh_services(account, stream);
            break;
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