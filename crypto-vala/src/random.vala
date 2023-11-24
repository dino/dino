namespace Crypto {
public static void randomize(uint8[] buffer) {
#if GCRYPT
    GCrypt.Random.randomize(buffer);
#else
    OpenSSL.RAND.bytes(buffer);
#endif
}
}
