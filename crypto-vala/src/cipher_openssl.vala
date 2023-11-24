namespace Crypto {

internal class SymmetricCipherEncryptionOpenssl : SymmetricCipher, SymmetricCipherEncryption, Object {
    private OpenSSL.EVP.CipherContext? cipher;
    private bool is_finalized = false;

    public SymmetricCipherEncryptionOpenssl(string algo_name) throws Error {
        if (algo_name != "AES-GCM") throw new Error.ILLEGAL_ARGUMENTS(@"The algorithm $algo_name is not supported");
        cipher = new OpenSSL.EVP.CipherContext();
    }

    public void set_key(uint8[] key) throws Error {
        unowned OpenSSL.EVP.Cipher algo;
        if (key.length == 16) {
            algo = OpenSSL.EVP.aes_128_gcm();
        } else if (key.length == 32) {
            algo = OpenSSL.EVP.aes_256_gcm();
        } else {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("key length must be 16 or 32 for AES-GCM");
        }
        try {
            cipher.encrypt_init(algo, null, null);
            cipher.encrypt_init(null, key, null);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
    }

    public void set_iv(uint8[] iv) throws Error {
        if (iv.length != 12) {
            cipher.ctrl(OpenSSL.EVP.Control.GCM_SET_IVLEN, iv.length, null);
        }
        try {
            cipher.encrypt_init(null, null, iv);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
    }

    public void reset() throws Error {
        throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't reset OpenSSL cipher context");
    }

    public uint8[] get_tag(size_t taglen) throws Error {
        uint8[] tag = new uint8[taglen];
        if (!is_finalized) {
            uint8[] empty = new uint8[0];
            int empty_len = 0;
            try {
                cipher.encrypt_final(empty, out empty_len);
            } catch (GLib.Error e) {
                throw new Crypto.Error.OPENSSL(e.message);
            }
            if (empty_len != 0) {
                throw new Crypto.Error.ILLEGAL_ARGUMENTS("get_tag called on a stream with remaining data");
            }
        }
        if (cipher.ctrl(OpenSSL.EVP.Control.GCM_GET_TAG, (int)taglen, tag) != 1) {
            openssl_error();
        }
        return tag;
    }

    public int encrypt(uint8[] output, uint8[] input) throws Error {
        int output_length = output.length;
        if (is_finalized) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("encrypt called after get_tag");
        }
        try {
            cipher.encrypt_update(output, out output_length, input);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
        return output_length;
    }
}

internal class SymmetricCipherDecryptionOpenssl : SymmetricCipher, SymmetricCipherDecryption, Object {
    private OpenSSL.EVP.CipherContext? cipher;
    private bool is_finalized = false;

    public SymmetricCipherDecryptionOpenssl(string algo_name) throws Error {
        if (algo_name != "AES-GCM") throw new Error.ILLEGAL_ARGUMENTS(@"The algorithm $algo_name is not supported");
        cipher = new OpenSSL.EVP.CipherContext();
        try {
            cipher.decrypt_init(OpenSSL.EVP.aes_128_gcm(), null, null);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
    }

    public void set_key(uint8[] key) throws Error {
        unowned OpenSSL.EVP.Cipher algo;
        if (key.length == 16) {
            algo = OpenSSL.EVP.aes_128_gcm();
        } else if (key.length == 32) {
            algo = OpenSSL.EVP.aes_256_gcm();
        } else {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("key length must be 16 or 32 for AES-GCM");
        }
        try {
            cipher.decrypt_init(algo, null, null);
            cipher.decrypt_init(null, key, null);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
    }

    public void set_iv(uint8[] iv) throws Error {
        if (iv.length != 12) {
            cipher.ctrl(OpenSSL.EVP.Control.GCM_SET_IVLEN, iv.length, null);
        }
        try {
            cipher.decrypt_init(null, null, iv);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
    }

    public void reset() throws Error {
        throw new Crypto.Error.ILLEGAL_ARGUMENTS("can't reset OpenSSL cipher context");
    }

    public void check_tag(uint8[] tag) throws Error {
        if (cipher.ctrl(OpenSSL.EVP.Control.GCM_SET_TAG, tag.length, tag) != 1) {
            openssl_error();
        }
        if (!is_finalized) {
            uint8[] empty = new uint8[0];
            int empty_len = 0;
            try {
                cipher.decrypt_final(empty, out empty_len);
            } catch (GLib.Error e) {
                throw new Crypto.Error.OPENSSL(e.message);
            }
            if (empty_len != 0) {
                throw new Crypto.Error.ILLEGAL_ARGUMENTS("check_tag called on a stream with remaining data");
            }
        }
    }

    public int decrypt(uint8[] output, uint8[] input) throws Error {
        if (is_finalized) {
            throw new Crypto.Error.ILLEGAL_ARGUMENTS("decrypt called after check_tag");
        }
        int output_length = output.length;
        try {
            cipher.decrypt_update(output, out output_length, input);
        } catch (GLib.Error e) {
            throw new Crypto.Error.OPENSSL(e.message);
        }
        return output_length;
    }
}

}
