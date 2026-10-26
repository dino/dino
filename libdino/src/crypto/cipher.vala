namespace Dino.Crypto {

public interface SymmetricCipher {
    public abstract void set_key(uint8[] key) throws Error;
    public abstract void set_iv(uint8[] iv) throws Error;
    public abstract void reset() throws Error;
}

public interface SymmetricCipherEncryption : SymmetricCipher, Object {
    public abstract int encrypt(uint8[] output, uint8[] input) throws Error;
    public abstract uint8[] get_tag(size_t taglen) throws Error;
}

public interface SymmetricCipherDecryption : SymmetricCipher, Object {
    public abstract int decrypt(uint8[] output, uint8[] input) throws Error;
    public abstract void check_tag(uint8[] tag) throws Error;
}

}
