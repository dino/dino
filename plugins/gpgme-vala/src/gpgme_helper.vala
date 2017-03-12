using Gee;
using GPG;

namespace GPGHelper {

private static bool initialized = false;

public static string encrypt_armor(string plain, Key[] keys, EncryptFlags flags) throws GLib.Error {
    initialize();

    global_mutex.lock();
    Data plain_data = Data.create_from_memory(plain.data, false);
    Context context = Context.create();
    context.set_armor(true);
    Data enc_data = context.op_encrypt(keys, flags, plain_data);
    global_mutex.unlock();
    return get_string_from_data(enc_data);
}

public static string decrypt(string encr) throws GLib.Error {
    initialize();

    global_mutex.lock();
    Data enc_data = Data.create_from_memory(encr.data, false);
    Context context = Context.create();
    Data dec_data = context.op_decrypt(enc_data);
    global_mutex.unlock();
    return get_string_from_data(dec_data);
}

public static string sign(string plain, SigMode mode) throws GLib.Error {
    initialize();

    global_mutex.lock();
    Data plain_data = Data.create_from_memory(plain.data, false);
    Context context = Context.create();
    Data signed_data = context.op_sign(plain_data, mode);
    global_mutex.unlock();
    return get_string_from_data(signed_data);
}

public static string? get_sign_key(string signature, string? text) throws GLib.Error {
    initialize();

    global_mutex.lock();
    Data sig_data = Data.create_from_memory(signature.data, false);
    Data text_data;
    if (text != null) {
        text_data = Data.create_from_memory(text.data, false);
    } else {
        text_data = Data.create();
    }
    Context context = Context.create();
    context.op_verify(sig_data, text_data);
    VerifyResult* verify_res = context.op_verify_result();
    if (verify_res == null || verify_res.signatures == null) return null;
    global_mutex.unlock();
    return verify_res.signatures.fpr;
}

public static Gee.List<Key> get_keylist(string? pattern = null, bool secret_only = false) throws GLib.Error {
    initialize();

    Gee.List<Key> keys = new ArrayList<Key>();
    Context context = Context.create();
    context.op_keylist_start(pattern, secret_only ? 1 : 0);
    try {
        while (true) {
            Key key = context.op_keylist_next();
            keys.add(key);
        }
    } catch (Error e) {
        if (e.code != GPGError.ErrorCode.EOF) throw e;
    }
    return keys;
}

public static Key? get_public_key(string sig) throws GLib.Error {
    initialize();

    global_mutex.lock();
    Context context = Context.create();
    Key key = context.get_key(sig, false);
    global_mutex.unlock();
    return key;
}

private static string get_string_from_data(Data data) {
    initialize();

    data.seek(0);
    uint8[] buf = new uint8[256];
    ssize_t? len = null;
    string res = "";
    do {
        len = data.read(buf);
        if (len > 0) {
            string part = (string) buf;
            part = part.substring(0, (long) len);
            res += part;
        }
    } while (len > 0);
    return res;
}

private static void initialize() {
    if (!initialized) {
        check_version();
        initialized = true;
    }
}

}