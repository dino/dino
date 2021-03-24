[CCode (cprefix = "gnutls_", lower_case_cprefix = "gnutls_", cheader_filename = "gnutls/gnutls.h")]
namespace GnuTLS {

    public int global_init();

    [CCode (cname = "gnutls_pull_func", has_target = false)]
    public delegate ssize_t PullFunc(void* transport_ptr, [CCode (ctype = "void*", array_length_type="size_t")] uint8[] array);

    [CCode (cname = "gnutls_pull_timeout_func", has_target = false)]
    public delegate int PullTimeoutFunc(void* transport_ptr, uint ms);

    [CCode (cname = "gnutls_push_func", has_target = false)]
    public delegate ssize_t PushFunc(void* transport_ptr, [CCode (ctype = "void*", array_length_type="size_t")] uint8[] array);

    [CCode (cname = "gnutls_certificate_verify_function", has_target = false)]
    public delegate int VerifyFunc(Session session);

    [Compact]
    [CCode (cname = "struct gnutls_session_int", free_function = "gnutls_deinit")]
    public class Session {

        public static Session? create(int con_end) throws GLib.Error {
            Session result;
            var ret = init(out result, con_end);
            throw_if_error(ret);
            return result;
        }

        [CCode (cname = "gnutls_init")]
        private static int init(out Session session, int con_end);

        [CCode (cname = "gnutls_transport_set_push_function")]
        public void set_push_function(PushFunc func);

        [CCode (cname = "gnutls_transport_set_pull_function")]
        public void set_pull_function(PullFunc func);

        [CCode (cname = "gnutls_transport_set_pull_timeout_function")]
        public void set_pull_timeout_function(PullTimeoutFunc func);

        [CCode (cname = "gnutls_transport_set_ptr")]
        public void set_transport_pointer(void* ptr);

        [CCode (cname = "gnutls_transport_get_ptr")]
        public void* get_transport_pointer();

        [CCode (cname = "gnutls_heartbeat_enable")]
        public int enable_heartbeat(uint type);

        [CCode (cname = "gnutls_certificate_server_set_request")]
        public void server_set_request(CertificateRequest req);

        [CCode (cname = "gnutls_credentials_set")]
        public int set_credentials_(CredentialsType type, void* cred);
        [CCode (cname = "gnutls_credentials_set_")]
        public void set_credentials(CredentialsType type, void* cred) throws GLib.Error {
            int err = set_credentials_(type, cred);
            throw_if_error(err);
        }

        [CCode (cname = "gnutls_priority_set_direct")]
        public int set_priority_from_string_(string priority, out unowned string err_pos = null);
        [CCode (cname = "gnutls_priority_set_direct_")]
        public void set_priority_from_string(string priority, out unowned string err_pos = null) throws GLib.Error {
            int err = set_priority_from_string_(priority, out err_pos);
            throw_if_error(err);
        }

        [CCode (cname = "gnutls_srtp_set_profile_direct")]
        public int set_srtp_profile_direct_(string profiles, out unowned string err_pos = null);
        [CCode (cname = "gnutls_srtp_set_profile_direct_")]
        public void set_srtp_profile_direct(string profiles, out unowned string err_pos = null) throws GLib.Error {
            int err = set_srtp_profile_direct_(profiles, out err_pos);
            throw_if_error(err);
        }

        [CCode (cname = "gnutls_transport_set_int")]
        public void transport_set_int(int fd);

        [CCode (cname = "gnutls_handshake")]
        public int handshake();

        [CCode (cname = "gnutls_srtp_get_keys")]
        public int get_srtp_keys_(void *key_material, uint32 key_material_size, out Datum client_key, out Datum client_salt, out Datum server_key, out Datum server_salt);
        [CCode (cname = "gnutls_srtp_get_keys_")]
        public void get_srtp_keys(void *key_material, uint32 key_material_size, out Datum client_key, out Datum client_salt, out Datum server_key, out Datum server_salt) throws GLib.Error {
            get_srtp_keys_(key_material, key_material_size, out client_key, out client_salt, out server_key, out server_salt);
        }

        [CCode (cname = "gnutls_certificate_get_peers", array_length_type = "unsigned int")]
        public unowned Datum[]? get_peer_certificates();

        [CCode (cname = "gnutls_session_set_verify_function")]
        public void set_verify_function(VerifyFunc func);
    }

