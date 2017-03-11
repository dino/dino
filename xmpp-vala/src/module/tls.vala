using Xmpp.Core;

namespace Xmpp.Tls {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-tls";

    public class Module : XmppStreamNegotiationModule {
        public const string ID = "tls_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public bool require { get; set; default = true; }
        public bool server_supports_tls = false;
        public bool server_requires_tls = false;
        public SocketConnectable? identity = null;

        public override void attach(XmppStream stream) {
            stream.received_features_node.connect(this.received_features_node);
            stream.received_nonza.connect(this.received_nonza);
        }

        public override void detach(XmppStream stream) {
            stream.received_features_node.disconnect(this.received_features_node);
            stream.received_nonza.disconnect(this.received_nonza);
        }

        private void received_nonza(XmppStream stream, StanzaNode node) {
            if (node.ns_uri == NS_URI && node.name == "proceed") {
                try {
                    var io_stream = stream.get_stream();
                    if (io_stream == null) return;
                    var conn = TlsClientConnection.new(io_stream, identity);
                    // TODO: Add certificate error handling, that is, allow the
                    // program to handle certificate errors. The certificate
                    // *is checked* by TlsClientConnection, and connection is
                    // not allowed to continue in case that there is an error.
                    stream.reset_stream(conn);

                    var flag = Flag.get_flag(stream);
                    flag.peer_certificate = conn.get_peer_certificate();
                    flag.finished = true;
                } catch (Error e) {
                    stderr.printf("Failed to start TLS: %s\n", e.message);
                }
            }
        }

        private void received_features_node(XmppStream stream) {
            if (Flag.has_flag(stream)) return;
            if (stream.is_setup_needed()) return;

            var starttls = stream.features.get_subnode("starttls", NS_URI);
            if (starttls != null) {
                server_supports_tls = true;
                if (starttls.get_subnode("required") != null || stream.features.get_all_subnodes().size == 1) {
                    server_requires_tls = true;
                }
                if (server_requires_tls || require) {
                    try {
                        stream.write(new StanzaNode.build("starttls", NS_URI).add_self_xmlns());
                    } catch (IOStreamError e) {
                        stderr.printf("Failed to request TLS: %s\n", e.message);
                    }
                }
                if (identity == null) {
                    identity = new NetworkService("xmpp-client", "tcp", stream.remote_name);
                }
                stream.add_flag(new Flag());
            }
        }

        public override bool mandatory_outstanding(XmppStream stream) {
            return require && (!Flag.has_flag(stream) || !Flag.get_flag(stream).finished);
        }

        public override bool negotiation_active(XmppStream stream) {
            return Flag.has_flag(stream) && !Flag.get_flag(stream).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

    public class Flag : XmppStreamFlag {
        public const string ID = "tls_flag";
        public TlsCertificate? peer_certificate;
        public bool finished = false;

        public static Flag? get_flag(XmppStream stream) {
            return (Flag?) stream.get_flag(NS_URI, ID);
        }

        public static bool has_flag(XmppStream stream) {
            return get_flag(stream) != null;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }
}
