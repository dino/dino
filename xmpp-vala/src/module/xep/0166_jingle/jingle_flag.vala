using Gee;
using Xmpp;

public class Xmpp.Xep.Jingle.Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "jingle");

    public HashMap<string, Session> sessions = new HashMap<string, Session>();
    public HashMap<string, Promise<Session?>> promises = new HashMap<string, Promise<Session?>>();

    // We might get transport-infos about a session before we finished fully creating the session. (e.g. telepathy outgoing calls)
    // Thus, we "pre add" the session as soon as possible and can then await it.
    public void pre_add_session(string sid) {
        var promise = new Promise<Session?>();
        promises[sid] = promise;
    }

    public void add_session(Session session) {
        if (promises.has_key(session.sid)) {
            promises[session.sid].set_value(session);
            promises.unset(session.sid);
        }
        sessions[session.sid] = session;
    }

    public async Session? get_session(string sid) {
        if (promises.has_key(sid)) {
            return yield promises[sid].future.wait_async();
        }
        return sessions[sid];
    }

    public void remove_session(string sid) {
        sessions.unset(sid);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}