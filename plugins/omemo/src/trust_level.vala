namespace Dino.Plugins.Omemo {

public enum TrustLevel {
    VERIFIED,
    TRUSTED,
    UNTRUSTED,
    UNKNOWN;

    public string to_string() {
        int val = this;
        return val.to_string();
    }
}

}