    [Compact]
    [CCode (cname = "struct gnutls_certificate_credentials_st", free_function = "gnutls_certificate_free_credentials", cprefix = "gnutls_certificate_")]
    public class CertificateCredentials {

        [CCode (cname = "gnutls_certificate_allocate_credentials")]
        private static int allocate(out CertificateCredentials credentials);

        public static CertificateCredentials create() throws GLib.Error {
            CertificateCredentials result;
            var ret = allocate (out result);
            throw_if_error(ret);
            return result;
        }

        public void get_x509_crt(uint index, [CCode (array_length_type = "unsigned int")] out unowned X509.Certificate[] x509_ca_list);

        public int set_x509_key(X509.Certificate[] cert_list, X509.PrivateKey key);
    }

    [CCode (cheader_filename = "gnutls/x509.h", cprefix = "GNUTLS_")]
    namespace X509 {

        [Compact]
        [CCode (cname = "struct gnutls_x509_crt_int", cprefix = "gnutls_x509_crt_", free_function = "gnutls_x509_crt_deinit")]
        public class Certificate {

            [CCode (cname = "gnutls_x509_crt_init")]
            private static int init (out Certificate cert);
            public static Certificate create() throws GLib.Error {
                Certificate result;
                var ret = init (out result);
                throw_if_error(ret);
                return result;
            }

