public enum Dino.Plugins.Omemo.ProtocolVersion {
    UNKNOWN,
    LEGACY,
    V1;

    public static ProtocolVersion from_int(int i) {
        switch (i) {
            case 0: return LEGACY;
            case 1: return V1;
        }
        return UNKNOWN;
    }

    public int to_int() {
        switch (this) {
            case LEGACY: return 0;
            case V1: return 1;
        }
        return -1;
    }
}