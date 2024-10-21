namespace Crypto {
public class SymmetricCipher {
#if GCRYPT
    private GCrypt.Cipher.Cipher cipher;
#else
    bool is_encryption;
    private OpenSSL.EVP.CipherContext? cipher;
#endif

    public static bool supports(string algo_name) {
#if GCRYPT
        GCrypt.Cipher.Algorithm algo;
        GCrypt.Cipher.Mode mode;
        GCrypt.Cipher.Flag flags;
        return parse(algo_name, out algo, out mode, out flags);
#else
        return algo_name == "AES-GCM";
#endif
    }

#if GCRYPT
    private static unowned string mode_to_string(GCrypt.Cipher.Mode mode) {
        switch (mode) {
            case GCrypt.Cipher.Mode.ECB: return "ECB";
            case GCrypt.Cipher.Mode.CFB: return "CFB";
            case GCrypt.Cipher.Mode.CBC: return "CBC";
            case GCrypt.Cipher.Mode.STREAM: return "STREAM";
            case GCrypt.Cipher.Mode.OFB: return "OFB";
            case GCrypt.Cipher.Mode.CTR: return "CTR";
            case GCrypt.Cipher.Mode.AESWRAP: return "AESWRAP";
            case GCrypt.Cipher.Mode.GCM: return "GCM";
            case GCrypt.Cipher.Mode.POLY1305: return "POLY1305";
            case GCrypt.Cipher.Mode.OCB: return "OCB";
            case GCrypt.Cipher.Mode.CFB8: return "CFB8";
            // case GCrypt.Cipher.Mode.XTS: return "XTS"; // Not supported in gcrypt < 1.8
        }
        return "NONE";
    }

    private static GCrypt.Cipher.Mode mode_from_string(string name) {
        switch (name) {
            case "ECB": return GCrypt.Cipher.Mode.ECB;
            case "CFB": return GCrypt.Cipher.Mode.CFB;
            case "CBC": return GCrypt.Cipher.Mode.CBC;
            case "STREAM": return GCrypt.Cipher.Mode.STREAM;
            case "OFB": return GCrypt.Cipher.Mode.OFB;
            case "CTR": return GCrypt.Cipher.Mode.CTR;
            case "AESWRAP": return GCrypt.Cipher.Mode.AESWRAP;
            case "GCM": return GCrypt.Cipher.Mode.GCM;
            case "POLY1305": return GCrypt.Cipher.Mode.POLY1305;
            case "OCB": return GCrypt.Cipher.Mode.OCB;
            case "CFB8": return GCrypt.Cipher.Mode.CFB8;
            // case "XTS": return GCrypt.Cipher.Mode.XTS; // Not supported in gcrypt < 1.8
        }
        return GCrypt.Cipher.Mode.NONE;
    }

    private static string flags_to_string(GCrypt.Cipher.Flag flags) {
        string? s = null;
        if ((GCrypt.Cipher.Flag.CBC_MAC & flags) != 0) s = (s == null ? "" : @"$s-") + "MAC";
        if ((GCrypt.Cipher.Flag.CBC_CTS & flags) != 0) s = (s == null ? "" : @"$s-") + "CTS";
        if ((GCrypt.Cipher.Flag.ENABLE_SYNC & flags) != 0) s = (s == null ? "" : @"$s-") + "SYNC";
        if ((GCrypt.Cipher.Flag.SECURE & flags) != 0) s = (s == null ? "" : @"$s-") + "SECURE";
        return s ?? "NONE";
    }

    private static GCrypt.Cipher.Flag flag_from_string(string flag_name) {
        if (flag_name == "SECURE") return GCrypt.Cipher.Flag.SECURE;
        if (flag_name == "SYNC") return GCrypt.Cipher.Flag.ENABLE_SYNC;
        if (flag_name == "CTS") return GCrypt.Cipher.Flag.CBC_CTS;
        if (flag_name == "MAC") return GCrypt.Cipher.Flag.CBC_MAC;
        return 0;
    }

    private static GCrypt.Cipher.Flag flags_from_string(string flag_names) {
        GCrypt.Cipher.Flag flags = 0;
        foreach(string flag in flag_names.split("-")) {
            flags |= flag_from_string(flag);
        }
        return flags;
    }

    private static bool parse(string algo_name, out GCrypt.Cipher.Algorithm algo, out GCrypt.Cipher.Mode mode, out GCrypt.Cipher.Flag flags) {
        algo = GCrypt.Cipher.Algorithm.NONE;
        mode = GCrypt.Cipher.Mode.NONE;
        flags = 0;
        string[] algo_parts = algo_name.split("-", 3);

        algo = GCrypt.Cipher.Algorithm.from_string(algo_parts[0]);
        if (algo_parts.length >= 2) {
            mode = mode_from_string(algo_parts[1]);
        }
        if (algo_parts.length == 3) {
            flags |= flags_from_string(algo_parts[2]);
        }
        return to_algo_name(algo, mode, flags) == algo_name;
    }

    private static string to_algo_name(GCrypt.Cipher.Algorithm algo = GCrypt.Cipher.Algorithm.NONE, GCrypt.Cipher.Mode mode = GCrypt.Cipher.Mode.NONE, GCrypt.Cipher.Flag flags = 0) {
        if (flags != 0) {
            return @"$algo-$(mode_to_string(mode))-$(flags_to_string(flags))";
        } else if (mode != GCrypt.Cipher.Mode.NONE) {
            return @"$algo-$(mode_to_string(mode))";
        } else {
            return algo.to_string();
        }
    }
#endif

    public SymmetricCipher.encryption(string algo_name) throws Error {
        this.initialize(algo_name, true);
    }

    public SymmetricCipher.decryption(string algo_name) throws Error {
        this.initialize(algo_name, false);
    }

    private SymmetricCipher.initialize(string algo_name, bool is_encryption) throws Error {
#if GCRYPT
        GCrypt.Cipher.Algorithm algo;
        GCrypt.Cipher.Mode mode;
        GCrypt.Cipher.Flag flags;
        if (parse(algo_name, out algo, out mode, out flags)) {
            this.gcrypt(algo, mode, flags);
        } else {
            throw new Error.ILLEGAL_ARGUMENTS(@"The algorithm $algo_name is not supported");
        }
#else
        if (algo_name == "AES-GCM") {
            this.openssl(is_encryption);
        } else {
            throw new Error.ILLEGAL_ARGUMENTS(@"The algorithm $algo_name is not supported");
        }
#endif
    }

#if GCRYPT
    private SymmetricCipher.gcrypt(GCrypt.Cipher.Algorithm algo, GCrypt.Cipher.Mode mode, GCrypt.Cipher.Flag flags) throws Error {
        may_throw_gcrypt_error(GCrypt.Cipher.Cipher.open(out this.cipher, algo, mode, flags));
    }
#else
    private SymmetricCipher.openssl(bool is_encryption) throws Error {
        this.is_encryption = is_encryption;
        cipher = new OpenSSL.EVP.CipherContext();
        if (is_encryption) {
            if (cipher.encrypt_init(OpenSSL.EVP.aes_128_gcm(), null, null, null) != 1) {
                openssl_error();
            }
        } else {
            if (cipher.decrypt_init(OpenSSL.EVP.aes_128_gcm(), null, null, null) != 1) {
                openssl_error();
            }
        }
    }
#endif

    public void set_key(uint8[] key) throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.set_key(key));
#else
        if (key.length != 16) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("key length must be 16 for AES-GCM");
        }
        if (is_encryption) {
            if (cipher.encrypt_init(null, null, key, null) != 1) {
                openssl_error();
            }
        } else {
            if (cipher.decrypt_init(null, null, key, null) != 1) {
                openssl_error();
            }
        }
