namespace Dino.Plugins.Omemo {

public class EncryptStatus {
    public bool encrypted { get; internal set; }
    public int other_devices { get; internal set; }
    public int other_success { get; internal set; }
    public int other_lost { get; internal set; }
    public int other_unknown { get; internal set; }
    public int other_failure { get; internal set; }
    public int own_devices { get; internal set; }
    public int own_success { get; internal set; }
    public int own_lost { get; internal set; }
    public int own_unknown { get; internal set; }
    public int own_failure { get; internal set; }
}

}