using Xmpp.Core;

namespace Xmpp.PlainSasl {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-sasl";

    public class Module : XmppStreamNegotiationModule {
        public const string ID = "plain_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);
        private const string MECHANISM = "PLAIN";

        private string name;
        private string password;
        public bool use_full_name = false;

        public signal void received_auth_failure(XmppStream stream, StanzaNode node);

        public Module(string name, string password) {
            this.name = name;
            this.password = password;
        }

        public override void attach(XmppStream stream) {
            stream.received_features_node.connect(this.received_features_node);
            stream.received_nonza.connect(this.received_nonza);
        }

        public override void detach(XmppStream stream) {
            stream.received_features_node.disconnect(this.received_features_node);
            stream.received_nonza.disconnect(this.received_nonza);
        }

        public void received_nonza(XmppStream stream, StanzaNode node) {
            if (node.ns_uri == NS_URI) {
                if (node.name == "success") {
                    stream.require_setup();
                    Flag.get_flag(stream).finished = true;
                } else if (node.name == "failure") {
                    stream.remove_flag(Flag.get_flag(stream));
                    received_auth_failure(stream, node);
                }
            }
        }

        public void received_features_node(XmppStream stream) {
            if (Flag.has_flag(stream)) return;
            if (stream.is_setup_needed()) return;
            if (!Tls.Flag.has_flag(stream) || !Tls.Flag.get_flag(stream).finished) return;

            var mechanisms = stream.features.get_subnode("mechanisms", NS_URI);
            if (mechanisms != null) {
                bool supportsPlain = false;
                foreach (var mechanism in mechanisms.sub_nodes) {
                    if (mechanism.name != "mechanism" || mechanism.ns_uri != NS_URI) continue;
                    var text = mechanism.get_subnode("#text");
                    if (text != null && text.val == MECHANISM) {
                        supportsPlain = true;
                    }
                }
                if (!supportsPlain) {
                    stderr.printf("Server at %s does not support %s auth, use full-features Sasl implementation!\n", stream.remote_name, MECHANISM);
                    return;
                }

                if (!name.contains("@")) {
                    name = "%s@%s".printf(name, stream.remote_name);
                }
                if (!use_full_name && name.contains("@")) {
                    var split = name.split("@");
                    if (split[1] == stream.remote_name) {
                        name = split[0];
                    } else {
                        use_full_name = true;
                    }
                }
                var name = this.name;
                if (!use_full_name && name.contains("@")) {
                    var split = name.split("@");
                    if (split[1] == stream.remote_name) {
                        name = split[0];
                    }
                }
                stream.write(new StanzaNode.build("auth", NS_URI).add_self_xmlns()
                                    .put_attribute("mechanism", MECHANISM)
                                    .put_node(new StanzaNode.text(Base64.encode(get_plain_bytes(name, password)))));
                var flag = new Flag();
                flag.mechanism = MECHANISM;
                flag.name = name;
                stream.add_flag(flag);
            }
        }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stderr.printf("PlainSaslModule required but not attached!\n");
        }

        private static uchar[] get_plain_bytes(string name_s, string password_s) {
            var name = name_s.to_utf8();
            var password = password_s.to_utf8();
            uchar[] res = new uchar[name.length + password.length + 2];
            res[0] = 0;
            res[name.length + 1] = 0;
            for(int i = 0; i < name.length; i++) { res[i + 1] = (uchar) name[i]; }
            for(int i = 0; i < password.length; i++) { res[i + name.length + 2] = (uchar) password[i]; }
            return res;
        }

        public override bool mandatory_outstanding(XmppStream stream) {
            return !Flag.has_flag(stream) || !Flag.get_flag(stream).finished;
        }

        public override bool negotiation_active(XmppStream stream) {
            return Flag.has_flag(stream) && !Flag.get_flag(stream).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

    public class Flag : XmppStreamFlag {
        public const string ID = "sasl";
        public string mechanism;
        public string name;
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
