namespace Dino.Plugins.Omemo {

public class EncryptState {
    public bool encrypted { get; internal set; }
    public int other_devices { get; internal set; }
    public int other_success { get; internal set; }
    public int other_lost { get; internal set; }
    public int other_unknown { get; internal set; }
    public int other_failure { get; internal set; }
    public int other_waiting_lists { get; internal set; }

    public int own_devices { get; internal set; }
    public int own_success { get; internal set; }
    public int own_lost { get; internal set; }
    public int own_unknown { get; internal set; }
    public int own_failure { get; internal set; }
    public bool own_list { get; internal set; }

    public string to_string() {
        return @"EncryptState (encrypted=$encrypted, other=(devices=$other_devices, success=$other_success, lost=$other_lost, unknown=$other_unknown, failure=$other_failure, waiting_lists=$other_waiting_lists), own=(devices=$own_devices, success=$own_success, lost=$own_lost, unknown=$own_unknown, failure=$own_failure, list=$own_list))";
    }
}

}
