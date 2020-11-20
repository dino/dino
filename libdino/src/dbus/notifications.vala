namespace Dino {

    [DBus (name = "org.freedesktop.Notifications")]
    public interface DBusNotifications : GLib.Object {

        public signal void action_invoked(uint32 key, string action_key);

        public signal void notification_closed (uint32 id, uint32 reason);

        public abstract uint32 notify(string app_name, uint32 replaces_id, string app_icon, string summary,
                                       string body, string[] actions, HashTable<string, Variant> hints, int32 expire_timeout) throws DBusError, IOError;

        public abstract void get_capabilities(out string[] capabilities) throws Error;

        public abstract void close_notification(uint id) throws DBusError, IOError;

        public abstract void get_server_information(out string name, out string vendor, out string version, out string spec_version) throws DBusError, IOError;
    }

    public static DBusNotifications? get_notifications_dbus() {
        DBusNotifications? upower = null;
        try {
            upower = Bus.get_proxy_sync(BusType.SESSION, "org.freedesktop.Notifications", "/org/freedesktop/Notifications");
        } catch (IOError e) {
            warning("Couldn't get org.freedesktop.Notifications DBus instance: %s\n", e.message);
        }
        return upower;
    }
}