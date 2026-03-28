namespace Crypto {
public static void randomize(uint8[] buffer) {
    GCrypt.Random.randomize(buffer);
}
}