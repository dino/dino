using Gsasl;

namespace Xmpp.Sasl {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-sasl";
    private const string HOSTNAME_NS_URI = "urn:xmpp:domain-based-name:1";

    private class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "sasl");
        public Gsasl.Session? sasl_session;
        public bool finished = false;
        public bool sasl_needs_more = true;

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "sasl");

        public string name { get; set; }
        public string password { get; set; }
        private Gsasl.Context sasl_context;

        public signal void received_auth_failure(XmppStream stream, StanzaNode node);
        public signal void sasl_error(XmppStream stream, string description);

        public Module(string name, string password) {
            Gsasl.Result result = Gsasl.Context.init(out this.sasl_context);
            assert(result == Gsasl.Result.OK);
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
            if (node.ns_uri != NS_URI)
                return;
            if (node.name == "success") {
                Flag flag = stream.get_flag(Flag.IDENTITY);
                if (flag.sasl_needs_more) {
                    string output;
                    Gsasl.Result result = flag.sasl_session.step64(node.get_string_content(), out output);
                    if (result != Gsasl.Result.OK) {
                        stream.remove_flag(stream.get_flag(Flag.IDENTITY));
                        sasl_error(stream, result.description());
                        return;
                    }
                }
                stream.require_setup();
                flag.finished = true;
            } else if (node.name == "failure") {
                stream.remove_flag(stream.get_flag(Flag.IDENTITY));
                received_auth_failure(stream, node);
            } else if (node.name == "challenge" && stream.has_flag(Flag.IDENTITY)) {
                Flag flag = stream.get_flag(Flag.IDENTITY);
                string output;
                Gsasl.Result result = flag.sasl_session.step64(node.get_string_content(), out output);
                if (result != Gsasl.Result.OK && result != Gsasl.Result.NEEDS_MORE) {
                    stream.remove_flag(stream.get_flag(Flag.IDENTITY));
                    sasl_error(stream, result.description());
                    return;
                }
                stream.write(new StanzaNode.build("response", NS_URI).add_self_xmlns()
                            .put_node(new StanzaNode.text(output)));
                flag.sasl_needs_more = (result == Gsasl.Result.NEEDS_MORE);
            }
        }

        public void received_features_node(XmppStream stream) {
            if (stream.has_flag(Flag.IDENTITY)) return;
            if (stream.is_setup_needed()) return;
            if (!stream.has_flag(Tls.Flag.IDENTITY) || !stream.get_flag(Tls.Flag.IDENTITY).finished) return;

            var mechanisms = stream.features.get_subnode("mechanisms", NS_URI);
            string[] supported_mechanisms = {};
            foreach (var mechanism in mechanisms.sub_nodes) {
                if (mechanism.name != "mechanism" || mechanism.ns_uri != NS_URI) continue;
                supported_mechanisms += mechanism.get_string_content();
            }

            var hostname = mechanisms.get_subnode("hostname", HOSTNAME_NS_URI);

            string? suggested_mechanism = this.sasl_context.client_suggest_mechanism(string.joinv(" ", supported_mechanisms));
            if (suggested_mechanism == null) {
                stderr.printf("No supported mechanism provided by server at %s. Offered: %s\n", stream.remote_name.to_string(), string.joinv(",", supported_mechanisms));
                return;
            }

            var flag = new Flag();
            Gsasl.Result result;
            result = this.sasl_context.client_start(suggested_mechanism, out flag.sasl_session);
            if (result != Gsasl.Result.OK) {
                sasl_error(stream, result.description());
                return;
            }
            flag.sasl_session.set_property(Gsasl.Property.AUTHID, name);
            if (hostname != null) {
                flag.sasl_session.set_property(Gsasl.Property.HOSTNAME, hostname.get_string_content());
            }
            flag.sasl_session.set_property(Gsasl.Property.SERVICE, "xmpp");
            flag.sasl_session.set_property(Gsasl.Property.PASSWORD, password);
            string output;
            result = flag.sasl_session.step64(null, out output);
            if (result != Gsasl.Result.OK && result != Gsasl.Result.NEEDS_MORE) {
                sasl_error(stream, result.description());
                return;
            }
            stream.write(new StanzaNode.build("auth", NS_URI).add_self_xmlns()
                         .put_attribute("mechanism", suggested_mechanism)
                         .put_node(new StanzaNode.text(output)));
            stream.add_flag(flag);
        }

        public override bool mandatory_outstanding(XmppStream stream) {
            return !stream.has_flag(Flag.IDENTITY) || !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override bool negotiation_active(XmppStream stream) {
            return stream.has_flag(Flag.IDENTITY) && !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
