/* libgpgme.vapi
 *
 * Copyright (C) 2009 Sebastian Reichel <sre@ring0.de>
 * Copyright (C) 2022 Itay Grudev <itay+git2022@grudev.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

[CCode (lower_case_cprefix = "gpgme_", cheader_filename = "gpgme.h,gpgme_fix.h")]
namespace GPG {
    public static GLib.RecMutex global_mutex;

    [CCode (cname = "struct _gpgme_engine_info")]
    public struct EngineInfo {
        EngineInfo* next;
        Protocol protocol;
        string file_name;
        string version;
        string req_version;
        string? home_dir;
    }

    [Compact]
    [CCode (cname = "struct _gpgme_key", ref_function = "gpgme_key_ref_vapi", unref_function = "gpgme_key_unref_vapi", free_function = "gpgme_key_release")]
    public class Key {
        public bool revoked;
        public bool expired;
        public bool disabled;
        public bool invalid;
        public bool can_encrypt;
        public bool can_sign;
        public bool can_certify;
        public bool secret;
        public bool can_authenticate;
        public bool is_qualified;
        public Protocol protocol;
        public string issuer_serial;
        public string issuer_name;
        public string chain_id;
        public Validity owner_trust;
        [CCode(array_null_terminated = true)]
        public SubKey[] subkeys;
        [CCode(array_null_terminated = true)]
        public UserID[] uids;
        public KeylistMode keylist_mode;
        public string fpr { get { return subkeys[0].fpr; } }
    }

    [CCode (cname = "struct _gpgme_sig_notation")]
    public struct SigNotation {
        SigNotation* next;
        string? name;
        string value;
        int name_len;
        int value_len;
        SigNotationFlags flags;
        bool human_readable;
        bool critical;
    }

    [CCode (cname = "struct _gpgme_subkey")]
    public struct SubKey {
        SubKey* next;
        bool revoked;
        bool expired;
        bool disabled;
        bool invalid;
        bool can_encrypt;
        bool can_sign;
        bool can_certify;
        bool secret;
        bool can_authenticate;
        bool is_qualified;
        bool is_cardkey;
        PublicKeyAlgorithm algo;
        uint length;
        string keyid;
        string fpr;
        long timestamp;
        long expires;
        string? card_number;
    }

    [CCode (cname = "struct _gpgme_key_sig")]
    public struct KeySig {
        KeySig* next;
        bool revoked;
        bool expired;
        bool invalid;
        bool exportable;
        PublicKeyAlgorithm algo;
        string keyid;
        long timestamp;
        long expires;
        GPGError.Error status;
        string uid;
        string name;
        string email;
        string comment;
        uint sig_class;
        SigNotation notations;
    }

    [CCode (cname = "struct _gpgme_user_id")]
    public struct UserID {
        UserID* next;
        bool revoked;
        bool invalid;
        Validity validity;
        string uid;
        string name;
        string email;
        string comment;
        KeySig signatures;
    }

    [CCode (cname = "struct _gpgme_op_verify_result")]
    public struct VerifyResult {
        Signature* signatures;
        string? file_name;
    }

    [CCode (cname = "struct _gpgme_op_sign_result")]
    public struct SignResult {
        InvalidKey invalid_signers;
        Signature* signatures;
    }

    [CCode (cname = "struct _gpgme_op_encrypt_result")]
    public struct EncryptResult {
        InvalidKey invalid_signers;
    }

    [CCode (cname = "struct _gpgme_op_decrypt_result")]
    public struct DecryptResult {
        string unsupported_algorithm;
        bool wrong_key_usage;
        Recipient recipients;
        string file_name;
    }

    [CCode (cname = "struct _gpgme_recipient")]
    public struct Recipient {
        Recipient *next;
        string keyid;
        PublicKeyAlgorithm pubkey_algo;
        GPGError.Error status;
    }

    [CCode (cname = "struct _gpgme_invalid_key")]
    public struct InvalidKey {
        InvalidKey *next;
        string fpr;
        GPGError.Error reason;
    }

    [CCode (cname = "struct _gpgme_signature")]
    public struct Signature {
        Signature *next;
        Sigsum summary;
        string fpr;
        GPGError.Error status;
        SigNotation notations;
        ulong timestamp;
        ulong exp_timestamp;
        bool wrong_key_usage;
        PKAStatus pka_trust;
        bool chain_model;
        Validity validity;
        GPGError.Error validity_reason;
        PublicKeyAlgorithm pubkey_algo;
        HashAlgorithm hash_algo;
        string? pka_address;
    }

    public enum PKAStatus {
        NOT_AVAILABLE,
        BAD,
        OKAY,
        RFU
    }

    [CCode (cname = "gpgme_sigsum_t", cprefix = "GPGME_SIGSUM_")]
    public enum Sigsum {
        VALID,
        GREEN,
        RED,
        KEY_REVOKED,
        KEY_EXPIRED,
        SIG_EXPIRED,
        KEY_MISSING,
        CRL_MISSING,
        CRL_TOO_OLD,
        BAD_POLICY,
        SYS_ERROR
    }

    [CCode (cname = "gpgme_data_encoding_t", cprefix = "GPGME_DATA_ENCODING_")]
    public enum DataEncoding {
        NONE,
        BINARY,
        BASE64,
        ARMOR,
        URL,
        URLESC,
        URL0
    }

    [CCode (cname = "gpgme_pubkey_algo_t", cprefix = "GPGME_PK_")]
    public enum PublicKeyAlgorithm {
        RSA,
        RSA_E,
        RSA_S,
        ELG_E,
        DSA,
        ELG
    }

    [CCode (cname = "gpgme_hash_algo_t", cprefix = "GPGME_MD_")]
    public enum HashAlgorithm {
        NONE,
        MD5,
        SHA1,
        RMD160,
        MD2,
        TIGER,
        HAVAL,
        SHA256,
        SHA384,
        SHA512,
        MD4,
        CRC32,
        CRC32_RFC1510,
        CRC24_RFC2440
    }

    [CCode (cname = "gpgme_sig_mode_t", cprefix = "GPGME_SIG_MODE_")]
    public enum SigMode {
        NORMAL,
        DETACH,
        CLEAR
    }

    [CCode (cname = "gpgme_validity_t", cprefix = "GPGME_VALIDITY_")]
    public enum Validity {
        UNKNOWN,
        UNDEFINED,
        NEVER,
        MARGINAL,
        FULL,
        ULTIMATE
    }

    [CCode (cname = "gpgme_protocol_t", cprefix = "GPGME_PROTOCOL_")]
    public enum Protocol {
        OpenPGP,
        CMS,
        GPGCONF,
        ASSUAN,
        UNKNOWN
    }

    [CCode (cname = "gpgme_keylist_mode_t", cprefix = "GPGME_KEYLIST_MODE_")]
    public enum KeylistMode {
        LOCAL,
        EXTERN,
        SIGS,
        SIG_NOTATIONS,
        EPHEMERAL,
        VALIDATE
    }

    [CCode (cname = "gpgme_export_mode_t", cprefix = "GPGME_EXPORT_MODE_")]
    public enum ExportMode {
        EXTERN
    }

    [CCode (cprefix = "GPGME_AUDITLOG_")]
    public enum AuditLogFlag {
        HTML,
        WITH_HELP
    }

    [CCode (cname = "gpgme_sig_notation_flags_t", cprefix = "GPGME_SIG_NOTATION_")]
    public enum SigNotationFlags {
        HUMAN_READABLE,
        CRITICAL
    }

    [CCode (cname = "gpgme_encrypt_flags_t", cprefix = "GPGME_ENCRYPT_")]
    public enum EncryptFlags {
        ALWAYS_TRUST,
        NO_ENCRYPT_TO
    }

    [CCode (cname = "gpgme_status_code_t", cprefix = "GPGME_STATUS_")]
    public enum StatusCode {
        EOF,
        ENTER,
        LEAVE,
        ABORT,
        GOODSIG,
        BADSIG,
        ERRSIG,
        BADARMOR,
        RSA_OR_IDEA,
        KEYEXPIRED,
        KEYREVOKED,
        TRUST_UNDEFINED,
        TRUST_NEVER,
        TRUST_MARGINAL,
        TRUST_FULLY,
        TRUST_ULTIMATE,
        SHM_INFO,
        SHM_GET,
        SHM_GET_BOOL,
        SHM_GET_HIDDEN,
        NEED_PASSPHRASE,
        VALIDSIG,
        SIG_ID,
        SIG_TO,
        ENC_TO,
        NODATA,
        BAD_PASSPHRASE,
        NO_PUBKEY,
        NO_SECKEY,
        NEED_PASSPHRASE_SYM,
        DECRYPTION_FAILED,
        DECRYPTION_OKAY,
        MISSING_PASSPHRASE,
        GOOD_PASSPHRASE,
        GOODMDC,
        BADMDC,
        ERRMDC,
        IMPORTED,
        IMPORT_OK,
        IMPORT_PROBLEM,
        IMPORT_RES,
        FILE_START,
        FILE_DONE,
        FILE_ERROR,
        BEGIN_DECRYPTION,
        END_DECRYPTION,
        BEGIN_ENCRYPTION,
        END_ENCRYPTION,
        DELETE_PROBLEM,
        GET_BOOL,
        GET_LINE,
        GET_HIDDEN,
        GOT_IT,
        PROGRESS,
        SIG_CREATED,
        SESSION_KEY,
        NOTATION_NAME,
        NOTATION_DATA,
        POLICY_URL,
        BEGIN_STREAM,
        END_STREAM,
        KEY_CREATED,
        USERID_HINT,
        UNEXPECTED,
        INV_RECP,
        NO_RECP,
        ALREADY_SIGNED,
        SIGEXPIRED,
        EXPSIG,
        EXPKEYSIG,
        TRUNCATED,
        ERROR,
        NEWSIG,
        REVKEYSIG,
        SIG_SUBPACKET,
        NEED_PASSPHRASE_PIN,
        SC_OP_FAILURE,
        SC_OP_SUCCESS,
        CARDCTRL,
        BACKUP_KEY_CREATED,
        PKA_TRUST_BAD,
        PKA_TRUST_GOOD,
        PLAINTEXT
    }

    [Compact]
    [CCode (cname = "struct gpgme_context", free_function = "gpgme_release", cprefix = "gpgme_")]
    public class Context {
        private static GPGError.Error new(out Context ctx);

        public static Context create() throws GLib.Error {
            Context ctx;
            throw_if_error(@new(out ctx));
            return ctx;
        }

        public GPGError.Error set_protocol(Protocol p);
        public Protocol get_protocol();

        public void set_armor(bool yes);
        public bool get_armor();

        public void set_textmode(bool yes);
        public bool get_textmode();

        public GPGError.Error set_keylist_mode(KeylistMode mode);
        public KeylistMode get_keylist_mode();

        public void set_include_certs(int nr_of_certs = -256);

        public int get_include_certs();

        public void set_passphrase_cb(passphrase_callback cb, void* hook_value = null);

        public void get_passphrase_cb(out passphrase_callback cb, out void* hook_value);

        public GPGError.Error set_locale(int category, string val);

        [CCode (cname = "gpgme_ctx_get_engine_info")]
        public EngineInfo* get_engine_info();

        [CCode (cname = "gpgme_ctx_set_engine_info")]
        public GPGError.Error set_engine_info(Protocol proto, string file_name, string home_dir);

        public void signers_clear();

        public GPGError.Error signers_add(Key key);

        public Key* signers_enum(int n);

        public void sig_notation_clear();

        public GPGError.Error sig_notation_add(string name, string val, SigNotationFlags flags);

        public SigNotation* sig_notation_get();

        [CCode (cname = "gpgme_get_key")]
        private GPGError.Error get_key_(string fpr, out Key key, bool secret);

        [CCode (cname = "gpgme_get_key_")]
        public Key get_key(string fpr, bool secret) throws GLib.Error {
            Key key;
            throw_if_error(get_key_(fpr, out key, secret));
            return key;
        }

        public Context* wait(out GPGError.Error status, bool hang);

        public SignResult* op_sign_result();

        [CCode (cname = "gpgme_op_sign")]
        public GPGError.Error op_sign_(Data plain, Data sig, SigMode mode);

        [CCode (cname = "gpgme_op_sign_")]
        public Data op_sign(Data plain, SigMode mode) throws GLib.Error {
            Data sig = Data.create();
            throw_if_error(op_sign_(plain, sig, mode));
            return sig;
        }

        public VerifyResult* op_verify_result();

        [CCode (cname = "gpgme_op_verify")]
        public GPGError.Error op_verify_(Data sig, Data signed_text, Data? plaintext);

        [CCode (cname = "gpgme_op_verify_")]
        public Data op_verify(Data sig, Data signed_text) throws GLib.Error {
            Data plaintext = Data.create();
            throw_if_error(op_verify_(sig, signed_text, plaintext));
            return plaintext;
        }

        public EncryptResult* op_encrypt_result();

        [CCode (cname = "gpgme_op_encrypt")]
        public GPGError.Error op_encrypt_([CCode (array_length = false)] Key[] recp, EncryptFlags flags, Data plain, Data cipher);

        [CCode (cname = "gpgme_op_encrypt_")]
        public Data op_encrypt(Key[] recp, EncryptFlags flags, Data plain) throws GLib.Error {
            Data cipher = Data.create();
            throw_if_error(op_encrypt_(recp, flags, plain, cipher));
            return cipher;
        }

        public DecryptResult* op_decrypt_result();

        [CCode (cname = "gpgme_op_decrypt")]
        public GPGError.Error op_decrypt_(Data cipher, Data plain);

        [CCode (cname = "gpgme_op_decrypt_")]
        public Data op_decrypt(Data cipher) throws GLib.Error {
            Data plain = Data.create();
            throw_if_error(op_decrypt_(cipher, plain));
            return plain;
        }

        public GPGError.Error op_export(string? pattern, ExportMode mode, Data keydata);

        public GPGError.Error op_import(Data keydata);

        public unowned ImportResult op_import_result();

        [CCode (cname = "gpgme_op_keylist_start")]
        private GPGError.Error op_keylist_start_(string? pattern = null, int secret_only = 0);

        [CCode (cname = "gpgme_op_keylist_start_")]
        public void op_keylist_start(string? pattern = null, int secret_only = 0) throws GLib.Error {
            throw_if_error(op_keylist_start_(pattern, secret_only));
        }

        [CCode (cname = "gpgme_op_keylist_next")]
        private GPGError.Error op_keylist_next_(out Key key);

        [CCode (cname = "gpgme_op_keylist_next_")]
        public Key op_keylist_next() throws GLib.Error {
            Key key;
            throw_if_error(op_keylist_next_(out key));
            return key;
        }

        [CCode (cname = "gpgme_op_keylist_end")]
        private GPGError.Error op_keylist_end_();

        [CCode (cname = "gpgme_op_keylist_end_")]
        public void op_keylist_end() throws GLib.Error {
            throw_if_error(op_keylist_end_());
        }

        public KeylistResult op_keylist_result();
    }

    [Flags]
    [CCode (cname="unsigned int")]
    public enum ImportStatusFlags {
        [CCode (cname = "GPGME_IMPORT_NEW")]
        NEW,
        [CCode (cname = "GPGME_IMPORT_UID")]
        UID,
        [CCode (cname = "GPGME_IMPORT_SIG")]
        SIG,
        [CCode (cname = "GPGME_IMPORT_SUBKEY")]
        SUBKEY,
        [CCode (cname = "GPGME_IMPORT_SECRET")]
        SECRET
    }

    [Compact]
    [CCode (cname = "struct _gpgme_import_status")]
    public class ImportStatus {
        public ImportStatus? next;
        public string fpr;
        public GPGError.Error result;
        public ImportStatusFlags status;
    }

    [Compact]
    [CCode (cname = "struct _gpgme_op_import_result")]
    public class ImportResult {
        public int considered;
        public int no_user_id;
        public int imported;
        public int imported_rsa;
        public int unchanged;
        public int new_user_ids;
        public int new_sub_keys;
        public int new_signatures;
        public int new_revocations;
        public int secret_read;
        public int secret_imported;
        public int secret_unchanged;
        public int not_imported;
        public ImportStatus imports;
    }

    [Compact]
    [CCode (cname = "struct _gpgme_op_keylist_result")]
    public class KeylistResult {
        uint truncated;
    }

    [Compact]
    [CCode (cname = "struct gpgme_data", free_function = "gpgme_data_release", cprefix = "gpgme_data_")]
    public class Data {

        public static GPGError.Error new(out Data d);

        public static Data create() throws GLib.Error {
            Data data;
            throw_if_error(@new(out data));
            return data;
        }

        [CCode (cname = "gpgme_data_new_from_mem")]
        public static GPGError.Error new_from_memory(out Data d, char[] buffer, bool copy);

        public static Data create_from_memory(uint8[] buffer, bool copy) throws GLib.Error {
            Data data;
            throw_if_error(new_from_memory(out data, (char[]) buffer, copy));
            return data;
        }

        [CCode (cname = "gpgme_data_new_from_file")]
        public static GPGError.Error new_from_file(out Data d, string filename, int copy = 1);

        public static Data create_from_file(string filename, int copy = 1) throws GLib.Error {
            Data data;
            throw_if_error(new_from_file(out data, filename, copy));
            return data;
        }

        [CCode (cname = "gpgme_data_release_and_get_mem")]
        public string release_and_get_mem(out size_t len);

        public ssize_t read([CCode (array_length = false)] uint8[] buf, size_t len);

        public ssize_t write(uint8[] buf);

        public long seek(long offset, int whence=0);

        public GPGError.Error set_file_name(string file_name);

        public DataEncoding *get_encoding();

        public GPGError.Error set_encoding(DataEncoding enc);
    }

    [CCode (cname = "gpgme_get_protocol_name")]
    public unowned string get_protocol_name(Protocol p);

    [CCode (cname = "gpgme_pubkey_algo_name")]
    public unowned string get_public_key_algorithm_name(PublicKeyAlgorithm algo);

    [CCode (cname = "gpgme_hash_algo_name")]
    public unowned string get_hash_algorithm_name(HashAlgorithm algo);

    [CCode (cname = "gpgme_passphrase_cb_t", has_target = false)]
    public delegate GPGError.Error passphrase_callback(void* hook, string uid_hint, string passphrase_info, bool prev_was_bad, int fd);

    [CCode (cname = "gpgme_check_version")]
    public unowned string check_version(string? required_version = null);

    [CCode (cname = "gpgme_engine_check_version")]
    public GPGError.Error engine_check_version(Protocol proto);

    [CCode (cname = "gpgme_get_engine_info")]
    public GPGError.Error get_engine_info(out EngineInfo? engine_info);

    [CCode (cname = "gpgme_strerror_r")]
    public int strerror_r(GPGError.Error err, uint8[] buf);

    [CCode (cname = "gpgme_strerror")]
    public unowned string strerror(GPGError.Error err);

    private void throw_if_error(GPGError.Error error) throws GLib.Error {
        if (error.code != GPGError.ErrorCode.NO_ERROR) {
            throw new GLib.Error(-1, error.code, "%s", error.to_string());
        }
    }
}
