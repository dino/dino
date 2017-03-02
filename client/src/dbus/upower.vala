namespace Dino {

[DBus (name = "org.freedesktop.UPower")]
public interface UPower : Object {
    public signal void Sleeping();
    public signal void Resuming();
}

public static UPower? get_upower() {
    UPower? upower = null;
    try {
        upower = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower");
    } catch (IOError e) {
        stderr.printf ("%s\n", e.message);
    }
    return upower;
}

}