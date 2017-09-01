namespace Dino {

[DBus (name = "org.freedesktop.NetworkManager")]
public interface NetworkManager : Object {

    public const int CONNECTED_GLOBAL = 70;

    public abstract uint32 State {owned get;}
    public signal void StateChanged(uint32 state);
}

public static NetworkManager? get_network_manager() {
    NetworkManager? nm = null;
    try {
        nm = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager");
    } catch (IOError e) {
        stderr.printf ("%s\n", e.message);
    }
    return nm;
}

}
