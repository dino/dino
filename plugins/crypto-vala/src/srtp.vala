using Srtp;

public class Crypto.Srtp {
    public const string AES_CM_128_HMAC_SHA1_80 = "AES_CM_128_HMAC_SHA1_80";
    public const string AES_CM_128_HMAC_SHA1_32 = "AES_CM_128_HMAC_SHA1_32";
    public const string F8_128_HMAC_SHA1_80 = "F8_128_HMAC_SHA1_80";

    public class Session {
        public bool has_encrypt { get; private set; default = false; }
        public bool has_decrypt { get; private set; default = false; }

        private Context encrypt_context;
        private Context decrypt_context;

        static construct {
            init();
            install_log_handler(log);
        }

        private static void log(LogLevel level, string msg) {
            print(@"SRTP[$level]: $msg\n");
        }

        public Session() {
            Context.create(out encrypt_context, null);
            Context.create(out decrypt_context, null);
        }

        public uint8[] encrypt_rtp(uint8[] data) throws Error {
            uint8[] buf = new uint8[data.length + MAX_TRAILER_LEN];
            Memory.copy(buf, data, data.length);
            int buf_use = data.length;
            ErrorStatus res = encrypt_context.protect(buf, ref buf_use);
            if (res != ErrorStatus.ok) {
                throw new Error.UNKNOWN(@"SRTP encrypt failed: $res");
            }
            uint8[] ret = new uint8[buf_use];
            GLib.Memory.copy(ret, buf, buf_use);
            return ret;
        }

        public uint8[] decrypt_rtp(uint8[] data) throws Error {
            uint8[] buf = new uint8[data.length];
            Memory.copy(buf, data, data.length);
            int buf_use = data.length;
            ErrorStatus res = decrypt_context.unprotect(buf, ref buf_use);
            switch (res) {
                case ErrorStatus.auth_fail:
                    throw new Error.AUTHENTICATION_FAILED("SRTP packet failed the message authentication check");
                case ErrorStatus.ok:
                    break;
                default:
                    throw new Error.UNKNOWN(@"SRTP decrypt failed: $res");
            }
            uint8[] ret = new uint8[buf_use];
            GLib.Memory.copy(ret, buf, buf_use);
            return ret;
        }

        public uint8[] encrypt_rtcp(uint8[] data) throws Error {
            uint8[] buf = new uint8[data.length + MAX_TRAILER_LEN + 4];
            Memory.copy(buf, data, data.length);
            int buf_use = data.length;
            ErrorStatus res = encrypt_context.protect_rtcp(buf, ref buf_use);
            if (res != ErrorStatus.ok) {
                throw new Error.UNKNOWN(@"SRTCP encrypt failed: $res");
            }
            uint8[] ret = new uint8[buf_use];
            GLib.Memory.copy(ret, buf, buf_use);
            return ret;
        }

        public uint8[] decrypt_rtcp(uint8[] data) throws Error {
            uint8[] buf = new uint8[data.length];
            Memory.copy(buf, data, data.length);
            int buf_use = data.length;
            ErrorStatus res = decrypt_context.unprotect_rtcp(buf, ref buf_use);
            switch (res) {
                case ErrorStatus.auth_fail:
                    throw new Error.AUTHENTICATION_FAILED("SRTCP packet failed the message authentication check");
                case ErrorStatus.ok:
                    break;
                default:
                    throw new Error.UNKNOWN(@"SRTP decrypt failed: $res");
            }
            uint8[] ret = new uint8[buf_use];
            GLib.Memory.copy(ret, buf, buf_use);
            return ret;
        }

        private Policy create_policy(string profile) {
            Policy policy = Policy();
            switch (profile) {
                case AES_CM_128_HMAC_SHA1_80:
                    policy.rtp.set_aes_cm_128_hmac_sha1_80();
                    policy.rtcp.set_aes_cm_128_hmac_sha1_80();
                    break;
            }
            return policy;
        }

        public void set_encryption_key(string profile, uint8[] key, uint8[] salt) {
            Policy policy = create_policy(profile);
            policy.ssrc.type = SsrcType.any_outbound;
            policy.key = new uint8[key.length + salt.length];
            Memory.copy(policy.key, key, key.length);
            Memory.copy(((uint8*)policy.key) + key.length, salt, salt.length);
            encrypt_context.add_stream(ref policy);
            has_encrypt = true;
        }

        public void set_decryption_key(string profile, uint8[] key, uint8[] salt) {
            Policy policy = create_policy(profile);
            policy.ssrc.type = SsrcType.any_inbound;
            policy.key = new uint8[key.length + salt.length];
            Memory.copy(policy.key, key, key.length);
            Memory.copy(((uint8*)policy.key) + key.length, salt, salt.length);
            decrypt_context.add_stream(ref policy);
            has_decrypt = true;
        }
    }
}