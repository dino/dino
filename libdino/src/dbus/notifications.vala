namespace Dino {

    [DBus (name = "org.freedesktop.Notifications")]
    public interface DBusNotifications : GLib.Object {

        public signal void action_invoked(uint32 key, string action_key);

        public signal void notification_closed (uint32 id, uint32 reason);

        public abstract async uint32 notify(string app_name, uint32 replaces_id, string app_icon, string summary,
                                       string body, string[] actions, HashTable<string, Variant> hints, int32 expire_timeout) throws DBusError, IOError;

        public abstract async void get_capabilities(out string[] capabilities) throws Error;

        public abstract async void close_notification(uint id) throws DBusError, IOError;

        public abstract async void get_server_information(out string name, out string vendor, out string version, out string spec_version) throws DBusError, IOError;
    }

    // This function will always return. Sometimes Glib.Bus.get_proxy doesn't return, but this function covers that with a timeout.
    // Returns null if the dbus notifications interface can't be obtained (if timeout or exception)
    public static async DBusNotifications? get_notifications_dbus() {
        DBusNotifications? ret = null;
        Cancellable cancellable = new Cancellable();

        uint timeout_handle_id = 0;
        timeout_handle_id = Timeout.add_seconds(10, () => {
            if (timeout_handle_id != 0) {
                warning("Timeout waiting for org.freedesktop.Notifications DBus instance");
                timeout_handle_id = 0;
                cancellable.cancel();
                Idle.add(get_notifications_dbus.callback);
            }
            return false;
        });

        Bus.get_proxy.begin<DBusNotifications>(BusType.SESSION, "org.freedesktop.Notifications", "/org/freedesktop/Notifications", 0, cancellable, (_, res) => {
            try {
                ret = Bus.get_proxy.end(res);
            } catch(IOError e) {
                warning("Couldn't get org.freedesktop.Notifications DBus instance: %s", e.message);
            }
            if (timeout_handle_id != 0) {
                Source.remove(timeout_handle_id);
                timeout_handle_id = 0;
                Idle.add(get_notifications_dbus.callback);
            }
        });

        yield;

        return ret;
    }
}