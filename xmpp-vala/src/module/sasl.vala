namespace Xmpp.Sasl {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-sasl";

    public errordomain SaslError {
        INVALID_CHALLENGE,
        CHANNEL_BINDING,
        INVALID_SERVER_SIGNATURE,
        RANDOM
    }

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "sasl");
        public string mechanism;
        public string name;
        public string password;
        public string client_nonce;
        public uint8[] channel_binding;
        public uint8[] server_signature;
        public bool finished = false;

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    namespace Mechanism {
        public const string PLAIN = "PLAIN";
        public const string SCRAM_SHA_1 = "SCRAM-SHA-1";
        public const string SCRAM_SHA_1_PLUS = "SCRAM-SHA-1-PLUS";
        public const string SCRAM_SHA_256 = "SCRAM-SHA-256";
        public const string SCRAM_SHA_256_PLUS = "SCRAM-SHA-256-PLUS";
        public const string SCRAM_SHA_512 = "SCRAM-SHA-512";
        public const string SCRAM_SHA_512_PLUS = "SCRAM-SHA-512-PLUS";

        public bool is_scram(string mechanism) {
            return mechanism.has_prefix("SCRAM-");
        }

        public ChecksumType get_checksum_type(string mechanism) {
            if (mechanism.has_prefix(SCRAM_SHA_512)) return ChecksumType.SHA512;
            if (mechanism.has_prefix(SCRAM_SHA_256)) return ChecksumType.SHA256;
            return ChecksumType.SHA1;
        }

        public bool is_plus(string mechanism) {
            return is_scram(mechanism) && mechanism.has_suffix("-PLUS");
        }

        public string? select_scram(string[] supported_mechanisms, bool channel_binding) {
            foreach (string mechanism in new string[] { SCRAM_SHA_512_PLUS, SCRAM_SHA_256_PLUS, SCRAM_SHA_1_PLUS, SCRAM_SHA_512, SCRAM_SHA_256, SCRAM_SHA_1 }) {
                if (is_plus(mechanism) && !channel_binding) continue;
                if (mechanism in supported_mechanisms) return mechanism;
            }
            return null;
        }
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

        public void received_nonza(XmppStream stream, StanzaNode node) {
            if (node.ns_uri == NS_URI) {
                if (node.name == "success") {
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (Mechanism.is_scram(flag.mechanism)) {
                        try {
                            verify_server_signature(node.get_string_content(), flag.server_signature);
                        } catch (SaslError e) {
                            fail_authentication(stream);
                            return;
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
            string client_first_message;
            Flag? scram_flag;
            try {
                scram_flag = start_scram(stream, supported_mechanisms, name, password, out client_first_message);
            } catch (SaslError e) {
                fail_authentication(stream);
                return;
            }
            if (scram_flag != null) {
                stream.write(new StanzaNode.build("auth", NS_URI).add_self_xmlns()
                        .put_attribute("mechanism", scram_flag.mechanism)
                        .put_node(new StanzaNode.text(Base64.encode((uchar[]) client_first_message.to_utf8()))));
                stream.add_flag(scram_flag);
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

    public static uchar[] get_plain_bytes(string name_s, string password_s) {
        var name = name_s.to_utf8();
        var password = password_s.to_utf8();
        uchar[] res = new uchar[name.length + password.length + 2];
        res[0] = 0;
        res[name.length + 1] = 0;
        for(int i = 0; i < name.length; i++) { res[i + 1] = (uchar) name[i]; }
        for(int i = 0; i < password.length; i++) { res[i + name.length + 2] = (uchar) password[i]; }
        return res;
    }

    private const string CHANNEL_BINDING_NS_URI = "urn:xmpp:sasl-cb:0";

    public static Flag? start_scram(XmppStream stream, string[] supported_mechanisms, string name, string password, out string client_first_message) throws SaslError {
        client_first_message = "";
        bool server_offers_plus = false;
        foreach (string mechanism in supported_mechanisms) {
            if (Mechanism.is_plus(mechanism)) server_offers_plus = true;
        }
        StanzaNode? binding_node = stream.features.get_subnode("sasl-channel-binding", CHANNEL_BINDING_NS_URI);
        // Reject inconsistent announcements in SASL1 too, so neither feature can be stripped.
        if (server_offers_plus != (binding_node != null)) {
            throw new SaslError.CHANNEL_BINDING("Incomplete channel-binding announcement");
        }

        uint8[]? channel_binding_data = null;
        string? binding_type = null;
        foreach (string candidate in new string[] { "tls-exporter", "tls-server-end-point" }) {
            if (binding_node == null) break;
            foreach (StanzaNode type_node in binding_node.get_subnodes("channel-binding", CHANNEL_BINDING_NS_URI)) {
                if (type_node.get_attribute("type") != candidate) continue;
                channel_binding_data = get_channel_binding_data(stream, candidate == "tls-exporter" ? TlsChannelBindingType.EXPORTER : TlsChannelBindingType.SERVER_END_POINT);
                if (channel_binding_data != null) {
                    binding_type = candidate;
                    break;
                }
            }
            if (binding_type != null) break;
        }
        if (server_offers_plus && channel_binding_data == null) {
            throw new SaslError.CHANNEL_BINDING("No usable channel-binding type");
        }

        string? mechanism = Mechanism.select_scram(supported_mechanisms, channel_binding_data != null);
        if (server_offers_plus && (mechanism == null || !Mechanism.is_plus(mechanism))) {
            throw new SaslError.CHANNEL_BINDING("No supported channel-binding mechanism");
        }
        if (mechanism == null) return null;

        string gs2_header = "n,,";
        if (Mechanism.is_plus(mechanism)) {
            gs2_header = @"p=$(binding_type),,";
        } else if (get_channel_binding_data(stream, TlsChannelBindingType.EXPORTER) != null ||
                   get_channel_binding_data(stream, TlsChannelBindingType.SERVER_END_POINT) != null) {
            gs2_header = "y,,";
        }

        uint8[] channel_binding = gs2_header.data;
        if (Mechanism.is_plus(mechanism)) {
            foreach (uint8 b in channel_binding_data) channel_binding += b;
        }

        uint8[] nonce = new uint8[24];
        FileStream? random = FileStream.open("/dev/urandom", "rb");
        if (random == null || random.read(nonce) != nonce.length) throw new SaslError.RANDOM("Cannot read /dev/urandom");
        string client_nonce = Base64.encode(nonce);
        string sasl_name = name.replace("=", "=3D").replace(",", "=2C");
        client_first_message = @"$(gs2_header)n=$sasl_name,r=$client_nonce";

        var flag = new Flag();
        flag.mechanism = mechanism;
        flag.name = sasl_name;
        flag.password = password.normalize(-1, NormalizeMode.NFKC);
        flag.client_nonce = client_nonce;
        flag.channel_binding = channel_binding;
        return flag;
    }

    // The GLib binding passes the array by reference, but the function expects an allocated array to fill
    [CCode (cname = "g_tls_connection_get_channel_binding_data")]
    private extern bool tls_connection_get_channel_binding_data(TlsConnection connection, TlsChannelBindingType type, ByteArray data) throws Error;

    private static TlsConnection? get_tls_connection(XmppStream stream) {
        IoXmppStream? io_stream = stream as IoXmppStream;
        if (io_stream == null) return null;
        return io_stream.get_stream() as TlsConnection;
    }

    private static uint8[]? get_channel_binding_data(XmppStream stream, TlsChannelBindingType type) {
        TlsConnection? tls_connection = get_tls_connection(stream);
        if (tls_connection == null) return null;
        var data = new ByteArray();
        try {
            if (!tls_connection_get_channel_binding_data(tls_connection, type, data) || data.len == 0) return null;
        } catch (Error e) {
            return null;
        }
        return data.data;
    }

    public class ChallengeResponse {
        public uint8[] expected_server_signature { get; set; }
        public string response { get; set; }
    }

    public static ChallengeResponse compute_challenge_response(string challenge, string password, string client_nonce, string name, ChecksumType type, uint8[] channel_binding) throws SaslError {
        uint8[] decoded = decode_scram_base64(challenge);
        string challenge_base64 = (string) decoded;
        if (!challenge_base64.validate() || challenge_base64.length != decoded.length) {
            throw new SaslError.INVALID_CHALLENGE("Invalid challenge encoding");
        }
        string[] attributes = challenge_base64.split(",");
        if (attributes.length < 3 || !attributes[0].has_prefix("r=") ||
            !attributes[1].has_prefix("s=") || !attributes[2].has_prefix("i=")) {
            throw new SaslError.INVALID_CHALLENGE("Invalid challenge attributes");
        }
        var seen = new Gee.HashSet<string>();
        foreach (string attribute in attributes) {
            string[] pair = attribute.split("=", 2);
            if (pair.length != 2 || pair[0].length != 1 || !pair[0][0].isalpha() ||
                pair[1].length == 0 || pair[0] == "m" || !seen.add(pair[0])) {
                throw new SaslError.INVALID_CHALLENGE("Invalid or unsupported challenge attribute");
            }
        }
        string server_nonce = attributes[0].substring(2);
        if (!server_nonce.has_prefix(client_nonce) || server_nonce.length <= client_nonce.length) {
            throw new SaslError.INVALID_CHALLENGE("Invalid server nonce");
        }
        foreach (char c in server_nonce.to_utf8()) {
            if (c < 0x21 || c > 0x7e) throw new SaslError.INVALID_CHALLENGE("Invalid server nonce");
        }
        uint8[] salt = decode_scram_base64(attributes[1].substring(2));
        string iteration_string = attributes[2].substring(2);
        foreach (char c in iteration_string.to_utf8()) {
            if (!c.isdigit()) throw new SaslError.INVALID_CHALLENGE("Invalid iteration count");
        }
        uint64 iterations = 0;
        // Bound synchronous password derivation to avoid freezing on hostile challenges.
        if (iteration_string[0] == '0' || !uint64.try_parse(iteration_string, out iterations) || iterations > 1000000) {
            throw new SaslError.INVALID_CHALLENGE("Unsupported iteration count");
        }
        string client_final_message_bare = @"c=$(Base64.encode(channel_binding)),r=$server_nonce";
        uint8[] salted_password = pbkdf2(type, password, salt, (uint) iterations);
        uint8[] client_key = hmac(type, salted_password, (uint8[]) "Client Key".to_utf8());
        uint8[] stored_key = hash(type, client_key);
        string auth_message = @"n=$(name),r=$(client_nonce),$challenge_base64,$client_final_message_bare";
        uint8[] client_signature = hmac(type, stored_key, (uint8[]) auth_message.to_utf8());
        uint8[] client_proof = xor(client_key, client_signature);
        uint8[] server_key = hmac(type, salted_password, (uint8[]) "Server Key".to_utf8());

        return new ChallengeResponse() {
            expected_server_signature = hmac(type, server_key, (uint8[]) auth_message.to_utf8()),
            response = @"$client_final_message_bare,p=$(Base64.encode(client_proof))"
        };
    }

    private static uint8[] decode_scram_base64(string text) throws SaslError {
        uint8[] decoded = Base64.decode(text);
        if (decoded.length == 0 || Base64.encode(decoded) != text) {
            throw new SaslError.INVALID_CHALLENGE("Invalid base64 encoding");
        }
        return decoded;
    }

    public static void verify_server_signature(string? data, uint8[]? expected) throws SaslError {
        if (data == null || expected == null || expected.length == 0) {
            throw new SaslError.INVALID_SERVER_SIGNATURE("Missing server signature");
        }
        uint8[] decoded = decode_scram_base64(data);
        string message = (string) decoded;
        if (!message.validate() || message.length != decoded.length) {
            throw new SaslError.INVALID_SERVER_SIGNATURE("Invalid server-final encoding");
        }
        if (!message.has_prefix("v=")) throw new SaslError.INVALID_SERVER_SIGNATURE("Missing server verifier");
        string[] attributes = message.split(",");
        uint8[] signature = decode_scram_base64(attributes[0].substring(2));
        var seen = new Gee.HashSet<string>();
        seen.add("v");
        foreach (string attribute in attributes[1:attributes.length]) {
            string[] pair = attribute.split("=", 2);
            if (pair.length != 2 || pair[0].length != 1 || !pair[0][0].isalpha() ||
                pair[1].length == 0 || pair[0] == "e" || pair[0] == "m" || !seen.add(pair[0])) {
                throw new SaslError.INVALID_SERVER_SIGNATURE("Invalid server-final message");
            }
        }
        if (signature.length != expected.length) throw new SaslError.INVALID_SERVER_SIGNATURE("Invalid server signature");
        uint8 difference = 0;
        for (int i = 0; i < signature.length; i++) difference |= signature[i] ^ expected[i];
        if (difference != 0) throw new SaslError.INVALID_SERVER_SIGNATURE("Invalid server signature");
    }

    private static uint8[] hash(ChecksumType type, uint8[] data) {
        Checksum checksum = new Checksum(type);
        checksum.update(data, data.length);
        size_t size = (size_t) type.get_length();
        uint8[] res = new uint8[size];
        checksum.get_digest(res, ref size);
        return res;
    }

    private static uint8[] hmac(ChecksumType type, uint8[] key, uint8[] data) {
        Hmac mac = new Hmac(type, key);
        mac.update(data);
        size_t size = (size_t) type.get_length();
        uint8[] res = new uint8[size];
        mac.get_digest(res, ref size);
        return res;
    }

    private static uint8[] pbkdf2(ChecksumType type, string password, uint8[] salt, uint iterations) {
        size_t size = (size_t) type.get_length();
        uint8[] res = new uint8[size];
        uint8[] last = new uint8[salt.length + 4];
        for(int i = 0; i < salt.length; i++) {
            last[i] = salt[i];
        }
        last[salt.length + 3] = 1;
        for(int i = 0; i < iterations; i++) {
            last = hmac(type, (uint8[]) password.to_utf8(), last);
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
}
