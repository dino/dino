namespace Dino {

[DBus (name = "org.freedesktop.login1.Manager")]
public interface Login1Manager : Object {
    public signal void PrepareForSleep(bool suspend);
    public abstract GLib.ObjectPath get_session(string session_id) throws DBusError, IOError;
}

public static async Login1Manager? get_login1() {
    try {
        return yield Bus.get_proxy(BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }
    return null;
}

[DBus (name = "org.freedesktop.login1.Session")]
public interface Login1Session : Object {
    public abstract bool locked_hint {  get; }
}

public static async Login1Session? get_login1_session(string session) {
    try {
        return yield Bus.get_proxy(BusType.SYSTEM, "org.freedesktop.login1", session);
    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }
    return null;
}

}