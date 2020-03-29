using Xmpp;

public interface Dino.Plugins.Omemo.BaseStreamModule : Object {
    public abstract bool start_session(XmppStream stream, Jid jid, int32 device_id, Bundle bundle);
    public abstract bool is_ignored_device(Jid jid, int32 device_id);
}