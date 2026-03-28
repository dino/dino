namespace Crypto {

public errordomain Error {
    ILLEGAL_ARGUMENTS,
    GCRYPT,
    AUTHENTICATION_FAILED,
    UNKNOWN
}

internal void may_throw_gcrypt_error(GCrypt.Error e) throws Error {
    if (((int)e) != 0) {
        throw new Crypto.Error.GCRYPT(e.to_string());
    }
}
}