[Compact]
[CCode (cname = "srtp_session_t", free_function = "srtp_destroy", cheader_filename="srtp.h")]
public class Dino.Plugins.Rtp.SrtpSession {
    [CCode (cname = "srtp_create")]
    public SrtpSession(SrtpEncryption encr, SrtpAuthentication auth, uint tag_len, SrtpPrf prf, SrtpFlags flags);
    [CCode (cname = "srtp_setkey")]
    public int setkey(uint8[] key, uint8[] salt);
    [CCode (cname = "srtp_setkeystring")]
    public int setkeystring(string key, string salt);
    [CCode (cname = "srtp_setrcc_rate")]
    public void setrcc_rate(uint16 rate);

    [CCode (cname = "srtp_send")]
    private int rtp_send([CCode (array_length = false)] uint8[] buf, ref size_t len, size_t maxsize);
    [CCode (cname = "srtcp_send")]
    private int rtcp_send([CCode (array_length = false)] uint8[] buf, ref size_t len, size_t maxsize);
    [CCode (cname = "srtp_recv")]
    private int rtp_recv([CCode (array_length = false)] uint8[] buf, ref size_t len);
    [CCode (cname = "srtcp_recv")]
    private int rtcp_recv([CCode (array_length = false)] uint8[] buf, ref size_t len);

    public uint8[] encrypt_rtp(uint8[] input, uint tag_len = 10) throws GLib.Error {
        uint8[] buf = new uint8[input.length+tag_len];
        GLib.Memory.copy(buf, input, input.length);
        size_t buf_use = input.length;
        int res = rtp_send(buf, ref buf_use, buf.length);
        if (res != 0) {
            throw new GLib.Error(-1, res, "RTP encrypt failed");
        }
        uint8[] ret = new uint8[buf_use];
        GLib.Memory.copy(ret, buf, buf_use);
        return ret;
    }

    public uint8[] encrypt_rtcp(uint8[] input, uint tag_len = 10) throws GLib.Error {
        uint8[] buf = new uint8[input.length+tag_len+4];
        GLib.Memory.copy(buf, input, input.length);
        size_t buf_use = input.length;
        int res = rtcp_send(buf, ref buf_use, buf.length);
        if (res != 0) {
            throw new GLib.Error(-1, res, "RTCP encrypt failed");
        }
        uint8[] ret = new uint8[buf_use];
        GLib.Memory.copy(ret, buf, buf_use);
        return ret;
    }

    public uint8[] decrypt_rtp(uint8[] input) throws GLib.Error {
        uint8[] buf = new uint8[input.length];
        GLib.Memory.copy(buf, input, input.length);
        size_t buf_use = input.length;
        int res = rtp_recv(buf, ref buf_use);
        if (res != 0) {
            throw new GLib.Error(-1, res, "RTP decrypt failed");
        }
        uint8[] ret = new uint8[buf_use];
        GLib.Memory.copy(ret, buf, buf_use);
        return ret;
    }

    public uint8[] decrypt_rtcp(uint8[] input) throws GLib.Error {
        uint8[] buf = new uint8[input.length];
        GLib.Memory.copy(buf, input, input.length);
        size_t buf_use = input.length;
        int res = rtcp_recv(buf, ref buf_use);
        if (res != 0) {
            throw new GLib.Error(-1, res, "RTCP decrypt failed");
        }
        uint8[] ret = new uint8[buf_use];
        GLib.Memory.copy(ret, buf, buf_use);
        return ret;
    }
}

[Flags]
[CCode (cname = "unsigned", cprefix = "", cheader_filename="srtp.h", has_type_id = false)]
public enum Dino.Plugins.Rtp.SrtpFlags {
    SRTP_UNENCRYPTED,
    SRTCP_UNENCRYPTED,
    SRTP_UNAUTHENTICATED,

    SRTP_RCC_MODE1,
    SRTP_RCC_MODE2,
    SRTP_RCC_MODE3
}

[CCode (cname = "int", cprefix = "SRTP_ENCR_", cheader_filename="srtp.h", has_type_id = false)]
public enum Dino.Plugins.Rtp.SrtpEncryption {
    NULL,
    AES_CM,
    AES_F8
}

[CCode (cname = "int", cprefix = "SRTP_AUTH_", cheader_filename="srtp.h", has_type_id = false)]
public enum Dino.Plugins.Rtp.SrtpAuthentication {
    NULL,
    HMAC_SHA1
}

[CCode (cname = "int", cprefix = "SRTP_PRF_", cheader_filename="srtp.h", has_type_id = false)]
public enum Dino.Plugins.Rtp.SrtpPrf {
    AES_CM
}