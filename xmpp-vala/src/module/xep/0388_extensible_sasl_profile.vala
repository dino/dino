using Gee;
using Xmpp.Sasl;

namespace Xmpp.Xep.ExtensibleSaslProfile {
    public const string NS_URI = "urn:xmpp:sasl:2";

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "sasl2");

        public HashMap<string, Sasl2InlineActivation> inline_activation_providers = new HashMap<string, Sasl2InlineActivation>();

        public string name { get; set; }
        public string password { get; set; }
        public string user_agent_id { get; set; }
        public string? user_agent_software { get; set; default = "Dino"; }
        public string? user_agent_device { get; set; }

        public signal void received_auth_failure(XmppStream stream, StanzaNode node);

        public Module(string name, string password, string user_agent_id) {
            this.name = name;
            this.password = password;
            this.user_agent_id = user_agent_id;
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
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (Mechanism.is_scram(flag.mechanism)) {
                        var additional_data = node.get_subnode("additional-data", NS_URI);
                        try {
                            verify_server_signature(additional_data == null ? null : additional_data.get_string_content(), flag.server_signature);
                        } catch (SaslError e) {
                            fail_authentication(stream);
                            return;
                        }
                    }
                    flag.password = null; // Remove password from memory
                    flag.finished = true;

                    stream.expect_further_negotiation_stanzas = true;

                    var authorisation_identifier = node.get_subnode("authorization-identifier", NS_URI);
                    string jid_string = authorisation_identifier != null ? authorisation_identifier.get_string_content() : "";
                    try {
                        Jid jid = Jid.from_string(jid_string);

                        foreach (var inline_provider in inline_activation_providers.values) {
                            inline_provider.on_bound(stream, jid, node);
                        }
                    } catch (InvalidJidError e) {
                        warning("Server provided invalid authorization-identifier \"%s\": %s", jid_string, e.message);
                    }
                } else if (node.name == "challenge" && stream.has_flag(Flag.IDENTITY)) {
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (Mechanism.is_scram(flag.mechanism)) {
                        try {
                            var challenge_response = compute_challenge_response(node.get_string_content(), flag.password, flag.client_nonce, flag.name, Mechanism.get_checksum_type(flag.mechanism), flag.channel_binding);
                            flag.server_signature = challenge_response.expected_server_signature;
                            stream.write(new StanzaNode.build("response", NS_URI).add_self_xmlns()
                                    .put_node(new StanzaNode.text(Base64.encode((uchar[]) (challenge_response.response).to_utf8()))));
                        } catch (SaslError e) {
                            stream.write(new StanzaNode.build("abort", NS_URI).add_self_xmlns());
                            fail_authentication(stream);
                        }
                    }
                } else if (node.name == "failure") {
                    stream.remove_flag(stream.get_flag(Flag.IDENTITY));
                    received_auth_failure(stream, node);
                }
            }
        }

        public void received_features_node(XmppStream stream) {
            if (stream.has_flag(Flag.IDENTITY)) return;
            if (stream.is_setup_needed()) return;

            var authentication_node = stream.features.get_subnode("authentication", NS_URI);
            if (authentication_node == null) return;

            var mechanism_nodes = authentication_node.get_subnodes("mechanism", NS_URI);
            string[] supported_mechanisms = {};
            foreach (var mechanism in mechanism_nodes) {
                supported_mechanisms += mechanism.get_string_content();
            }

            var authenticate_node = new StanzaNode.build("authenticate", NS_URI).add_self_xmlns();

            string client_first_message;
            Flag? scram_flag;
            try {
                scram_flag = start_scram(stream, supported_mechanisms, name, password, out client_first_message);
            } catch (SaslError e) {
                fail_authentication(stream);
                return;
            }
            if (scram_flag != null) {
                string response = Base64.encode((uchar[]) client_first_message.to_utf8());
                authenticate_node
                        .put_attribute("mechanism", scram_flag.mechanism)
                        .put_node(new StanzaNode.build("initial-response", NS_URI).put_node(new StanzaNode.text(response)));
                stream.add_flag(scram_flag);
            } else if (Mechanism.PLAIN in supported_mechanisms) {
                authenticate_node
                        .put_attribute("mechanism", Mechanism.PLAIN)
                        .put_node(new StanzaNode.build("initial-response", NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(get_plain_bytes(name, password)))));
                var flag = new Flag();
                flag.mechanism = Mechanism.PLAIN;
                flag.name = name;
                stream.add_flag(flag);
            }

            StanzaNode? inline_node = authentication_node.get_subnode("inline", NS_URI);
            if (inline_node != null) {
                StanzaNode[] inline_activation_nodes = {};
                foreach (StanzaNode inline_feature_node in inline_node.sub_nodes) {
                    if (inline_activation_providers.has_key(inline_feature_node.ns_uri)) {
                        var activation_node = inline_activation_providers[inline_feature_node.ns_uri].get_activation_node(stream, inline_node);
                        if (activation_node != null) {
                            inline_activation_nodes += activation_node;
                        }
                    }
                }

                foreach (var inline_activation_node in inline_activation_nodes) {
                    authenticate_node.put_node(inline_activation_node);
                }
            }

            StanzaNode user_agent_node = new StanzaNode.build("user-agent", NS_URI).put_attribute("id", user_agent_id);
            if (user_agent_software != null) user_agent_node.put_node(new StanzaNode.build("software", NS_URI).put_node(new StanzaNode.text(user_agent_software)));
            if (user_agent_device != null) user_agent_node.put_node(new StanzaNode.build("device", NS_URI).put_node(new StanzaNode.text(user_agent_device)));
            authenticate_node.put_node(user_agent_node);

            stream.write(authenticate_node);
        }

        private void fail_authentication(XmppStream stream) {
            Flag? flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) {
                flag.password = null;
                stream.remove_flag(flag);
            }
            received_auth_failure(stream, new StanzaNode.build("failure", NS_URI)
                    .put_node(new StanzaNode.build("not-authorized", NS_URI)));
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

    public abstract class Sasl2InlineActivation : Object {
        public abstract StanzaNode? get_activation_node(XmppStream stream, StanzaNode inline_node);
        public abstract void on_bound(XmppStream stream, Jid authorization_identifier, StanzaNode success_node);
    }
}
