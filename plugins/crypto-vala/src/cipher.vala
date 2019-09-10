namespace Crypto {
public class SymmetricCipher {
    private GCrypt.Cipher.Cipher cipher;

    public static bool supports(string algo_name) {
        GCrypt.Cipher.Algorithm algo;
        GCrypt.Cipher.Mode mode;
        GCrypt.Cipher.Flag flags;
        return parse(algo_name, out algo, out mode, out flags);
    }

    private static unowned string mode_to_string(GCrypt.Cipher.Mode mode) {
        switch (mode) {
            case ECB: return "ECB";
            case CFB: return "CFB";
            case CBC: return "CBC";
            case STREAM: return "STREAM";
            case OFB: return "OFB";
            case CTR: return "CTR";
            case AESWRAP: return "AESWRAP";
            case GCM: return "GCM";
            case POLY1305: return "POLY1305";
            case OCB: return "OCB";
            case CFB8: return "CFB8";
            case XTS: return "XTS";
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
            case "XTS": return GCrypt.Cipher.Mode.XTS;
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

    public SymmetricCipher(string algo_name) throws Error {
        GCrypt.Cipher.Algorithm algo;
        GCrypt.Cipher.Mode mode;
        GCrypt.Cipher.Flag flags;
        if (parse(algo_name, out algo, out mode, out flags)) {
            this.gcrypt(algo, mode, flags);
        } else {
            throw new Error.ILLEGAL_ARGUMENTS(@"The algorithm $algo_name is not supported");
        }
    }

    private SymmetricCipher.gcrypt(GCrypt.Cipher.Algorithm algo, GCrypt.Cipher.Mode mode, GCrypt.Cipher.Flag flags) throws Error {
        may_throw_gcrypt_error(GCrypt.Cipher.Cipher.open(out this.cipher, algo, mode, flags));
    }

    public void set_key(uint8[] key) throws Error {
        may_throw_gcrypt_error(cipher.set_key(key));
    }

    public void set_iv(uint8[] iv) throws Error {
        may_throw_gcrypt_error(cipher.set_iv(iv));
    }

    public void set_counter_vector(uint8[] ctr) throws Error {
        may_throw_gcrypt_error(cipher.set_counter_vector(ctr));
    }

    public void reset() throws Error {
        may_throw_gcrypt_error(cipher.reset());
    }

    public uint8[] get_tag(size_t taglen) throws Error {
        uint8[] tag = new uint8[taglen];
        may_throw_gcrypt_error(cipher.get_tag(tag));
        return tag;
    }

    public void check_tag(uint8[] tag) throws Error {
        may_throw_gcrypt_error(cipher.check_tag(tag));
    }

    public void encrypt(uint8[] output, uint8[] input) throws Error {
        may_throw_gcrypt_error(cipher.encrypt(output, input));
    }

    public void decrypt(uint8[] output, uint8[] input) throws Error {
        may_throw_gcrypt_error(cipher.decrypt(output, input));
    }

    public void sync() throws Error {
        may_throw_gcrypt_error(cipher.sync());
    }
}
}