using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class PresenceManager : StreamInteractionModule, Object {
    public const string id = "presence_manager";

    public signal void show_received(Show show, Jid jid, Account account);
    public signal void received_subscription_request(Jid jid, Account account);

    private StreamInteractor stream_interactor;
    private HashMap<Jid, HashMap<Jid, ArrayList<Show>>> shows = new HashMap<Jid, HashMap<Jid, ArrayList<Show>>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, ArrayList<Jid>> resources = new HashMap<Jid, ArrayList<Jid>>(Jid.hash_bare_func, Jid.equals_bare_func);

    public static void start(StreamInteractor stream_interactor) {
        PresenceManager m = new PresenceManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private PresenceManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
    }

    public Show get_last_show(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xmpp.Presence.Stanza? presence = Xmpp.Presence.Flag.get_flag(stream).get_presence(jid.to_string());
            if (presence != null) {
                return new Show(jid, presence.show, new DateTime.now_local());
            }
        }
        return new Show(jid, Show.OFFLINE, new DateTime.now_local());
    }

    public HashMap<Jid, ArrayList<Show>>? get_shows(Jid jid, Account account) {
        return shows[jid];
    }

    public ArrayList<Jid>? get_full_jids(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xmpp.Presence.Flag flag = Xmpp.Presence.Flag.get_flag(stream);
            if (flag == null) return null;
            Gee.List<string> resources = flag.get_resources(jid.bare_jid.to_string());
            if (resources == null) {
                return null;
            }
            ArrayList<Jid> ret = new ArrayList<Jid>(Jid.equals_func);
            resources.foreach((resource) => {
                ret.add(new Jid(resource));
                return true;
            });
            return ret;
        }
        return null;
    }

    public void request_subscription(Account account, Jid jid) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Presence.Module.IDENTITY).request_subscription(stream, jid.bare_jid.to_string());
    }

    public void approve_subscription(Account account, Jid jid) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Presence.Module.IDENTITY).approve_subscription(stream, jid.bare_jid.to_string());
    }

    public void deny_subscription(Account account, Jid jid) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Presence.Module.IDENTITY).deny_subscription(stream, jid.bare_jid.to_string());
    }

    public static PresenceManager? get_instance(StreamInteractor stream_interactor) {
        return (PresenceManager) stream_interactor.get_module(id);
    }

    internal string get_id() {
        return id;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_available_show.connect((stream, jid, show) =>
            on_received_available_show(account, new Jid(jid), show)
        );
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_unavailable.connect((stream, jid) =>
            on_received_unavailable(account, new Jid(jid))
        );
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_subscription_request.connect((stream, jid) =>
            received_subscription_request(new Jid(jid), account)
        );
    }

    private void on_received_available_show(Account account, Jid jid, string show) {
        lock (resources) {
            if (!resources.has_key(jid)){
                resources[jid] = new ArrayList<Jid>(Jid.equals_func);
            }
            if (!resources[jid].contains(jid)) {
                resources[jid].add(jid);
            }
        }
        add_show(account, jid, show);
    }

    private void on_received_unavailable(Account account, Jid jid) {
        lock (resources) {
            if (resources.has_key(jid)) {
                resources[jid].remove(jid);
                if (resources[jid].size == 0 || jid.is_bare()) {
                    resources.unset(jid);
                }
            }
        }
        add_show(account, jid, Show.OFFLINE);
    }

    private void add_show(Account account, Jid jid, string s) {
        Show show = new Show(jid, s, new DateTime.now_local());
        lock (shows) {
            if (!shows.has_key(jid)) {
                shows[jid] = new HashMap<Jid, ArrayList<Show>>();
            }
            if (!shows[jid].has_key(jid)) {
                shows[jid][jid] = new ArrayList<Show>();
            }
            shows[jid][jid].add(show);
        }
        show_received(show, jid, account);
    }
}

public class Show : Object {
    public const string ONLINE = Xmpp.Presence.Stanza.SHOW_ONLINE;
    public const string AWAY = Xmpp.Presence.Stanza.SHOW_AWAY;
    public const string CHAT = Xmpp.Presence.Stanza.SHOW_CHAT;
    public const string DND = Xmpp.Presence.Stanza.SHOW_DND;
    public const string XA = Xmpp.Presence.Stanza.SHOW_XA;
    public const string OFFLINE = "offline";

    public Jid jid;
    public string as;
    public DateTime datetime;

    public Show(Jid jid, string show, DateTime datetime) {
        this.jid = jid;
        this.as = show;
        this.datetime = datetime;
    }
}
}