#endif
    }

    public void set_iv(uint8[] iv) throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.set_iv(iv));
#else
        if (iv.length != 12) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("intialization vector must be of length 16 for AES-GCM");
        }
        if (is_encryption) {
            if (cipher.encrypt_init(null, null, null, iv) != 1) {
                openssl_error();
            }
        } else {
            if (cipher.decrypt_init(null, null, null, iv) != 1) {
                openssl_error();
            }
        }
#endif
    }

    public void reset() throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.reset());
#else
        throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't reset OpenSSL cipher context");
#endif
    }

    public uint8[] get_tag(size_t taglen) throws Error {
        uint8[] tag = new uint8[taglen];
#if GCRYPT
        may_throw_gcrypt_error(cipher.get_tag(tag));
#else
        if (!is_encryption) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't call get_tag on decryption context");
        }
        uint8[] empty = new uint8[0];
        int empty_len = 0;
        if (cipher.encrypt_final(empty, out empty_len) != 1) {
            openssl_error();
        }
        if (empty_len != 0) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("get_tag called on a stream with remaining data");
        }
        if (cipher.ctrl(OpenSSL.EVP.CTRL_GCM_GET_TAG, (int)taglen, tag) != 1) {
            openssl_error();
        }
#endif
        return tag;
    }

    public void check_tag(uint8[] tag) throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.check_tag(tag));
#else
        if (is_encryption) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't call check_tag on encryption context");
        }
        if (cipher.ctrl(OpenSSL.EVP.CTRL_GCM_SET_TAG, tag.length, tag) != 1) {
            openssl_error();
        }
        uint8[] empty = new uint8[0];
        int empty_len = 0;
        if (cipher.decrypt_final(empty, out empty_len) != 1) {
            openssl_error();
        }
        if (empty_len != 0) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("check_tag called on a stream with remaining data");
        }
#endif
    }

    public void encrypt(uint8[] output, uint8[] input) throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.encrypt(output, input));
#else
        if (!is_encryption) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't call encrypt on decryption context");
        }
        int output_length = output.length;
        if (cipher.encrypt_update(output, out output_length, input) != 1) {
            openssl_error();
        }
        if (output_length != output.length) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("invalid output array length");
        }
#endif
    }

    public void decrypt(uint8[] output, uint8[] input) throws Error {
#if GCRYPT
        may_throw_gcrypt_error(cipher.decrypt(output, input));
#else
        if (is_encryption) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't call decrypt on encryption context");
        }
        int output_length = output.length;
        if (cipher.decrypt_update(output, out output_length, input) != 1) {
            openssl_error();
        }
        if (output_length != output.length) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("invalid output array length");
        }
#endif
    }
}
}
