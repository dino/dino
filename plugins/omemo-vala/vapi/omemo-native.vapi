namespace Omemo {
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
             public int load_session(NativeStoreContext context, out SessionRecord record, Address address, int32 version = 2);
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
    public static int pre_key_signal_message_deserialize(out PreKeySignalMessage message, uint8[] data, NativeContext global_context);
    [CCode (cname = "pre_key_signal_message_copy", cheader_filename = "omemo/protocol.h")]
    public static int pre_key_signal_message_copy(out PreKeySignalMessage message, PreKeySignalMessage other_message, NativeContext global_context);
    [CCode (cname = "signal_message_create", cheader_filename = "omemo/protocol.h")]
    public static int signal_message_create(out SignalMessage message, uint8 message_version, uint8[] mac_key, ECPublicKey sender_ratchet_key, uint32 counter, uint32 previous_counter, uint8[] ciphertext, ECPublicKey sender_identity_key, ECPublicKey receiver_identity_key, NativeContext global_context);
    [CCode (cname = "signal_message_deserialize", cheader_filename = "omemo/protocol.h")]
    public static int signal_message_deserialize(out SignalMessage message, uint8[] data, NativeContext global_context);
    [CCode (cname = "signal_message_copy", cheader_filename = "omemo/protocol.h")]
    public static int signal_message_copy(out SignalMessage message, SignalMessage other_message, NativeContext global_context);
    [CCode (cname = "curve_generate_key_pair", cheader_filename = "omemo/curve.h")]
    public static int curve_generate_key_pair(NativeContext context, out ECKeyPair key_pair);
    [CCode (cname = "curve_decode_private_point", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_private_point(out ECPrivateKey public_key, uint8[] key, NativeContext global_context);
    [CCode (cname = "curve_decode_point", cheader_filename = "omemo/curve.h")]
    public static int curve_decode_point(out ECPublicKey public_key, uint8[] key, NativeContext global_context);
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

    [CCode (cname = "setup_signal_vala_crypto_provider", cheader_filename = "signal_helper.h")]
    public static void setup_crypto_provider(NativeContext context);
    [CCode (cname = "signal_vala_randomize", cheader_filename = "signal_helper.h")]
    public static int native_random(uint8[] data);
}
