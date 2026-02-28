namespace Dino {

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBusManager : Object {
        public abstract async bool name_has_owner(string name);
        // many more methods available but unused here..
    }

    public static async bool dbus_service_available(string name, bool system = false) {
        try {
            DBusManager dbus = yield Bus.get_proxy(system ? BusType.SYSTEM : BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
            return yield dbus.name_has_owner(name);
        } catch (IOError e) {
            warning("Failed to query D-Bus: %s", e.message);
        }
        return false;
    }

}
