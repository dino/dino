namespace Signal {

    [CCode (cname = "int", cprefix = "SG_ERR_", cheader_filename = "signal_protocol.h", has_type_id = false)]
    public enum ErrorCode {
        [CCode (cname = "SG_SUCCESS")]
        SUCCESS,
        NOMEM,
        INVAL,
        UNKNOWN,
        DUPLICATE_MESSAGE,
        INVALID_KEY,
        INVALID_KEY_ID,
        INVALID_MAC,
        INVALID_MESSAGE,
        INVALID_VERSION,
        LEGACY_MESSAGE,
        NO_SESSION,
        STALE_KEY_EXCHANGE,
        UNTRUSTED_IDENTITY,
        VRF_SIG_VERIF_FAILED,
        INVALID_PROTO_BUF,
        FP_VERSION_MISMATCH,
        FP_IDENT_MISMATCH;
    }

    [CCode (cname = "SG_ERR_MINIMUM", cheader_filename = "signal_protocol.h")]
    public const int MIN_ERROR_CODE;

    [CCode (cname = "int", cprefix = "SG_LOG_", cheader_filename = "signal_protocol.h", has_type_id = false)]
    public enum LogLevel {
        ERROR,
        WARNING,
        NOTICE,
        INFO,
        DEBUG
    }

    [CCode (cname = "signal_throw_gerror_by_code_", cheader_filename = "signal_protocol.h")]
    private int throw_by_code(int code, string? message = null) throws GLib.Error {
        if (code < 0 && code > MIN_ERROR_CODE) {
            throw new GLib.Error(-1, code, "%s: %s", message ?? "Signal error", ((ErrorCode)code).to_string());
        }
        return code;
    }

    [CCode (cname = "int", cprefix = "SG_CIPHER_", cheader_filename = "signal_protocol.h", has_type_id = false)]
    public enum Cipher {
        AES_CTR_NOPADDING,
        AES_CBC_PKCS5,
        AES_GCM_NOPADDING
    }

    [Compact]
    [CCode (cname = "signal_type_base", ref_function="signal_type_ref_vapi", unref_function="signal_type_unref_vapi", cheader_filename="signal_protocol_types.h,signal_helper.h")]
    public class TypeBase {
    }

    [Compact]
    [CCode (cname = "signal_buffer", cheader_filename = "signal_protocol_types.h", free_function="signal_buffer_free")]
    public class Buffer {
        [CCode (cname = "signal_buffer_alloc")]
        public Buffer(size_t len);
        [CCode (cname = "signal_buffer_create")]
        public Buffer.from(uint8[] data);

        public Buffer copy();
        public Buffer append(uint8[] data);
        public int compare(Buffer other);

        public uint8 get(int i) { return data[i]; }
        public void set(int i, uint8 val) { data[i] = val; }

        public uint8[] data { get { int x = (int)len(); unowned uint8[] res = _data(); res.length = x; return res; } }

        [CCode (array_length = false, cname = "signal_buffer_data")]
        private unowned uint8[] _data();
        private size_t len();
    }

    [Compact]
    [CCode (cname = "signal_int_list", cheader_filename = "signal_protocol_types.h", free_function="signal_int_list_free")]
    public class IntList {
        [CCode (cname = "signal_int_list_alloc")]
        public IntList();
        [CCode (cname = "signal_int_list_push_back")]
        public int add(int value);
        public uint size { [CCode (cname = "signal_int_list_size")] get; }
        [CCode (cname = "signal_int_list_at")]
        public int get(uint index);
    }

    [Compact]
    [CCode (cname = "session_builder", cprefix = "session_builder_", free_function="session_builder_free", cheader_filename = "session_builder.h")]
    public class SessionBuilder {
        [CCode (cname = "session_builder_process_pre_key_bundle")]
        private int process_pre_key_bundle_(PreKeyBundle pre_key_bundle);
        [CCode (cname = "session_builder_process_pre_key_bundle_")]
        public void process_pre_key_bundle(PreKeyBundle pre_key_bundle) throws GLib.Error {
            throw_by_code(process_pre_key_bundle_(pre_key_bundle));
        }
    }

    [Compact]
    [CCode (cname = "session_pre_key_bundle", cprefix = "session_pre_key_bundle_", cheader_filename = "session_pre_key.h")]
    public class PreKeyBundle : TypeBase {
        public static int create(out PreKeyBundle bundle, uint32 registration_id, int device_id, uint32 pre_key_id, ECPublicKey? pre_key_public,
                uint32 signed_pre_key_id, ECPublicKey? signed_pre_key_public, uint8[]? signed_pre_key_signature, ECPublicKey? identity_key);
        public uint32 registration_id { get; }
        public int device_id { get; }
        public uint32 pre_key_id { get; }
        public ECPublicKey pre_key { owned get; }
        public uint32 signed_pre_key_id { get; }
        public ECPublicKey signed_pre_key { owned get; }
        public Buffer signed_pre_key_signature { owned get; }
        public ECPublicKey identity_key { owned get; }
    }

    [Compact]
    [CCode (cname = "session_pre_key", cprefix = "session_pre_key_", cheader_filename = "session_pre_key.h,signal_helper.h")]
    public class PreKeyRecord : TypeBase {
        public PreKeyRecord(uint32 id, ECKeyPair key_pair) throws GLib.Error {
            int err;
            this.new(id, key_pair, out err);
            throw_by_code(err);
        }
        [CCode (cheader_filename = "signal_helper.h")]
        private PreKeyRecord.new(uint32 id, ECKeyPair key_pair, out int err);
        private static int create(out PreKeyRecord pre_key, uint32 id, ECKeyPair key_pair);
        //public static int deserialize(out PreKeyRecord pre_key, uint8[] data, NativeContext global_context);
        [CCode (instance_pos = 2)]
        public int serialze(out Buffer buffer);
        public uint32 id { get; }
        public ECKeyPair key_pair { get; }
    }

    [Compact]
    [CCode (cname = "session_record", cprefix = "session_record_", cheader_filename = "signal_protocol_types.h")]
    public class SessionRecord : TypeBase {
        public SessionState state { get; }
    }

    [Compact]
    [CCode (cname = "session_state", cprefix = "session_state_", cheader_filename = "session_state.h")]
    public class SessionState : TypeBase {
        //public static int create(out SessionState state, NativeContext context);
        //public static int deserialize(out SessionState state, uint8[] data, NativeContext context);
        //public static int copy(out SessionState state, SessionState other_state, NativeContext context);
        [CCode (instance_pos = 2)]
        public int serialze(out Buffer buffer);

        public uint32 session_version { get; set; }
        public ECPublicKey local_identity_key { get; set; }
        public ECPublicKey remote_identity_key { get; set; }
        //public Ratchet.RootKey root_key { get; set; }
        public uint32 previous_counter { get; set; }
        public ECPublicKey sender_ratchet_key { get; }
        public ECKeyPair sender_ratchet_key_pair { get; }
        //public Ratchet.ChainKey sender_chain_key { get; set; }
        public uint32 remote_registration_id { get; set; }
        public uint32 local_registration_id { get; set; }
        public int needs_refresh { get; set; }
        public ECPublicKey alice_base_key { get; set; }
    }

    [Compact]
    [CCode (cname = "session_signed_pre_key", cprefix = "session_signed_pre_key_", cheader_filename = "session_pre_key.h")]
    public class SignedPreKeyRecord : TypeBase {
        public SignedPreKeyRecord(uint32 id, uint64 timestamp, ECKeyPair key_pair, uint8[] signature) throws GLib.Error {
            int err;
            this.new(id, timestamp, key_pair, signature, out err);
            throw_by_code(err);
        }
        [CCode (cheader_filename = "signal_helper.h")]
        private SignedPreKeyRecord.new(uint32 id, uint64 timestamp, ECKeyPair key_pair, uint8[] signature, out int err);
        private static int create(out SignedPreKeyRecord pre_key, uint32 id, uint64 timestamp, ECKeyPair key_pair, uint8[] signature);
        [CCode (instance_pos = 2)]
        public int serialze(out Buffer buffer);

        public uint32 id { get; }
        public uint64 timestamp { get; }
        public ECKeyPair key_pair { get; }
        public uint8[] signature { [CCode (cname = "session_signed_pre_key_get_signature_")] get { int x = (int)get_signature_len(); unowned uint8[] res = get_signature(); res.length = x; return res; } }

        [CCode (array_length = false, cname = "session_signed_pre_key_get_signature")]
        private unowned uint8[] get_signature();
        private size_t get_signature_len();
    }

    /**
     * Address of an Signal Protocol message recipient
     */
    [Compact]
    [CCode (cname = "signal_protocol_address", cprefix = "signal_protocol_address_", cheader_filename = "signal_protocol.h,signal_helper.h")]
    public class Address {
        public Address(string name, int32 device_id);
        public int32 device_id { get; set; }
        public string name { owned get; set; }
    }

    /**
     * A representation of a (group + sender + device) tuple
     */
    [Compact]
    [CCode (cname = "signal_protocol_sender_key_name")]
    public class SenderKeyName {
        [CCode (cname = "group_id", array_length_cname="group_id_len")]
        private char* group_id_;
        private size_t group_id_len;
        public Address sender;
    }

    [Compact]
    [CCode (cname = "ec_public_key", cprefix = "ec_public_key_", cheader_filename = "curve.h,signal_helper.h")]
    public class ECPublicKey : TypeBase {
        [CCode (cname = "curve_generate_public_key")]
        public static int generate(out ECPublicKey public_key, ECPrivateKey private_key);
        [CCode (instance_pos = 1, cname = "ec_public_key_serialize")]
        private int serialize_([CCode (pos = 0)] out Buffer buffer);
        [CCode (cname = "ec_public_key_serialize_")]
        public uint8[] serialize() throws GLib.Error {
            Buffer buffer;
            throw_by_code(serialize_(out buffer));
            return buffer.data;
        }
        public int compare(ECPublicKey other);
        public int memcmp(ECPublicKey other);
    }

    [Compact]
    [CCode (cname = "ec_private_key", cprefix = "ec_private_key_", cheader_filename = "curve.h,signal_helper.h")]
    public class ECPrivateKey : TypeBase {
        [CCode (instance_pos = 1, cname = "ec_private_key_serialize")]
        private int serialize_([CCode (pos = 0)] out Buffer buffer);
        [CCode (cname = "ec_private_key_serialize_")]
        public uint8[] serialize() throws GLib.Error {
            Buffer buffer;
            throw_by_code(serialize_(out buffer));
            return buffer.data;
        }
        public int compare(ECPublicKey other);
    }

    [Compact]
    [CCode (cname = "ec_key_pair", cprefix="ec_key_pair_", cheader_filename = "curve.h,signal_helper.h")]
    public class ECKeyPair : TypeBase {
        public static int create(out ECKeyPair key_pair, ECPublicKey public_key, ECPrivateKey private_key);
        public ECPublicKey public { get; }
        public ECPrivateKey private { get; }
    }

    [CCode (cname = "ratchet_message_keys", cheader_filename = "ratchet.h")]
    public class MessageKeys {
    }

    [Compact]
    [CCode (cname = "ratchet_identity_key_pair", cprefix = "ratchet_identity_key_pair_", cheader_filename = "ratchet.h,signal_helper.h")]
    public class IdentityKeyPair : TypeBase {
        public static int create(out IdentityKeyPair key_pair, ECPublicKey public_key, ECPrivateKey private_key);
        public int serialze(out Buffer buffer);
        public ECPublicKey public { get; }
        public ECPrivateKey private { get; }
    }

    [Compact]
    [CCode (cname = "ec_public_key_list")]
    public class PublicKeyList {}

    /**
     * The main entry point for Signal Protocol encrypt/decrypt operations.
     *
     * Once a session has been established with session_builder,
     * this class can be used for all encrypt/decrypt operations within
     * that session.
     */
    [Compact]
    [CCode (cname = "session_cipher", cprefix = "session_cipher_", cheader_filename = "session_cipher.h", free_function = "session_cipher_free")]
    public class SessionCipher {
        public void* user_data { get; set; }
        public DecryptionCallback decryption_callback { set; }
        [CCode (cname = "session_cipher_encrypt")]
        private int encrypt_(uint8[] padded_message, out CiphertextMessage encrypted_message);
        [CCode (cname = "session_cipher_encrypt_")]
        public CiphertextMessage encrypt(uint8[] padded_message) throws GLib.Error {
            CiphertextMessage res;
            throw_by_code(encrypt_(padded_message, out res));
            return res;
        }
        [CCode (cname = "session_cipher_decrypt_pre_key_signal_message")]
        private int decrypt_pre_key_signal_message_(PreKeySignalMessage ciphertext, void* decrypt_context, out Buffer plaintext);
        [CCode (cname = "session_cipher_decrypt_pre_key_signal_message_")]
        public uint8[] decrypt_pre_key_signal_message(PreKeySignalMessage ciphertext, void* decrypt_context = null) throws GLib.Error {
            Buffer res;
            throw_by_code(decrypt_pre_key_signal_message_(ciphertext, decrypt_context, out res));
            return res.data;
        }
        [CCode (cname = "session_cipher_decrypt_signal_message")]
        private int decrypt_signal_message_(SignalMessage ciphertext, void* decrypt_context, out Buffer plaintext);
        [CCode (cname = "session_cipher_decrypt_signal_message_")]
        public uint8[] decrypt_signal_message(SignalMessage ciphertext, void* decrypt_context = null) throws GLib.Error {
            Buffer res;
            throw_by_code(decrypt_signal_message_(ciphertext, decrypt_context, out res));
            return res.data;
        }
        public int get_remote_registration_id(out uint32 remote_id);
        public int get_session_version(uint32 version);

        [CCode (has_target = false)]
        public delegate int DecryptionCallback(SessionCipher cipher, Buffer plaintext, void* decrypt_context);
    }

    [CCode (cname = "int", cheader_filename = "protocol.h", has_type_id = false)]
    public enum CiphertextType {
        [CCode (cname = "CIPHERTEXT_SIGNAL_TYPE")]
        SIGNAL,
        [CCode (cname = "CIPHERTEXT_PREKEY_TYPE")]
        PREKEY,
        [CCode (cname = "CIPHERTEXT_SENDERKEY_TYPE")]
        SENDERKEY,
        [CCode (cname = "CIPHERTEXT_SENDERKEY_DISTRIBUTION_TYPE")]
        SENDERKEY_DISTRIBUTION
    }

    [Compact]
    [CCode (cname = "ciphertext_message", cprefix = "ciphertext_message_", cheader_filename = "protocol.h,signal_helper.h")]
    public abstract class CiphertextMessage : TypeBase {
        public CiphertextType type { get; }
        [CCode (cname = "ciphertext_message_get_serialized")]
        private unowned Buffer get_serialized_();
        public uint8[] serialized { [CCode (cname = "ciphertext_message_get_serialized_")] get {
            return get_serialized_().data;
        }}
    }
    [Compact]
    [CCode (cname = "signal_message", cprefix = "signal_message_", cheader_filename = "protocol.h,signal_helper.h")]
    public class SignalMessage : CiphertextMessage {
        public ECPublicKey sender_ratchet_key { get; }
        public uint8 message_version { get; }
        public uint32 counter { get; }
        public Buffer body { get; }
        //public int verify_mac(uint8 message_version, ECPublicKey sender_identity_key, ECPublicKey receiver_identity_key, uint8[] mac, NativeContext global_context);
        public static int is_legacy(uint8[] data);
    }
    [Compact]
    [CCode (cname = "pre_key_signal_message", cprefix = "pre_key_signal_message_", cheader_filename = "protocol.h,signal_helper.h")]
    public class PreKeySignalMessage : CiphertextMessage {
        public uint8 message_version { get; }
        public ECPublicKey identity_key { get; }
        public uint32 registration_id { get; }
        public uint32 pre_key_id { get; }
        public uint32 signed_pre_key_id { get; }
        public ECPublicKey base_key { get; }
        public SignalMessage signal_message { get; }
    }
    [Compact]
    [CCode (cname = "sender_key_message", cprefix = "sender_key_message_", cheader_filename = "protocol.h,signal_helper.h")]
    public class SenderKeyMessage : CiphertextMessage {
        public uint32 key_id { get; }
        public uint32 iteration { get; }
        public Buffer ciphertext { get; }
    }
    [Compact]
    [CCode (cname = "sender_key_distribution_message", cprefix = "sender_key_distribution_message_", cheader_filename = "protocol.h,signal_helper.h")]
    public class SenderKeyDistributionMessage : CiphertextMessage {
        public uint32 id { get; }
        public uint32 iteration { get; }
        public Buffer chain_key { get; }
        public ECPublicKey signature_key { get; }
    }

    [CCode (cname = "signal_vala_encrypt", cheader_filename = "signal_helper.h")]
    private static int aes_encrypt_(out Buffer output, int cipher, uint8[] key, uint8[] iv, uint8[] plaintext, void *user_data);

    [CCode (cname = "signal_vala_encrypt_")]
    public uint8[] aes_encrypt(int cipher, uint8[] key, uint8[] iv, uint8[] plaintext) throws GLib.Error {
        Buffer buf;
        throw_by_code(aes_encrypt_(out buf, cipher, key, iv, plaintext, null));
        return buf.data;
    }

    [CCode (cname = "signal_vala_decrypt", cheader_filename = "signal_helper.h")]
    private static int aes_decrypt_(out Buffer output, int cipher, uint8[] key, uint8[] iv, uint8[] ciphertext, void *user_data);

    [CCode (cname = "signal_vala_decrypt_")]
    public uint8[] aes_decrypt(int cipher, uint8[] key, uint8[] iv, uint8[] ciphertext) throws GLib.Error {
        Buffer buf;
        throw_by_code(aes_decrypt_(out buf, cipher, key, iv, ciphertext, null));
        return buf.data;
    }
}