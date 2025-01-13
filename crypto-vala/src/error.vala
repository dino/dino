namespace Crypto {

public errordomain Error {
    ILLEGAL_ARGUMENTS,
    GCRYPT,
    OPENSSL,
    AUTHENTICATION_FAILED,
    UNKNOWN
}

#if GCRYPT
internal void may_throw_gcrypt_error(GCrypt.Error e) throws Error {
    if (((int)e) != 0) {
        throw new Crypto.Error.GCRYPT(e.to_string());
    }
}
#else
internal void openssl_error() throws Error {
    throw new Crypto.Error.OPENSSL(OpenSSL.ERR.reason_error_string(OpenSSL.ERR.get_error()));
}
#endif
}
