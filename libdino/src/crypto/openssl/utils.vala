namespace Dino.Crypto {

public static void randomize(uint8[] buffer) {
    OpenSSL.RAND.bytes(buffer);
}

internal void openssl_error() throws Error {
    throw new Crypto.Error.OPENSSL(OpenSSL.ERR.reason_error_string(OpenSSL.ERR.get_error()));
}

public SymmetricCipherEncryption create_symmetric_cipher_encryption(string algo_name) throws Error {
    return new SymmetricCipherEncryptionOpenssl(algo_name);
}

public SymmetricCipherDecryption create_symmetric_cipher_decryption(string algo_name) throws Error {
    return new SymmetricCipherDecryptionOpenssl(algo_name);
}

}
