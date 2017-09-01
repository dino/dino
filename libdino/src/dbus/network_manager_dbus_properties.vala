[DBus (name = "org.freedesktop.DBus.Properties")]
public interface NetworkManagerDBusProperties : GLib.Object {
    public signal void properties_changed(string iface, HashTable<string, Variant> changed, string[] invalidated);
}

public static NetworkManagerDBusProperties? get_dbus_properties() {
    NetworkManagerDBusProperties? dbus_properties = null;
    try {
        dbus_properties = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.DBus.Properties", "/org/freedesktop/NetworkManager");
    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }
    return dbus_properties;
}
