namespace Xmpp {

    private class SrvTargetInfo {
        public string host { get; set; }
        public uint16 port { get; set; }
        public string service { get; set; }
        public uint16 priority { get; set; }
    }

    public class XmppStreamResult {
        public TlsXmppStream? stream { get; set; }
        public TlsCertificateFlags? tls_errors { get; set; }
        public IOStreamError? io_error { get; set; }
    }

    private async GLib.List<SrvTargetInfo> get_srv_targets(Jid remote) {
        // Lookup xmpp-client and xmpps-client SRV records
        GLib.List<SrvTargetInfo> targets = new GLib.List<SrvTargetInfo>();
        GLibFixes.Resolver resolver = GLibFixes.Resolver.get_default();
        try {
            GLib.List<SrvTarget> xmpp_services = yield resolver.lookup_service_async("xmpp-client", "tcp", remote.to_string(), null);
            foreach (SrvTarget service in xmpp_services) {
                targets.append(new SrvTargetInfo() { host=service.get_hostname(), port=service.get_port(), service="xmpp-client", priority=service.get_priority()});
            }
        } catch (Error e) {
            debug("Got no xmpp-client DNS records for %s: %s", remote.to_string(), e.message);
        }
        try {
            GLib.List<SrvTarget> xmpp_services = yield resolver.lookup_service_async("xmpps-client", "tcp", remote.to_string(), null);
            foreach (SrvTarget service in xmpp_services) {
                targets.append(new SrvTargetInfo() { host=service.get_hostname(), port=service.get_port(), service="xmpps-client", priority=service.get_priority()});
            }
        } catch (Error e) {
            debug("Got no xmpps-client DNS records for %s: %s", remote.to_string(), e.message);
        }

        targets.sort((a, b) => {
            return a.priority - b.priority;
        });

        // Add fallback connection
        bool should_add_fallback = true;
        foreach (SrvTargetInfo target in targets) {
            if (target.service == "xmpp-client" && target.port == 5222 && target.host == remote.to_string()) {
                should_add_fallback = false;
            }
        }
        if (should_add_fallback) {
            targets.append(new SrvTargetInfo() { host=remote.to_string(), port=5222, service="xmpp-client", priority=uint16.MAX});
        }

        return targets;
    }

    public async XmppStreamResult establish_stream(Jid bare_jid, Gee.List<XmppStreamModule> modules, string? log_options, bool? allow_cleartext, owned TlsXmppStream.OnInvalidCert on_invalid_cert) {
        TlsXmppStream.OnInvalidCertWrapper on_invalid_cert_wrapper = new TlsXmppStream.OnInvalidCertWrapper(on_invalid_cert);
        GLib.List<SrvTargetInfo> targets = yield get_srv_targets(bare_jid.domain_jid);
        if(allow_cleartext == true) {
            // Clear text connection will always have the lowest priority
            targets.append(new SrvTargetInfo() {
                host=bare_jid.domain_jid.to_string(),
                port=5222,
                service="x-cleartext-xmpp-client"
            });
        }

        // Try all connection options from lowest to highest priority
        TlsXmppStream? stream = null;
        TlsCertificateFlags? tls_errors = null;
        IOStreamError? io_error = null;
        foreach (SrvTargetInfo target in targets) {
            try {
                if (target.service == "xmpp-client") {
                    stream = new StartTlsXmppStream(bare_jid.domain_jid, target.host, target.port, on_invalid_cert_wrapper);
                } else if (target.service == "x-cleartext-xmpp-client") {
                    // "x-cleartext-xmpp-client" is not something found in real SRV records.
                    // It's a bogus service name for clear text XMPP conections, since a "real" one does not exist.
                    stream = new ClearTextXmppStream(bare_jid.domain_jid, target.host, target.port);
                } else {
                    stream = new DirectTlsXmppStream(bare_jid.domain_jid, target.host, target.port, on_invalid_cert_wrapper);
                }
                stream.log = new XmppLog(bare_jid.to_string(), log_options);

                foreach (XmppStreamModule module in modules) {
                    stream.add_module(module);
                }

                yield stream.connect();

                return new XmppStreamResult() { stream=stream };
            } catch (IOStreamError e) {
                warning("Could not establish XMPP session with %s:%i: %s", target.host, target.port, e.message);

                if (stream != null) {
                    if (stream.errors != null) {
                        tls_errors = stream.errors;
                    }
                    io_error = e;
                    stream.detach_modules();
                }
            }
        }

        return new XmppStreamResult() { io_error=io_error, tls_errors=tls_errors };
    }
}
