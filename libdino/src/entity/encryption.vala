namespace Dino.Entities {

    public enum Encryption {
        NONE,
        PGP,
        OMEMO,
        DTLS_SRTP,
        SRTP,
        UNKNOWN;

        public bool is_some() {
            return this != NONE;
        }
    }

}