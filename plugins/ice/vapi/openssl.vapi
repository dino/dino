[CCode (cprefix = "")]
namespace OpenSSL {
    [CCode (cprefix = "ASN1_", lower_case_cprefix = "ASN1_", cheader_filename = "openssl/asn1.h")]
    namespace ASN1 {
        [Compact]
        [CCode (cname = "ASN1_INTEGER", lower_case_cprefix = "ASN1_INTEGER_", cprefix = "ASN1_INTEGER_", free_function = "ASN1_INTEGER_free")]
        public class Integer {
            public bool @set (long v);
        }

        [Compact]
        [CCode (cname = "ASN1_TIME", lower_case_cprefix = "ASN1_TIME_", cprefix = "ASN1_TIME_", copy_function = "ASN1_TIME_dup", free_function = "ASN1_STRING_free")]
        public class Time {
            public bool @set (time_t t);
        }
    }
    [Compact]
    [CCode (cname = "BIO", lower_case_cprefix = "BIO_", cprefix = "BIO_", ref_function = "BIO_up_ref", ref_function_void = true, unref_function = "BIO_free", cheader_filename = "openssl/bio.h", simple_generics = true)]
    public class BIO<T> {
        [Compact]
        [CCode (cname = "BIO_METHOD", lower_case_cprefix = "BIO_meth_", cprefix = "BIO_meth_", unref_function = "BIO_meth_free", simple_generics = true)]
        public class Method<T> {
            public Method (Type type, string name);
            [CCode (has_target = false)]
            public delegate int WriteFunc<T> (BIO<T> bio, [CCode (type = "const char *", array_length_type = "int")] uint8[] buf);
            [CCode (has_target = false)]
            public delegate int ReadFunc<T> (BIO<T> bio, [CCode (type = "char *", array_length_type = "int")] uint8[] out_buf);
            [CCode (has_target = false, simple_generics = true)]
            public delegate long CtrlFunc<T> (BIO<T> bio, ControlCommand cmd, long num, void* ptr);
            public WriteFunc<T> write { get; set; }
            public ReadFunc<T> read { get; set; }
            public CtrlFunc<T> ctrl { get; set; }
        }

        [Flags]
        [CCode (cname = "int")]
        public enum Type {
            SOURCE_SINK,
            DGRAM,
        }

        [CCode (cname = "int", cprefix = "BIO_CTRL_", has_type_id = false)]
        public enum ControlCommand {
            RESET,
            EOF,
            SET,
            GET,
            PUSH,
            POP,
            GET_CLOSE,
            SET_CLOSE,
            PENDING,
            FLUSH,
            DUP,
            WPENDING,

            DGRAM_QUERY_MTU,
            DGRAM_GET_MTU,
            DGRAM_SET_MTU,
            DGRAM_SET_PEER,
            DGRAM_SET_NEXT_TIMEOUT,
            DGRAM_GET_PEER,
            DGRAM_GET_FALLBACK_MTU,
            DGRAM_SET_DONT_FRAG,
            DGRAM_GET_MTU_OVERHEAD,
        }

        public BIO (Method<T> type);
        public T data { get; set; }

        public void clear_retry_flags ();
        public void set_retry_read ();
        public bool should_read ();
    }

    [CCode (cprefix = "ERR_", lower_case_cprefix = "ERR_", cheader_filename = "openssl/err.h")]
    namespace ERR {
        public ulong get_error ();
        public unowned string lib_error_string (ulong error);
        public unowned string reason_error_string (ulong error);
    }

    [CCode (cprefix = "EVP_", lower_case_cprefix = "EVP_", cheader_filename = "openssl/evp.h")]
    namespace EVP {
        [Compact]
        [CCode (cname = "EVP_PKEY", lower_case_cprefix = "EVP_PKEY_", cprefix = "EVP_PKEY_", ref_function = "EVP_PKEY_up_ref", ref_function_void = true, unref_function = "EVP_PKEY_free")]
        public class Key {
            public Key ();
            [CCode (cheader_filename = "openssl_utils.h")]
            public Key.generate_ecdsa (string curve);
        }
        [Compact]
        [CCode (cname = "EVP_MD", lower_case_cprefix = "EVP_MD_", cprefix = "EVP_MD_", ref_function = "EVP_MD_up_ref", ref_function_void = true, unref_function = "EVP_MD_free")]
        public class MessageDigest {
        }

        public static unowned MessageDigest sha256 ();
    }

