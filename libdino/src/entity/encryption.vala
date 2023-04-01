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

        public static Encryption parse(string str) {
            switch (str) {
                case "DINO_ENTITIES_ENCRYPTION_NONE":
                    return NONE;
                case "DINO_ENTITIES_ENCRYPTION_PGP":
                    return PGP;
                case "DINO_ENTITIES_ENCRYPTION_OMEMO":
                    return OMEMO;
                case "DINO_ENTITIES_ENCRYPTION_DTLS_SRTP":
                    return DTLS_SRTP;
                case "DINO_ENTITIES_ENCRYPTION_SRTP":
                    return SRTP;
                case "DINO_ENTITIES_ENCRYPTION_UNKNOWN":
                    // Fall through.
                default:
                    break;
            }

            return UNKNOWN;
        }
    }

}