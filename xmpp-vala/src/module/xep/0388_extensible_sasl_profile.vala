using Gee;
using Xmpp.Sasl;

namespace Xmpp.Xep.ExtensibleSaslProfile {
    public const string NS_URI = "urn:xmpp:sasl:2";

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "sasl2");

        public HashMap<string, Sasl2InlineActivation> inline_activation_providers = new HashMap<string, Sasl2InlineActivation>();

        public string name { get; set; }
        public string password { get; set; }

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
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    flag.password = null; // Remove password from memory
                    flag.finished = true;

                    stream.expect_further_negotiation_stanzas = true;

                    var authorisation_identifier = node.get_subnode("authorization-identifier", NS_URI);
                    string jid_string = authorisation_identifier.get_string_content();
                    Jid jid = new Jid(jid_string);

                    foreach (var inline_provider in inline_activation_providers.values) {
                        inline_provider.on_bound(stream, jid, node);
                    }
                } else if (node.name == "challenge" && stream.has_flag(Flag.IDENTITY)) {
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (flag.mechanism == Mechanism.SCRAM_SHA_1) {
                        var challenge_response = compute_challenge_response(node.get_string_content(), flag.password, flag.client_nonce, flag.name);
                        flag.server_signature = challenge_response.expected_server_signature;
                        stream.write(new StanzaNode.build("response", NS_URI).add_self_xmlns()
                                .put_node(new StanzaNode.text(Base64.encode((uchar[]) (challenge_response.response).to_utf8()))));
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

            if (Mechanism.SCRAM_SHA_1 in supported_mechanisms) {
                string normalized_password = password.normalize(-1, NormalizeMode.NFKC);
                string client_nonce = Random.next_int().to_string("%.8x") + Random.next_int().to_string("%.8x") + Random.next_int().to_string("%.8x");
                string initial_message = @"n=$name,r=$client_nonce";
                string response = Base64.encode((uchar[]) ("n,,"+initial_message).to_utf8());
                authenticate_node
                        .put_attribute("mechanism", Mechanism.SCRAM_SHA_1)
                        .put_node(new StanzaNode.build("initial-response", NS_URI).put_node(new StanzaNode.text(response)));
                var flag = new Flag();
                flag.mechanism = Mechanism.SCRAM_SHA_1;
                flag.name = name;
                flag.password = normalized_password;
                flag.client_nonce = client_nonce;
                stream.add_flag(flag);
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

            stream.write(authenticate_node);
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
