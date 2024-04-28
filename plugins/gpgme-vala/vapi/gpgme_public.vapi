[CCode (lower_case_cprefix = "gpgme_", cheader_filename = "gpgme.h,gpgme_fix.h")]
namespace GPG {

[CCode (cname = "gpgme_check_version")]
public unowned string check_version(string? required_version = null);

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
    public bool can_authenticate;
    public bool is_qualified;
    public bool secret;
    public Protocol protocol;
    public string issuer_serial;
    public string issuer_name;
    public string chain_id;
    public Validity owner_trust;
    [CCode (array_length = false, array_null_terminated = true)]
    public SubKey[] subkeys;
    [CCode (array_length = false, array_null_terminated = true)]
    public UserID[] uids;
    public KeylistMode keylist_mode;
    // public string fpr; // requires gpgme >= 1.7.0
    public string fpr { get { return subkeys[0].fpr; } }
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

[CCode (cname = "struct _gpgme_key_sig")]
public struct KeySig {
    KeySig* next;
    bool invoked;
    bool expired;
    bool invalid;
    bool exportable;
    PublicKeyAlgorithm algo;
    string keyid;
    long timestamp;
    long expires;
//    GPGError.Error status;
    string uid;
    string name;
    string email;
    string comment;
    uint sig_class;
    SigNotation notations;
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
    string? cardnumber;
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

[CCode (cname = "gpgme_sig_notation_flags_t", cprefix = "GPGME_SIG_NOTATION_")]
public enum SigNotationFlags {
    HUMAN_READABLE,
    CRITICAL
}

[CCode (cname = "gpgme_sig_mode_t", cprefix = "GPGME_SIG_MODE_")]
public enum SigMode {
    NORMAL,
    DETACH,
    CLEAR
}

[CCode (cname = "gpgme_encrypt_flags_t", cprefix = "GPGME_ENCRYPT_")]
public enum EncryptFlags {
    ALWAYS_TRUST,
    NO_ENCRYPT_TO
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

[CCode (cname = "gpgme_validity_t", cprefix = "GPGME_VALIDITY_")]
public enum Validity {
    UNKNOWN,
    UNDEFINED,
    NEVER,
    MARGINAL,
    FULL,
    ULTIMATE
}

}