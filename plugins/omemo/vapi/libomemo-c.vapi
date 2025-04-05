namespace Omemo {

    [CCode (cname = "int", cprefix = "SG_ERR_", cheader_filename = "omemo/signal_protocol.h", has_type_id = false)]
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

    [CCode (cname = "SG_ERR_MINIMUM", cheader_filename = "omemo/signal_protocol.h")]
    public const int MIN_ERROR_CODE;

    [CCode (cname = "int", cprefix = "SG_LOG_", cheader_filename = "omemo/signal_protocol.h", has_type_id = false)]
    public enum LogLevel {
        ERROR,
        WARNING,
        NOTICE,
        INFO,
        DEBUG
    }

    [CCode (cname = "signal_throw_gerror_by_code_", cheader_filename = "omemo/signal_protocol.h")]
    private int throw_by_code(int code, string? message = null) throws GLib.Error {
        if (code < 0 && code > MIN_ERROR_CODE) {
            throw new GLib.Error(-1, code, "%s: %s", message ?? "libomemo-c error", ((ErrorCode)code).to_string());
        }
        return code;
    }

    [CCode (cname = "int", cprefix = "SG_CIPHER_", cheader_filename = "omemo/signal_protocol.h", has_type_id = false)]
    public enum Cipher {
        AES_CTR_NOPADDING,
        AES_CBC_PKCS5,
        AES_GCM_NOPADDING
    }

    [Compact]
    [CCode (cname = "signal_type_base", ref_function="signal_type_ref_vapi", unref_function="signal_type_unref_vapi", cheader_filename="omemo/signal_protocol_types.h,native/helper.h")]
    public class TypeBase {
    }

    [Compact]
    [CCode (cname = "signal_buffer", cprefix = "signal_buffer_", cheader_filename = "omemo/signal_protocol_types.h", free_function="signal_buffer_free")]
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
    [CCode (cname = "signal_int_list", cheader_filename = "omemo/signal_protocol_types.h", free_function="signal_int_list_free")]
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
    [CCode (cname = "session_builder", cprefix = "session_builder_", free_function="session_builder_free", cheader_filename = "omemo/session_builder.h")]
    public class SessionBuilder {
        [CCode (cname = "session_builder_process_pre_key_bundle")]
        private int process_pre_key_bundle_(PreKeyBundle pre_key_bundle);
        [CCode (cname = "session_builder_process_pre_key_bundle_")]
        public void process_pre_key_bundle(PreKeyBundle pre_key_bundle) throws GLib.Error {
            throw_by_code(process_pre_key_bundle_(pre_key_bundle));
        }
        public int version { get; set; }
    }

    [Compact]
    [CCode (cname = "session_pre_key_bundle", cprefix = "session_pre_key_bundle_", cheader_filename = "omemo/session_pre_key.h")]
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
    [CCode (cname = "session_pre_key", cprefix = "session_pre_key_", cheader_filename = "omemo/session_pre_key.h,native/helper.h")]
    public class PreKeyRecord : TypeBase {
        public static int create(out PreKeyRecord pre_key, uint32 id, ECKeyPair key_pair);
        //public static int deserialize(out PreKeyRecord pre_key, uint8[] data, NativeContext global_context);
        [CCode (instance_pos = 2)]
        public int serialze(out Buffer buffer);
        public uint32 id { get; }
        public ECKeyPair key_pair { get; }
    }

    [Compact]
    [CCode (cname = "session_record", cprefix = "session_record_", cheader_filename = "omemo/signal_protocol_types.h")]
    public class SessionRecord : TypeBase {
        public SessionState state { get; }
        public Buffer user_record { get; }
    }

    [Compact]
    [CCode (cname = "session_state", cprefix = "session_state_", cheader_filename = "omemo/session_state.h")]
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
    [CCode (cname = "session_signed_pre_key", cprefix = "session_signed_pre_key_", cheader_filename = "omemo/session_pre_key.h")]
    public class SignedPreKeyRecord : TypeBase {
        public static int create(out SignedPreKeyRecord pre_key, uint32 id, uint64 timestamp, ECKeyPair key_pair, uint8[] signature, uint8[]? signature_omemo);
        [CCode (instance_pos = 2)]
        public int serialize(out Buffer buffer);

        public uint32 id { get; }
        public uint64 timestamp { get; }
        public ECKeyPair key_pair { get; }
        public uint8[] signature { [CCode (cname = "session_signed_pre_key_get_signature_")] get { int x = (int)get_signature_len(); unowned uint8[] res = get_signature(); res.length = x; return res; } }
        public uint8[] signature_omemo { [CCode (cname = "session_signed_pre_key_get_signature_omemo_")] get { int x = (int)get_signature_omemo_len(); unowned uint8[] res = get_signature_omemo(); res.length = x; return res; } }

        [CCode (array_length = false, cname = "session_signed_pre_key_get_signature")]
        private unowned uint8[] get_signature();
        private size_t get_signature_len();
        [CCode (array_length = false, cname = "session_signed_pre_key_get_signature_omemo")]
        private unowned uint8[] get_signature_omemo();
        private size_t get_signature_omemo_len();
    }

    /**
     * Address of an OMEMO message recipient
     */
    [Compact]
    [CCode (cname = "signal_protocol_address", cprefix = "signal_protocol_address_", cheader_filename = "omemo/signal_protocol.h,native/helper.h")]
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
    [CCode (cname = "ec_public_key", cprefix = "ec_public_key_", cheader_filename = "omemo/curve.h,native/helper.h")]
    public class ECPublicKey : TypeBase {
        [CCode (cname = "curve_generate_public_key")]
        public static int generate(out ECPublicKey public_key, ECPrivateKey private_key);
        [CCode (instance_pos = 1, cname = "ec_public_key_serialize")]
        private int serialize_([CCode (pos = 0)] out Buffer buffer);
        [CCode (cname = "ec_public_key_serialize_")]
        public uint8[] serialize() {
            Buffer buffer;
            int code = serialize_(out buffer);
            if (code < 0 && code > MIN_ERROR_CODE) {
                // Can only throw for invalid arguments or out of memory.
                GLib.assert_not_reached();
            }
            return buffer.data;
        }
        [CCode (instance_pos = 1, cname = "ec_public_key_serialize_omemo")]
        private int serialize_omemo_([CCode (pos = 0)] out Buffer buffer);
        [CCode (cname = "ec_public_key_serialize_omemo_")]
        public uint8[] serialize_omemo() {
            Buffer buffer;
            int code = serialize_omemo_(out buffer);
            if (code < 0 && code > MIN_ERROR_CODE) {
                // Can only throw for invalid arguments or out of memory.
                GLib.assert_not_reached();
            }
            return buffer.data;
        }
        public Buffer ed { owned get; }
        public Buffer mont { owned get; }
        public int compare(ECPublicKey other);
        public int memcmp(ECPublicKey other);
    }

    [Compact]
    [CCode (cname = "ec_private_key", cprefix = "ec_private_key_", cheader_filename = "omemo/curve.h,native/helper.h")]
    public class ECPrivateKey : TypeBase {
        [CCode (instance_pos = 1, cname = "ec_private_key_serialize")]
        private int serialize_([CCode (pos = 0)] out Buffer buffer);
        [CCode (cname = "ec_private_key_serialize_")]
        public uint8[] serialize() throws GLib.Error {
            Buffer buffer;
            int code = serialize_(out buffer);
            if (code < 0 && code > MIN_ERROR_CODE) {
                // Can only throw for invalid arguments or out of memory.
                GLib.assert_not_reached();
            }
            return buffer.data;
        }
        public int compare(ECPublicKey other);
    }

    [Compact]
    [CCode (cname = "ec_key_pair", cprefix="ec_key_pair_", cheader_filename = "omemo/curve.h,native/helper.h")]
    public class ECKeyPair : TypeBase {
        public static int create(out ECKeyPair key_pair, ECPublicKey public_key, ECPrivateKey private_key);
        public ECPublicKey public { get; }
        public ECPrivateKey private { get; }
    }

    [CCode (cname = "ratchet_message_keys", cheader_filename = "omemo/ratchet.h")]
    public class MessageKeys {
    }

    [Compact]
    [CCode (cname = "ratchet_identity_key_pair", cprefix = "ratchet_identity_key_pair_", cheader_filename = "omemo/ratchet.h,native/helper.h")]
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
     * The main entry point for OMEMO encrypt/decrypt operations.
     *
     * Once a session has been established with session_builder,
     * this class can be used for all encrypt/decrypt operations within
     * that session.
     */
    [Compact]
    [CCode (cname = "session_cipher", cprefix = "session_cipher_", cheader_filename = "omemo/session_cipher.h", free_function = "session_cipher_free")]
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
        private int decrypt_pre_key_message_(PreKeyOmemoMessage ciphertext, void* decrypt_context, out Buffer plaintext);
        [CCode (cname = "session_cipher_decrypt_pre_key_signal_message_")]
        public uint8[] decrypt_pre_key_message(PreKeyOmemoMessage ciphertext, void* decrypt_context = null) throws GLib.Error {
            Buffer res;
            throw_by_code(decrypt_pre_key_message_(ciphertext, decrypt_context, out res));
            return res.data;
        }
        [CCode (cname = "session_cipher_decrypt_signal_message")]
        private int decrypt_message_(OmemoMessage ciphertext, void* decrypt_context, out Buffer plaintext);
        [CCode (cname = "session_cipher_decrypt_signal_message_")]
        public uint8[] decrypt_message(OmemoMessage ciphertext, void* decrypt_context = null) throws GLib.Error {
            Buffer res;
            throw_by_code(decrypt_message_(ciphertext, decrypt_context, out res));
            return res.data;
        }
        public int get_remote_registration_id(out uint32 remote_id);
        [CCode (cname = "session_cipher_get_session_version")]
        private int get_session_version_(out uint32 version);
        [CCode (cname = "session_cipher_get_session_version_")]
        public uint32 get_session_version() throws GLib.Error {
            uint32 res;
            throw_by_code(get_session_version_(out res));
            return res;
        }
        public uint32 version { get; set; }

        [CCode (has_target = false)]
        public delegate int DecryptionCallback(SessionCipher cipher, Buffer plaintext, void* decrypt_context);
    }

    [CCode (cname = "int", cheader_filename = "omemo/protocol.h", has_type_id = false)]
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
    [CCode (cname = "ciphertext_message", cprefix = "ciphertext_message_", cheader_filename = "omemo/protocol.h,native/helper.h")]
    public abstract class CiphertextMessage : TypeBase {
        public CiphertextType type { get; }
        [CCode (cname = "ciphertext_message_get_serialized")]
        private unowned Buffer get_serialized_();
        public uint8[] serialized { [CCode (cname = "ciphertext_message_get_serialized_")] get {
            return get_serialized_().data;
        }}
    }
    [Compact]
    [CCode (cname = "signal_message", cprefix = "signal_message_", cheader_filename = "omemo/protocol.h,native/helper.h")]
    public class OmemoMessage : CiphertextMessage {
        public ECPublicKey sender_ratchet_key { get; }
        public uint8 message_version { get; }
        public uint32 counter { get; }
        public Buffer body { get; }
        //public int verify_mac(uint8 message_version, ECPublicKey sender_identity_key, ECPublicKey receiver_identity_key, uint8[] mac, NativeContext global_context);
        public static int is_legacy(uint8[] data);
    }
    [Compact]
    [CCode (cname = "pre_key_signal_message", cprefix = "pre_key_signal_message_", cheader_filename = "omemo/protocol.h,native/helper.h")]
    public class PreKeyOmemoMessage : CiphertextMessage {
        public uint8 message_version { get; }
        public ECPublicKey identity_key { get; }
        public uint32 registration_id { get; }
        public uint32 pre_key_id { get; }
        public uint32 signed_pre_key_id { get; }
        public ECPublicKey base_key { get; }
        public OmemoMessage message { get; }
    }
    [Compact]
    [CCode (cname = "sender_key_message", cprefix = "sender_key_message_", cheader_filename = "omemo/protocol.h,native/helper.h")]
    public class SenderKeyMessage : CiphertextMessage {
        public uint32 key_id { get; }
        public uint32 iteration { get; }
        public Buffer ciphertext { get; }
    }
    [Compact]
    [CCode (cname = "sender_key_distribution_message", cprefix = "sender_key_distribution_message_", cheader_filename = "omemo/protocol.h,native/helper.h")]
    public class SenderKeyDistributionMessage : CiphertextMessage {
        public uint32 id { get; }
        public uint32 iteration { get; }
        public Buffer chain_key { get; }
        public ECPublicKey signature_key { get; }
    }

    [CCode (cname = "signal_vala_encrypt", cheader_filename = "native/helper.h")]
    private static int aes_encrypt_(out Buffer output, int cipher, uint8[] key, uint8[] iv, uint8[] plaintext, void *user_data);

    [CCode (cname = "signal_vala_encrypt_")]
    public uint8[] aes_encrypt(int cipher, uint8[] key, uint8[] iv, uint8[] plaintext) throws GLib.Error {
        Buffer buf;
        throw_by_code(aes_encrypt_(out buf, cipher, key, iv, plaintext, null));
        return buf.data;
    }

    [CCode (cname = "signal_vala_decrypt", cheader_filename = "native/helper.h")]
    private static int aes_decrypt_(out Buffer output, int cipher, uint8[] key, uint8[] iv, uint8[] ciphertext, void *user_data);

    [CCode (cname = "signal_vala_decrypt_")]
    public uint8[] aes_decrypt(int cipher, uint8[] key, uint8[] iv, uint8[] ciphertext) throws GLib.Error {
        Buffer buf;
        throw_by_code(aes_decrypt_(out buf, cipher, key, iv, ciphertext, null));
        return buf.data;
    }

    [Compact]
    [CCode (cname = "signal_context", cprefix="signal_context_", free_function="signal_context_destroy", cheader_filename = "omemo/signal_protocol.h")]
    public class NativeContext {
        public static int create(out NativeContext context, void* user_data);
        public int set_crypto_provider(NativeCryptoProvider crypto_provider);
        public int set_locking_functions(LockingFunc lock, LockingFunc unlock);
        public int set_log_function(LogFunc log);
    }
    [CCode (has_target = false)]
    public delegate void LockingFunc(void* user_data);
    [CCode (has_target = false)]
    public delegate void LogFunc(LogLevel level, string message, size_t len, void* user_data);

    [Compact]
    [CCode (cname = "signal_crypto_provider", cheader_filename = "omemo/signal_protocol.h")]
    public struct NativeCryptoProvider {
        public RandomFunc random_func;
        public HmacSha256Init hmac_sha256_init_func;
        public HmacSha256Update hmac_sha256_update_func;
        public HmacSha256Final hmac_sha256_final_func;
        public HmacSha256Cleanup hmac_sha256_cleanup_func;
        public Sha512DigestInit sha512_digest_init_func;
        public Sha512DigestUpdate sha512_digest_update_func;
        public Sha512DigestFinal sha512_digest_final_func;
        public Sha512DigestCleanup sha512_digest_cleanup_func;
        public CryptFunc encrypt_func;
        public CryptFunc decrypt_func;
        public void* user_data;
    }
    [CCode (has_target = false)]
    public delegate int RandomFunc(uint8[] data, void* user_data);
    [CCode (has_target = false)]
    public delegate int HmacSha256Init(out void* hmac_context, uint8[] key, void* user_data);
    [CCode (has_target = false)]
    public delegate int HmacSha256Update(void* hmac_context, uint8[] data, void* user_data);
    [CCode (has_target = false)]
    public delegate int HmacSha256Final(void* hmac_context, out Buffer buffer, void* user_data);
    [CCode (has_target = false)]
    public delegate int HmacSha256Cleanup(void* hmac_context, void* user_data);
    [CCode (has_target = false)]
    public delegate int Sha512DigestInit(out void* digest_context, void* user_data);
    [CCode (has_target = false)]
    public delegate int Sha512DigestUpdate(void* digest_context, uint8[] data, void* user_data);
    [CCode (has_target = false)]
    public delegate int Sha512DigestFinal(void* digest_context, out Buffer buffer, void* user_data);
    [CCode (has_target = false)]
    public delegate int Sha512DigestCleanup(void* digest_context, void* user_data);
    [CCode (has_target = false)]
    public delegate int CryptFunc(out Buffer output, Cipher cipher, uint8[] key, uint8[] iv, uint8[] content, void* user_data);

    [Compact]
    [CCode (cname = "signal_protocol_session_store", cheader_filename = "omemo/signal_protocol.h")]
    public struct NativeSessionStore {
        public LoadSessionFunc load_session_func;
        public GetSubDeviceSessionsFunc get_sub_device_sessions_func;
        public StoreSessionFunc store_session_func;
        public ContainsSessionFunc contains_session_func;
        public DeleteSessionFunc delete_session_func;
        public DeleteAllSessionsFunc delete_all_sessions_func;
        public DestroyFunc destroy_func;
        public void* user_data;
    }
    [CCode (has_target = false)]
    public delegate int LoadSessionFunc(out Buffer record, out Buffer user_record, Address address, void* user_data);
    [CCode (has_target = false)]
    public delegate int GetSubDeviceSessionsFunc(out IntList sessions, [CCode (array_length_type = "size_t")] char[] name, void* user_data);
    [CCode (has_target = false)]
    public delegate int StoreSessionFunc(Address address, [CCode (array_length_type = "size_t")] uint8[] record, [CCode (array_length_type = "size_t")] uint8[] user_record, void* user_data);
    [CCode (has_target = false)]
    public delegate int ContainsSessionFunc(Address address, void* user_data);
    [CCode (has_target = false)]
    public delegate int DeleteSessionFunc(Address address, void* user_data);
    [CCode (has_target = false)]
    public delegate int DeleteAllSessionsFunc([CCode (array_length_type = "size_t")] char[] name, void* user_data);

    [Compact]
    [CCode (cname = "signal_protocol_identity_key_store", cheader_filename = "omemo/signal_protocol.h")]
    public struct NativeIdentityKeyStore {
        GetIdentityKeyPairFunc get_identity_key_pair;
        GetLocalRegistrationIdFunc get_local_registration_id;
        SaveIdentityFunc save_identity;
        IsTrustedIdentityFunc is_trusted_identity;
        DestroyFunc destroy_func;
        void* user_data;
    }
    [CCode (has_target = false)]
    public delegate int GetIdentityKeyPairFunc(out Buffer public_data, out Buffer private_data, void* user_data);
    [CCode (has_target = false)]
    public delegate int GetLocalRegistrationIdFunc(void* user_data, out uint32 registration_id);
    [CCode (has_target = false)]
    public delegate int SaveIdentityFunc(Address address, [CCode (array_length_type = "size_t")] uint8[] key, void* user_data);
    [CCode (has_target = false)]
    public delegate int IsTrustedIdentityFunc(Address address, [CCode (array_length_type = "size_t")] uint8[] key, void* user_data);

    [Compact]
    [CCode (cname = "signal_protocol_pre_key_store", cheader_filename = "omemo/signal_protocol.h")]
    public struct NativePreKeyStore {
        LoadPreKeyFunc load_pre_key;
        StorePreKeyFunc store_pre_key;
        ContainsPreKeyFunc contains_pre_key;
        RemovePreKeyFunc remove_pre_key;
        DestroyFunc destroy_func;
        void* user_data;
    }
    [CCode (has_target = false)]
    public delegate int LoadPreKeyFunc(out Buffer record, uint32 pre_key_id, void* user_data);
    [CCode (has_target = false)]
    public delegate int StorePreKeyFunc(uint32 pre_key_id, [CCode (array_length_type = "size_t")] uint8[] record, void* user_data);
    [CCode (has_target = false)]
    public delegate int ContainsPreKeyFunc(uint32 pre_key_id, void* user_data);
    [CCode (has_target = false)]
    public delegate int RemovePreKeyFunc(uint32 pre_key_id, void* user_data);


    [Compact]
    [CCode (cname = "signal_protocol_signed_pre_key_store", cheader_filename = "omemo/signal_protocol.h")]
    public struct NativeSignedPreKeyStore {
        LoadPreKeyFunc load_signed_pre_key;
        StorePreKeyFunc store_signed_pre_key;
        ContainsPreKeyFunc contains_signed_pre_key;
        RemovePreKeyFunc remove_signed_pre_key;
        DestroyFunc destroy_func;
        void* user_data;
    }


    [Compact]
    [CCode (cname = "signal_protocol_sender_key_store")]
    public struct NativeSenderKeyStore {
        StoreSenderKeyFunc store_sender_key;
        LoadSenderKeyFunc load_sender_key;
        DestroyFunc destroy_func;
        void* user_data;
    }
    [CCode (has_target = false)]
    public delegate int StoreSenderKeyFunc(SenderKeyName sender_key_name, [CCode (array_length_type = "size_t")] uint8[] record, [CCode (array_length_type = "size_t")] uint8[] user_record, void* user_data);
    [CCode (has_target = false)]
    public delegate int LoadSenderKeyFunc(out Buffer record, out Buffer user_record, SenderKeyName sender_key_name, void* user_data);

    [CCode (has_target = false)]
    public delegate void DestroyFunc(void* user_data);

    [Compact]
    [CCode (cname = "signal_protocol_store_context", cprefix = "signal_protocol_store_context_", free_function="signal_protocol_store_context_destroy", cheader_filename = "omemo/signal_protocol.h")]
    public class NativeStoreContext {
        public static int create(out NativeStoreContext context, NativeContext global_context);
        public int set_session_store(NativeSessionStore store);
        public int set_pre_key_store(NativePreKeyStore store);
        public int set_signed_pre_key_store(NativeSignedPreKeyStore store);
        public int set_identity_key_store(NativeIdentityKeyStore store);
        public int set_sender_key_store(NativeSenderKeyStore store);
    }


    [CCode (cheader_filename = "omemo/signal_protocol.h")]
    namespace Protocol {

        /**
         * Interface to the pre-key store.
         * These functions will use the callbacks in the provided
         * signal_protocol_store_context instance and operate in terms of higher level
         * library data structures.
         */
        [CCode (lower_case_cprefix = "signal_protocol_pre_key_")]
        namespace PreKey {
            public int load_key(NativeStoreContext context, out PreKeyRecord pre_key, uint32 pre_key_id);
            public int store_key(NativeStoreContext context, PreKeyRecord pre_key);
            public int contains_key(NativeStoreContext context, uint32 pre_key_id);
            public int remove_key(NativeStoreContext context, uint32 pre_key_id);
        }

        [CCode (lower_case_cprefix = "signal_protocol_signed_pre_key_")]
        namespace SignedPreKey {
            public int load_key(NativeStoreContext context, out SignedPreKeyRecord pre_key, uint32 pre_key_id);
            public int store_key(NativeStoreContext context, SignedPreKeyRecord pre_key);
            public int contains_key(NativeStoreContext context, uint32 pre_key_id);
            public int remove_key(NativeStoreContext context, uint32 pre_key_id);
        }

        /**
         * Interface to the session store.
         * These functions will use the callbacks in the provided
         * signal_protocol_store_context instance and operate in terms of higher level
         * library data structures.
         */
        [CCode (lower_case_cprefix = "signal_protocol_session_")]
        namespace Session {
             public int load_session(NativeStoreContext context, out SessionRecord record, Address address, int32 version = 3);
             public int get_sub_device_sessions(NativeStoreContext context, out IntList sessions, char[] name);
             public int store_session(NativeStoreContext context, Address address, SessionRecord record);
             public int contains_session(NativeStoreContext context, Address address);
             public int delete_session(NativeStoreContext context, Address address);
             public int delete_all_sessions(NativeStoreContext context, char[] name);
        }

        [CCode (lower_case_cprefix = "signal_protocol_identity_")]
        namespace Identity {
            public int get_key_pair(NativeStoreContext store_context, out IdentityKeyPair key_pair);
            public int get_local_registration_id(NativeStoreContext store_context, out uint32 registration_id);
            public int save_identity(NativeStoreContext store_context, Address address, ECPublicKey identity_key);
            public int is_trusted_identity(NativeStoreContext store_context, Address address, ECPublicKey identity_key);
        }

        [CCode (cheader_filename = "omemo/key_helper.h", lower_case_cprefix = "signal_protocol_key_helper_")]
        namespace KeyHelper {
            [Compact]
            [CCode (cname = "signal_protocol_key_helper_pre_key_list_node", cprefix = "signal_protocol_key_helper_key_list_", free_function="signal_protocol_key_helper_key_list_free")]
            public class PreKeyListNode {
                public PreKeyRecord element();
                public PreKeyListNode next();
            }

            public int generate_identity_key_pair(out IdentityKeyPair key_pair, NativeContext global_context);
            public int generate_registration_id(out int32 registration_id, int extended_range, NativeContext global_context);
            public int get_random_sequence(out int value, int max, NativeContext global_context);
            public int generate_pre_keys(out PreKeyListNode head, uint start, uint count, NativeContext global_context);
            public int generate_last_resort_pre_key(out PreKeyRecord pre_key, NativeContext global_context);
            public int generate_signed_pre_key(out SignedPreKeyRecord signed_pre_key, IdentityKeyPair identity_key_pair, uint32 signed_pre_key_id, uint64 timestamp, NativeContext global_context);
            public int upgrade_signed_pre_key(ref SignedPreKeyRecord signed_pre_key, IdentityKeyPair identity_key_pair, NativeContext global_context);
            public int generate_sender_signing_key(out ECKeyPair key_pair, NativeContext global_context);
            public int generate_sender_key(out Buffer key_buffer, NativeContext global_context);
            public int generate_sender_key_id(out int32 key_id, NativeContext global_context);
        }
    }

    [CCode (cheader_filename = "omemo/curve.h")]
    namespace Curve {
        [CCode (cname = "curve_calculate_agreement")]
        public int calculate_agreement([CCode (array_length = false)] out uint8[] shared_key_data, ECPublicKey public_key, ECPrivateKey private_key);
        [CCode (cname = "curve_calculate_signature")]
        public int calculate_signature(NativeContext context, out Buffer signature, ECPrivateKey signing_key, uint8[] message);
        [CCode (cname = "curve_verify_signature")]
        public int verify_signature(ECPublicKey signing_key, uint8[] message, uint8[] signature);
    }

    [CCode (cname = "session_builder_create", cheader_filename = "omemo/session_builder.h")]
    public static int session_builder_create(out SessionBuilder builder, NativeStoreContext store, Address remote_address, NativeContext global_context);
    [CCode (cname = "session_cipher_create", cheader_filename = "omemo/session_cipher.h")]
    public static int session_cipher_create(out SessionCipher cipher, NativeStoreContext store, Address remote_address, NativeContext global_context);
    [CCode (cname = "pre_key_signal_message_deserialize", cheader_filename = "omemo/protocol.h")]
    public static int pre_key_message_deserialize(out PreKeyOmemoMessage message, uint8[] data, NativeContext global_context);
    [CCode (cname = "pre_key_signal_message_deserialize_omemo", cheader_filename = "omemo/protocol.h")]
    public static int pre_key_message_deserialize_omemo(out PreKeyOmemoMessage message, uint8[] data, uint32 remote_registration_id, NativeContext global_context);
    [CCode (cname = "pre_key_signal_message_copy", cheader_filename = "omemo/protocol.h")]
    public static int pre_key_message_copy(out PreKeyOmemoMessage message, PreKeyOmemoMessage other_message, NativeContext global_context);
    [CCode (cname = "signal_message_create", cheader_filename = "omemo/protocol.h")]
    public static int message_create(out OmemoMessage message, uint8 message_version, uint8[] mac_key, ECPublicKey sender_ratchet_key, uint32 counter, uint32 previous_counter, uint8[] ciphertext, ECPublicKey sender_identity_key, ECPublicKey receiver_identity_key, NativeContext global_context);
    [CCode (cname = "signal_message_deserialize", cheader_filename = "omemo/protocol.h")]
    public static int message_deserialize(out OmemoMessage message, uint8[] data, NativeContext global_context);
    [CCode (cname = "signal_message_deserialize_omemo", cheader_filename = "omemo/protocol.h")]
    public static int message_deserialize_omemo(out OmemoMessage message, uint8[] data, NativeContext global_context);
    [CCode (cname = "signal_message_copy", cheader_filename = "omemo/protocol.h")]
    public static int message_copy(out OmemoMessage message, OmemoMessage other_message, NativeContext global_context);
    [CCode (cname = "curve_generate_key_pair", cheader_filename = "omemo/curve.h")]
    public static int curve_generate_key_pair(NativeContext context, out ECKeyPair key_pair);
    [CCode (cname = "curve_decode_private_point", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_private_point(out ECPrivateKey public_key, uint8[] key, NativeContext global_context);
    [CCode (cname = "curve_decode_point", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_point(out ECPublicKey public_key, uint8[] key, NativeContext global_context);
    [CCode (cname = "curve_decode_point_ed", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_point_ed(out ECPublicKey public_key, uint8[] key, NativeContext global_context);
    [CCode (cname = "curve_decode_point_mont", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_point_mont(out ECPublicKey public_key, uint8[] key, NativeContext global_context);
    [CCode (cname = "curve_generate_private_key", cheader_filename = "omemo/curve.h")]
    public static int curve_generate_private_key(NativeContext context, out ECPrivateKey private_key);
    [CCode (cname = "ratchet_identity_key_pair_deserialize", cheader_filename = "omemo/ratchet.h")]
    public static int ratchet_identity_key_pair_deserialize(out IdentityKeyPair key_pair, uint8[] data, NativeContext global_context);
    [CCode (cname = "session_signed_pre_key_deserialize", cheader_filename = "omemo/signed_pre_key.h")]
    public static int session_signed_pre_key_deserialize(out SignedPreKeyRecord pre_key, uint8[] data, NativeContext global_context);

    [Compact]
    [CCode (cname = "hkdf_context", cprefix = "hkdf_", free_function = "hkdf_destroy", cheader_filename = "omemo/hkdf.h")]
    public class NativeHkdfContext {
        public static int create(out NativeHkdfContext context, int message_version, NativeContext global_context);
        public int compare(NativeHkdfContext other);
        public ssize_t derive_secrets([CCode (array_length = false)] out uint8[] output, uint8[] input_key_material, uint8[] salt, uint8[] info, size_t output_len);
    }

    [CCode (cname = "setup_signal_vala_crypto_provider", cheader_filename = "native/helper.h")]
    public static void setup_crypto_provider(NativeContext context);
    [CCode (cname = "signal_vala_randomize", cheader_filename = "native/helper.h")]
    public static int native_random(uint8[] data);
}
