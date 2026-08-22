namespace Dino.Crypto {

public static void randomize(uint8[] buffer) {
    GCrypt.Random.randomize(buffer);
}

internal void may_throw_gcrypt_error(GCrypt.Error e) throws Error {
    if (((int)e) != 0) {
        throw new Crypto.Error.GCRYPT(e.to_string());
    }
}

public SymmetricCipherEncryption create_symmetric_cipher_encryption(string algo_name) throws Error {
    return new SymmetricCipherGcrypt(algo_name);
}

public SymmetricCipherDecryption create_symmetric_cipher_decryption(string algo_name) throws Error {
    return new SymmetricCipherGcrypt(algo_name);
}

}
