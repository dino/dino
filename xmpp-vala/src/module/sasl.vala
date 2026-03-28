namespace Xmpp.Sasl {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-sasl";

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "sasl");
        public string mechanism;
        public string name;
        public string password;
        public string client_nonce;
        public uint8[] server_signature;
        public bool finished = false;

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    namespace Mechanism {
        public const string PLAIN = "PLAIN";
        public const string SCRAM_SHA_1 = "SCRAM-SHA-1";
        public const string SCRAM_SHA_1_PLUS = "SCRAM-SHA-1-PLUS";
    }

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "sasl");

        public string name { get; set; }
        public string password { get; set; }
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

        private static size_t SHA1_SIZE = 20;

        private static uint8[] sha1(uint8[] data) {
            Checksum checksum = new Checksum(ChecksumType.SHA1);
            checksum.update(data, data.length);
            uint8[] res = new uint8[SHA1_SIZE];
            checksum.get_digest(res, ref SHA1_SIZE);
            return res;
        }

        private static uint8[] hmac_sha1(uint8[] key, uint8[] data) {
            Hmac hmac = new Hmac(ChecksumType.SHA1, key);
            hmac.update(data);
            uint8[] res = new uint8[SHA1_SIZE];
            hmac.get_digest(res, ref SHA1_SIZE);
            return res;
        }

        private static uint8[] pbkdf2_sha1(string password, uint8[] salt, uint iterations) {
            uint8[] res = new uint8[SHA1_SIZE];
            uint8[] last = new uint8[salt.length + 4];
            for(int i = 0; i < salt.length; i++) {
                last[i] = salt[i];
            }
            last[salt.length + 3] = 1;
            for(int i = 0; i < iterations; i++) {
                last = hmac_sha1((uint8[]) password.to_utf8(), last);
                xor_inplace(res, last);
            }
            return res;
        }

        private static void xor_inplace(uint8[] mix, uint8[] a2) {
            for(int i = 0; i < mix.length; i++) {
                mix[i] = mix[i] ^ a2[i];
            }
        }

        private static uint8[] xor(uint8[] a1, uint8[] a2) {
            uint8[] mix = new uint8[a1.length];
            for(int i = 0; i < a1.length; i++) {
                mix[i] = a1[i] ^ a2[i];
            }
            return mix;
        }

        public void received_nonza(XmppStream stream, StanzaNode node) {
            if (node.ns_uri == NS_URI) {
                if (node.name == "success") {
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (flag.mechanism == Mechanism.SCRAM_SHA_1) {
                        string confirm = (string) Base64.decode(node.get_string_content());
                        uint8[] server_signature = null;
                        foreach(string c in confirm.split(",")) {
                            string[] split = c.split("=", 2);
                            if (split.length != 2) continue;
                            switch(split[0]) {
                                case "v": server_signature = Base64.decode(split[1]); break;
                            }
                        }
                        if (server_signature == null) return;
                        if (server_signature.length != flag.server_signature.length) return;
                        for(int i = 0; i < server_signature.length; i++) {
                            if (server_signature[i] != flag.server_signature[i]) return;
                        }
                    }
                    stream.require_setup();
                    flag.password = null; // Remove password from memory
                    flag.finished = true;
                } else if (node.name == "failure") {
                    stream.remove_flag(stream.get_flag(Flag.IDENTITY));
                    received_auth_failure(stream, node);
                } else if (node.name == "challenge" && stream.has_flag(Flag.IDENTITY)) {
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (flag.mechanism == Mechanism.SCRAM_SHA_1) {
                        string challenge = (string) Base64.decode(node.get_string_content());
                        string? server_nonce = null;
                        uint8[] salt = null;
                        uint iterations = 0;
                        foreach(string c in challenge.split(",")) {
                            string[] split = c.split("=", 2);
                            if (split.length != 2) continue;
                            switch(split[0]) {
                                case "r": server_nonce = split[1]; break;
                                case "s": salt = Base64.decode(split[1]); break;
                                case "i": iterations = int.parse(split[1]); break;
                            }
                        }
                        if (server_nonce == null || salt == null || iterations == 0) return;
                        if (!server_nonce.has_prefix(flag.client_nonce)) return;
                        string client_final_message_bare = @"c=biws,r=$server_nonce";
                        uint8[] salted_password = pbkdf2_sha1(flag.password, salt, iterations);
                        uint8[] client_key = hmac_sha1(salted_password, (uint8[]) "Client Key".to_utf8());
                        uint8[] stored_key = sha1(client_key);
                        string auth_message = @"n=$(flag.name),r=$(flag.client_nonce),$challenge,$client_final_message_bare";
                        uint8[] client_signature = hmac_sha1(stored_key, (uint8[]) auth_message.to_utf8());
                        uint8[] client_proof = xor(client_key, client_signature);
                        uint8[] server_key = hmac_sha1(salted_password, (uint8[]) "Server Key".to_utf8());
                        flag.server_signature = hmac_sha1(server_key, (uint8[]) auth_message.to_utf8());
                        string client_final_message = @"$client_final_message_bare,p=$(Base64.encode(client_proof))";
                        stream.write(new StanzaNode.build("response", NS_URI).add_self_xmlns()
                                .put_node(new StanzaNode.text(Base64.encode((uchar[]) (client_final_message).to_utf8()))));
                    }
                }
            }
        }

        public void received_features_node(XmppStream stream) {
            if (stream.has_flag(Flag.IDENTITY)) return;
            if (stream.is_setup_needed()) return;

            var mechanisms = stream.features.get_subnode("mechanisms", NS_URI);
            string[] supported_mechanisms = {};
            foreach (var mechanism in mechanisms.sub_nodes) {
                if (mechanism.name != "mechanism" || mechanism.ns_uri != NS_URI) continue;
                supported_mechanisms += mechanism.get_string_content();
            }
            if (!name.contains("@")) {
                name = "%s@%s".printf(name, stream.remote_name.to_string());
            }
            if (!use_full_name && name.contains("@")) {
                var split = name.split("@");
                if (split[1] == stream.remote_name.to_string()) {
                    name = split[0];
                } else {
                    use_full_name = true;
                }
            }
            string name = this.name;
            if (!use_full_name && name.contains("@")) {
                var split = name.split("@");
                if (split[1] == stream.remote_name.to_string()) {
                    name = split[0];
                }
            }
            if (Mechanism.SCRAM_SHA_1 in supported_mechanisms) {
                string normalized_password = password.normalize(-1, NormalizeMode.NFKC);
                string client_nonce = Random.next_int().to_string("%.8x") + Random.next_int().to_string("%.8x") + Random.next_int().to_string("%.8x");
                string initial_message = @"n=$name,r=$client_nonce";
                stream.write(new StanzaNode.build("auth", NS_URI).add_self_xmlns()
                        .put_attribute("mechanism", Mechanism.SCRAM_SHA_1)
                        .put_node(new StanzaNode.text(Base64.encode((uchar[]) ("n,,"+initial_message).to_utf8()))));
                var flag = new Flag();
                flag.mechanism = Mechanism.SCRAM_SHA_1;
                flag.name = name;
                flag.password = normalized_password;
                flag.client_nonce = client_nonce;
                stream.add_flag(flag);
            } else if (Mechanism.PLAIN in supported_mechanisms) {
                stream.write(new StanzaNode.build("auth", NS_URI).add_self_xmlns()
                                    .put_attribute("mechanism", Mechanism.PLAIN)
                                    .put_node(new StanzaNode.text(Base64.encode(get_plain_bytes(name, password)))));
                var flag = new Flag();
                flag.mechanism = Mechanism.PLAIN;
                flag.name = name;
                stream.add_flag(flag);
            } else {
                stderr.printf("No supported mechanism provided by server at %s\n", stream.remote_name.to_string());
                return;
            }
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
            return !stream.has_flag(Flag.IDENTITY) || !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override bool negotiation_active(XmppStream stream) {
            return stream.has_flag(Flag.IDENTITY) && !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
