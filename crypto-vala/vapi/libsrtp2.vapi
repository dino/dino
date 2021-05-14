[CCode (cheader_filename = "srtp2/srtp.h")]
namespace Srtp {
public const uint MAX_TRAILER_LEN;

public static ErrorStatus init();
public static ErrorStatus shutdown();

[Compact]
[CCode (cname = "srtp_ctx_t", cprefix = "srtp_", free_function = "srtp_dealloc")]
public class Context {
    public static ErrorStatus create(out Context session, Policy? policy);

    public ErrorStatus protect([CCode (type = "void*", array_length = false)] uint8[] rtp, ref int len);
    public ErrorStatus unprotect([CCode (type = "void*", array_length = false)] uint8[] rtp, ref int len);

    public ErrorStatus protect_rtcp([CCode (type = "void*", array_length = false)] uint8[] rtcp, ref int len);
    public ErrorStatus unprotect_rtcp([CCode (type = "void*", array_length = false)] uint8[] rtcp, ref int len);

    public ErrorStatus add_stream(ref Policy policy);
    public ErrorStatus update_stream(ref Policy policy);
    public ErrorStatus remove_stream(uint ssrc);
    public ErrorStatus update(ref Policy policy);
}

[CCode (cname = "srtp_ssrc_t")]
public struct Ssrc {
    public SsrcType type;
    public uint value;
}

[CCode (cname = "srtp_ssrc_type_t", cprefix = "ssrc_")]
public enum SsrcType {
    undefined, specific, any_inbound, any_outbound
}

[CCode (cname = "srtp_policy_t", destroy_function = "")]
public struct Policy {
    public Ssrc ssrc;
    public CryptoPolicy rtp;
    public CryptoPolicy rtcp;
    [CCode (array_length = false)]
    public uint8[] key;
    public ulong num_master_keys;
    public ulong window_size;
    public int allow_repeat_tx;
    [CCode (array_length_cname = "enc_xtn_hdr_count")]
    public int[] enc_xtn_hdr;
}

[CCode (cname = "srtp_crypto_policy_t")]
public struct CryptoPolicy {
    public CipherType cipher_type;
    public int cipher_key_len;
    public AuthType auth_type;
    public int auth_key_len;
    public int auth_tag_len;
    public SecurityServices sec_serv;

    public void set_aes_cm_128_hmac_sha1_80();
    public void set_aes_cm_128_hmac_sha1_32();
    public void set_aes_cm_128_null_auth();
    public void set_aes_cm_192_hmac_sha1_32();
    public void set_aes_cm_192_hmac_sha1_80();
    public void set_aes_cm_192_null_auth();
    public void set_aes_cm_256_hmac_sha1_32();
    public void set_aes_cm_256_hmac_sha1_80();
    public void set_aes_cm_256_null_auth();
    public void set_aes_gcm_128_16_auth();
    public void set_aes_gcm_128_8_auth();
    public void set_aes_gcm_128_8_only_auth();
    public void set_aes_gcm_256_16_auth();
    public void set_aes_gcm_256_8_auth();
    public void set_aes_gcm_256_8_only_auth();
    public void set_null_cipher_hmac_null();
    public void set_null_cipher_hmac_sha1_80();

    public void set_rtp_default();
    public void set_rtcp_default();

    public void set_from_profile_for_rtp(Profile profile);
    public void set_from_profile_for_rtcp(Profile profile);
}

[CCode (cname = "srtp_profile_t", cprefix = "srtp_profile_")]
public enum Profile {
    reserved, aes128_cm_sha1_80, aes128_cm_sha1_32, null_sha1_80, null_sha1_32, aead_aes_128_gcm, aead_aes_256_gcm
}

[CCode (cname = "srtp_cipher_type_id_t")]
public struct CipherType : uint32 {}

[CCode (cname = "srtp_auth_type_id_t")]
public struct AuthType : uint32 {}

[CCode (cname = "srtp_sec_serv_t", cprefix = "sec_serv_")]
public enum SecurityServices {
    none, conf, auth, conf_and_auth;
}

[CCode (cname = "srtp_err_status_t", cprefix = "srtp_err_status_", has_type_id = false)]
public enum ErrorStatus {
    ok, fail, bad_param, alloc_fail, dealloc_fail, init_fail, terminus, auth_fail, cipher_fail, replay_fail, algo_fail, no_such_op, no_ctx, cant_check, key_expired, socket_err, signal_err, nonce_bad, encode_err, semaphore_err, pfkey_err, bad_mki, pkt_idx_old, pkt_idx_adv
}

[CCode (cname = "srtp_log_level_t", cprefix = "srtp_log_level_", has_type_id = false)]
public enum LogLevel {
    error, warning, info, debug
}

[CCode (cname = "srtp_log_handler_func_t")]
public delegate void LogHandler(LogLevel level, string msg);

public static ErrorStatus install_log_handler(LogHandler func);

}