    [Compact]
    [CCode (cname = "SSL", lower_case_cprefix = "SSL_", cprefix = "SSL_", ref_function = "SSL_up_ref", ref_function_void = true, unref_function = "SSL_free", cheader_filename = "openssl/ssl.h")]
    class SSL {
        [Compact]
        [CCode (cname = "SSL_CTX", lower_case_cprefix = "SSL_CTX_", cprefix = "SSL_CTX_", ref_function = "SSL_CTX_up_ref", ref_function_void = true, unref_function = "SSL_CTX_free")]
        public class Context {
            public Context (Method method);
            public int set_tlsext_use_srtp (string profiles);
            public int use_certificate (X509.Certificate certificate);
            [CCode (cname = "SSL_CTX_use_PrivateKey")]
            public int use_private_key (EVP.Key private_key);
        }

        [CCode (cname = "const SSL_METHOD*")]
        public enum Method {
            [CCode (cname = "DTLS_client_method()")]
            DTLS_CLIENT,
            [CCode (cname = "DTLS_server_method()")]
            DTLS_SERVER,
        }

        [CCode (cname = "int", has_type_id = false)]
        public enum Error {
            NONE,
            ZERO_RETURN,
            WANT_READ,
            WANT_WRITE,
            WANT_CONNECT,
            WANT_ACCEPT,
            WANT_X509_LOOKUP,
            WANT_ASYNC,
            WANT_ASYNC_JOB,
            WANT_CLIENT_HELLO_CB,
            SYSCALL,
            SSL
        }

        public SSL (Context context);
        public BIO rbio { get; [CCode (cname="SSL_set0_rbio")] owned set; }
        public BIO wbio { get; [CCode (cname="SSL_set0_wbio")] owned set; }

        [CCode (cname = "SSL_do_handshake")]
        private int do_handshake_ ();
        [CCode (cname = "SSL_do_handshake_")]
        public Error do_handshake () throws GLib.Error {
            int ret = throw_if_error (do_handshake_ ());
            return get_error (ret);
        }
        [CCode (cname = "SSL_export_keying_material")]
        private int export_keying_material_ (uint8[] out, string label, size_t llen, [CCode (type = "const unsigned char *")] string context, size_t contextlen, bool use_context);
        [CCode (cname = "SSL_export_keying_material_")]
        public void export_keying_material (uint8[] out, string label, string? context = null) throws GLib.Error {
            throw_if_error (export_keying_material_ (@out, label, label.length, context, context == null ? 0 : context.length, context != null));
        }
        public Error get_error (int ret);
        public void set_accept_state ();
        public void set_connect_state ();
        public int want ();
    }

    [CCode (cprefix = "X509_", lower_case_cprefix = "X509_", cheader_filename = "openssl/x509.h")]
    namespace X509 {
        [Compact]
        [CCode (cname = "X509", lower_case_cprefix = "X509_", cprefix = "X509_", ref_function = "X509_up_ref", ref_function_void = true, unref_function = "X509_free")]
        public class Certificate {
            public Certificate ();
            public ASN1.Time not_before {
                [CCode (cname = "X509_get_notBefore")]
                get;
                [CCode (cname = "X509_set_notBefore")]
                set;
            }
            public ASN1.Time not_after {
                [CCode (cname = "X509_get_notAfter")]
                get;
                [CCode (cname = "X509_set_notAfter")]
                set;
            }
            public ASN1.Integer serial_number {
                [CCode (cname = "X509_get_serialNumber")]
                get;
                [CCode (cname = "X509_set_serialNumber")]
                set;
            }
            [CCode (cname = "X509_digest")]
            private int digest_ (EVP.MessageDigest type, uchar* md, ref uint len);
            [CCode (cname = "X509_digest_")]
            public uint8[] digest (EVP.MessageDigest type, size_t buf_len = 512) throws GLib.Error {
                uint8[] buf = new uint8[buf_len];
                uint buf_out_size = (uint) buf_len;
                throw_if_error (digest_ (type, (uchar*) buf, ref buf_out_size));

                uint8[] ret = new uint8[buf_out_size];
                for (int i = 0; i < buf_out_size; i++) {
                    ret[i] = buf[i];
                }
                return ret;
            }
            [CCode (cname = "X509_set_pubkey")]
            public int set_public_key (EVP.Key public_key);
            public int set_version (long version);
            [CCode (cname = "X509_sign")]
            private int sign_ (EVP.Key private_key, EVP.MessageDigest md);
            [CCode (cname = "X509_sign_")]
            public void sign (EVP.Key private_key, EVP.MessageDigest md) throws GLib.Error {
                throw_if_error (sign_ (private_key, md));
            }
        }
    }

    public int throw_if_error(int res) throws GLib.Error {
        if (res <= 0) {
            ulong error = ERR.get_error ();
            if (error == 0) return res;
            throw new GLib.Error (-1, (int) error, "%s:%s", ERR.lib_error_string (error), ERR.reason_error_string (error));
        }
        return res;
    }
}