            [CCode (cname = "gnutls_x509_crt_import")]
            public int import_(ref Datum data, CertificateFormat format);
            [CCode (cname = "gnutls_x509_crt_import_")]
            public void import(ref Datum data, CertificateFormat format) throws GLib.Error {
                int err = import_(ref data, format);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_set_version")]
            public int set_version_(uint version);
            [CCode (cname = "gnutls_x509_crt_set_version_")]
            public void set_version(uint version) throws GLib.Error {
                int err = set_version_(version);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_set_key")]
            public int set_key_(PrivateKey key);
            [CCode (cname = "gnutls_x509_crt_set_key_")]
            public void set_key(PrivateKey key) throws GLib.Error {
                int err = set_key_(key);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_set_activation_time")]
            public int set_activation_time_(time_t act_time);
            [CCode (cname = "gnutls_x509_crt_set_activation_time_")]
            public void set_activation_time(time_t act_time) throws GLib.Error {
                int err = set_activation_time_(act_time);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_set_expiration_time")]
            public int set_expiration_time_(time_t exp_time);
            [CCode (cname = "gnutls_x509_crt_set_expiration_time_")]
            public void set_expiration_time(time_t exp_time) throws GLib.Error {
                int err = set_expiration_time_(exp_time);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_set_serial")]
            public int set_serial_(void* serial, size_t serial_size);
            [CCode (cname = "gnutls_x509_crt_set_serial_")]
            public void set_serial(void* serial, size_t serial_size) throws GLib.Error {
                int err = set_serial_(serial, serial_size);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_sign")]
            public int sign_(Certificate issuer, PrivateKey issuer_key);
            [CCode (cname = "gnutls_x509_crt_sign_")]
            public void sign(Certificate issuer, PrivateKey issuer_key) throws GLib.Error {
                int err = sign_(issuer, issuer_key);
                throw_if_error(err);
            }

            [CCode (cname = "gnutls_x509_crt_get_fingerprint")]
            public int get_fingerprint_(DigestAlgorithm algo, void* buf, ref size_t buf_size);
            [CCode (cname = "gnutls_x509_crt_get_fingerprint_")]
            public void get_fingerprint(DigestAlgorithm algo, void* buf, ref size_t buf_size) throws GLib.Error {
                int err = get_fingerprint_(algo, buf, ref buf_size);
                throw_if_error(err);
            }
        }

        [Compact]
        [CCode (cname = "struct gnutls_x509_privkey_int", cprefix = "gnutls_x509_privkey_", free_function = "gnutls_x509_privkey_deinit")]
        public class PrivateKey {
            private static int init (out PrivateKey key);
            public static PrivateKey create () throws GLib.Error {
                PrivateKey result;
                var ret = init (out result);
                throw_if_error(ret);
                return result;
            }

            public int generate(PKAlgorithm algo, uint bits, uint flags = 0);
        }

    }

    [CCode (cname = "gnutls_certificate_request_t", cprefix = "GNUTLS_CERT_", has_type_id = false)]
    public enum CertificateRequest {
        IGNORE,
        REQUEST,
        REQUIRE
    }

    [CCode (cname = "gnutls_pk_algorithm_t", cprefix = "GNUTLS_PK_", has_type_id = false)]
    public enum PKAlgorithm {
        UNKNOWN,
        RSA,
        DSA;
    }

    [CCode (cname = "gnutls_digest_algorithm_t", cprefix = "GNUTLS_DIG_", has_type_id = false)]
    public enum DigestAlgorithm {
        NULL,
        MD5,
        SHA1,
        RMD160,
        MD2,
        SHA224,
        SHA256,
        SHA384,
        SHA512;
    }

    [Flags]
    [CCode (cname = "gnutls_init_flags_t", cprefix = "GNUTLS_", has_type_id = false)]
    public enum InitFlags {
        SERVER,
        CLIENT,
        DATAGRAM
    }

    [CCode (cname = "gnutls_credentials_type_t", cprefix = "GNUTLS_CRD_", has_type_id = false)]
    public enum CredentialsType {
        CERTIFICATE,
        ANON,
        SRP,
        PSK,
        IA
    }

    [CCode (cname = "gnutls_x509_crt_fmt_t", cprefix = "GNUTLS_X509_FMT_", has_type_id = false)]
    public enum CertificateFormat {
        DER,
        PEM
    }

    [Flags]
    [CCode (cname = "gnutls_certificate_status_t", cprefix = "GNUTLS_CERT_", has_type_id = false)]
    public enum CertificateStatus {
        INVALID,             // will be set if the certificate was not verified.
		REVOKED,             // in X.509 this will be set only if CRLs are checked
		SIGNER_NOT_FOUND,
        SIGNER_NOT_CA,
        INSECURE_ALGORITHM
    }

    [SimpleType]
    [CCode (cname = "gnutls_datum_t", has_type_id = false)]
    public struct Datum {
        public uint8* data;
        public uint size;

        public uint8[] extract() {
            uint8[size] ret = new uint8[size];
            for (int i = 0; i < size; i++) {
                ret[i] = data[i];
            }
            return ret;
        }
    }

    // Gnutls error codes. The mapping to a TLS alert is also shown in comments.
    [CCode (cname = "int", cprefix = "GNUTLS_E_", lower_case_cprefix = "gnutls_error_", has_type_id = false)]
    public enum ErrorCode {
        SUCCESS,
        UNKNOWN_COMPRESSION_ALGORITHM,
        UNKNOWN_CIPHER_TYPE,
        LARGE_PACKET,
        UNSUPPORTED_VERSION_PACKET, // GNUTLS_A_PROTOCOL_VERSION
        UNEXPECTED_PACKET_LENGTH, // GNUTLS_A_RECORD_OVERFLOW
        INVALID_SESSION,
        FATAL_ALERT_RECEIVED,
        UNEXPECTED_PACKET, // GNUTLS_A_UNEXPECTED_MESSAGE
        WARNING_ALERT_RECEIVED,
        ERROR_IN_FINISHED_PACKET,
        UNEXPECTED_HANDSHAKE_PACKET,
        UNKNOWN_CIPHER_SUITE, // GNUTLS_A_HANDSHAKE_FAILURE
        UNWANTED_ALGORITHM,
        MPI_SCAN_FAILED,
        DECRYPTION_FAILED, // GNUTLS_A_DECRYPTION_FAILED, GNUTLS_A_BAD_RECORD_MAC
        MEMORY_ERROR,
        DECOMPRESSION_FAILED, // GNUTLS_A_DECOMPRESSION_FAILURE
        COMPRESSION_FAILED,
        AGAIN,
        EXPIRED,
        DB_ERROR,
        SRP_PWD_ERROR,
        INSUFFICIENT_CREDENTIALS,
        HASH_FAILED,
        BASE64_DECODING_ERROR,
        MPI_PRINT_FAILED,
        REHANDSHAKE, // GNUTLS_A_NO_RENEGOTIATION
        GOT_APPLICATION_DATA,
        RECORD_LIMIT_REACHED,
        ENCRYPTION_FAILED,
        PK_ENCRYPTION_FAILED,
        PK_DECRYPTION_FAILED,
        PK_SIGN_FAILED,
        X509_UNSUPPORTED_CRITICAL_EXTENSION,
        KEY_USAGE_VIOLATION,
        NO_CERTIFICATE_FOUND, // GNUTLS_A_BAD_CERTIFICATE
        INVALID_REQUEST,
        SHORT_MEMORY_BUFFER,
        INTERRUPTED,
        PUSH_ERROR,
        PULL_ERROR,
        RECEIVED_ILLEGAL_PARAMETER, // GNUTLS_A_ILLEGAL_PARAMETER
        REQUESTED_DATA_NOT_AVAILABLE,
        PKCS1_WRONG_PAD,
        RECEIVED_ILLEGAL_EXTENSION,
        INTERNAL_ERROR,
        DH_PRIME_UNACCEPTABLE,
        FILE_ERROR,
        TOO_MANY_EMPTY_PACKETS,
        UNKNOWN_PK_ALGORITHM,
        // returned if libextra functionality was requested but
        // gnutls_global_init_extra() was not called.

        INIT_LIBEXTRA,
        LIBRARY_VERSION_MISMATCH,
        // returned if you need to generate temporary RSA
        // parameters. These are needed for export cipher suites.

        NO_TEMPORARY_RSA_PARAMS,
        LZO_INIT_FAILED,
        NO_COMPRESSION_ALGORITHMS,
        NO_CIPHER_SUITES,
        OPENPGP_GETKEY_FAILED,
        PK_SIG_VERIFY_FAILED,
        ILLEGAL_SRP_USERNAME,
        SRP_PWD_PARSING_ERROR,
        NO_TEMPORARY_DH_PARAMS,
        // For certificate and key stuff

        ASN1_ELEMENT_NOT_FOUND,
        ASN1_IDENTIFIER_NOT_FOUND,
        ASN1_DER_ERROR,
        ASN1_VALUE_NOT_FOUND,
        ASN1_GENERIC_ERROR,
        ASN1_VALUE_NOT_VALID,
        ASN1_TAG_ERROR,
        ASN1_TAG_IMPLICIT,
        ASN1_TYPE_ANY_ERROR,
        ASN1_SYNTAX_ERROR,
        ASN1_DER_OVERFLOW,
        OPENPGP_UID_REVOKED,
        CERTIFICATE_ERROR,
        CERTIFICATE_KEY_MISMATCH,
        UNSUPPORTED_CERTIFICATE_TYPE, // GNUTLS_A_UNSUPPORTED_CERTIFICATE
        X509_UNKNOWN_SAN,
        OPENPGP_FINGERPRINT_UNSUPPORTED,
        X509_UNSUPPORTED_ATTRIBUTE,
        UNKNOWN_HASH_ALGORITHM,
        UNKNOWN_PKCS_CONTENT_TYPE,
        UNKNOWN_PKCS_BAG_TYPE,
        INVALID_PASSWORD,
        MAC_VERIFY_FAILED, // for PKCS #12 MAC
        CONSTRAINT_ERROR,
        WARNING_IA_IPHF_RECEIVED,
        WARNING_IA_FPHF_RECEIVED,
        IA_VERIFY_FAILED,
        UNKNOWN_ALGORITHM,
        BASE64_ENCODING_ERROR,
        INCOMPATIBLE_CRYPTO_LIBRARY,
        INCOMPATIBLE_LIBTASN1_LIBRARY,
        OPENPGP_KEYRING_ERROR,
        X509_UNSUPPORTED_OID,
        RANDOM_FAILED,
        BASE64_UNEXPECTED_HEADER_ERROR,
        OPENPGP_SUBKEY_ERROR,
        CRYPTO_ALREADY_REGISTERED,
        HANDSHAKE_TOO_LARGE,
        UNIMPLEMENTED_FEATURE,
        APPLICATION_ERROR_MAX, // -65000
        APPLICATION_ERROR_MIN; // -65500

        [CCode (cname = "gnutls_error_is_fatal")]
        public bool is_fatal();

        [CCode (cname = "gnutls_perror")]
        public void print();

        [CCode (cname = "gnutls_strerror")]
        public unowned string to_string();
    }

    public void throw_if_error(int err_int) throws GLib.Error {
        ErrorCode error = (ErrorCode)err_int;
        if (error != ErrorCode.SUCCESS) {
            throw new GLib.Error(-1, error, "%s%s", error.to_string(), error.is_fatal() ? " fatal" : "");
        }
    }
}