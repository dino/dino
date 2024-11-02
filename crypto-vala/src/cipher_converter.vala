using GLib;

namespace Crypto {
public abstract class SymmetricCipherConverter : Converter, Object {
    internal SymmetricCipher cipher;
    internal size_t attached_taglen;

    public abstract ConverterResult convert(uint8[] inbuf, uint8[] outbuf, ConverterFlags flags, out size_t bytes_read, out size_t bytes_written) throws IOError;

    public uint8[] get_tag(size_t taglen) throws Error {
        return cipher.get_tag(taglen);
    }

    public void check_tag(uint8[] tag) throws Error {
        cipher.check_tag(tag);
    }

    public void reset() {
        try {
            cipher.reset();
        } catch (Crypto.Error e) {
            warning(@"$(e.domain) error while resetting cipher: $(e.message)");
        }
    }
}

public class SymmetricCipherEncrypter : SymmetricCipherConverter {
    public SymmetricCipherEncrypter(owned SymmetricCipher cipher, size_t attached_taglen = 0) {
        this.cipher = (owned) cipher;
        this.attached_taglen = attached_taglen;
    }

    public override ConverterResult convert(uint8[] inbuf, uint8[] outbuf, ConverterFlags flags, out size_t bytes_read, out size_t bytes_written) throws IOError {
        if (inbuf.length > outbuf.length) {
            throw new IOError.NO_SPACE("CipherConverter needs at least the size of input as output space");
        }
        if ((flags & ConverterFlags.INPUT_AT_END) != 0 && inbuf.length + attached_taglen > outbuf.length) {
            throw new IOError.NO_SPACE("CipherConverter needs additional output space to attach tag");
        }
        try {
            if (inbuf.length > 0) {
                cipher.encrypt(outbuf, inbuf);
            }
            bytes_read = inbuf.length;
            bytes_written = inbuf.length;
            if ((flags & ConverterFlags.INPUT_AT_END) != 0) {
                if (attached_taglen > 0) {
                    Memory.copy((uint8*)outbuf + inbuf.length, get_tag(attached_taglen), attached_taglen);
                    bytes_written = inbuf.length + attached_taglen;
                }
                return ConverterResult.FINISHED;
            }
            if ((flags & ConverterFlags.FLUSH) != 0) {
                return ConverterResult.FLUSHED;
            }
            return ConverterResult.CONVERTED;
        } catch (Crypto.Error e) {
            throw new IOError.FAILED(@"$(e.domain) error while encrypting: $(e.message)");
        }
    }
}

public class SymmetricCipherDecrypter : SymmetricCipherConverter {
    public SymmetricCipherDecrypter(owned SymmetricCipher cipher, size_t attached_taglen = 0) {
        this.cipher = (owned) cipher;
        this.attached_taglen = attached_taglen;
    }

    public override ConverterResult convert(uint8[] inbuf, uint8[] outbuf, ConverterFlags flags, out size_t bytes_read, out size_t bytes_written) throws IOError {
        if (inbuf.length > outbuf.length + attached_taglen) {
            throw new IOError.NO_SPACE("CipherConverter needs at least the size of input as output space");
        }
        if ((flags & ConverterFlags.INPUT_AT_END) != 0 && inbuf.length < attached_taglen) {
            throw new IOError.PARTIAL_INPUT("CipherConverter needs additional input to read tag");
        } else if ((flags & ConverterFlags.INPUT_AT_END) == 0 && inbuf.length < attached_taglen + 1) {
            throw new IOError.PARTIAL_INPUT("CipherConverter needs additional input to make sure to not accidentally read tag");
        }
        try {
            inbuf.length -= (int) attached_taglen;
            if (inbuf.length > 0) {
                cipher.decrypt(outbuf, inbuf);
            }
            bytes_read = inbuf.length;
            bytes_written = inbuf.length;
            inbuf.length += (int) attached_taglen;
            if ((flags & ConverterFlags.INPUT_AT_END) != 0) {
                if (attached_taglen > 0) {
                    check_tag(inbuf[(inbuf.length - attached_taglen):inbuf.length]);
                    bytes_read = inbuf.length;
                }
                return ConverterResult.FINISHED;
            }
            if ((flags & ConverterFlags.FLUSH) != 0) {
                return ConverterResult.FLUSHED;
            }
            return ConverterResult.CONVERTED;
        } catch (Crypto.Error e) {
            throw new IOError.FAILED(@"$(e.domain) error while decrypting: $(e.message)");
        }
    }
}
}
