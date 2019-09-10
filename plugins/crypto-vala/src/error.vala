namespace Crypto {

public errordomain Error {
    ILLEGAL_ARGUMENTS,
    GCRYPT
}

internal void may_throw_gcrypt_error(GCrypt.Error e) throws GLib.Error {
    if (((int)e) != 0) {
        throw new Crypto.Error.GCRYPT(e.to_string());
    }
}
}