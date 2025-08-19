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

        public string to_string() {
            switch (this) {
                case NONE:
                    return "Unencrypted";
                case PGP:
                    return "OpenPGP";
                case OMEMO:
                    return "OMEMO";
                case DTLS_SRTP:
                    return "DTLS-SRTP";
                case SRTP:
                    return "SRTP";
                case UNKNOWN:
                    return "Unknown encryption scheme";
                default:
                    assert_not_reached();
            }
        }
    }

}
