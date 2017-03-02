namespace Dino {

[DBus (name = "org.freedesktop.login1.Manager")]
public interface Login1Manager : Object {
    public signal void PrepareForSleep(bool suspend);
}

public static Login1Manager? get_login1() {
    Login1Manager? login1 = null;
    try {
        login1 = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }
    return login1;
}

}