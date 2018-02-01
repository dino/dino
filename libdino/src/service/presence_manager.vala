using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class PresenceManager : StreamInteractionModule, Object {
    public static ModuleIdentity<PresenceManager> IDENTITY = new ModuleIdentity<PresenceManager>("presence_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void show_received(Show show, Jid jid, Account account);
    public signal void received_subscription_request(Jid jid, Account account);

    private StreamInteractor stream_interactor;
    private HashMap<Jid, HashMap<Jid, ArrayList<Show>>> shows = new HashMap<Jid, HashMap<Jid, ArrayList<Show>>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, ArrayList<Jid>> resources = new HashMap<Jid, ArrayList<Jid>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private Gee.List<Jid> subscription_requests = new ArrayList<Jid>(Jid.equals_func);

    public static void start(StreamInteractor stream_interactor) {
        PresenceManager m = new PresenceManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private PresenceManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
    }

    public Show get_last_show(Jid jid, Account account) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xmpp.Presence.Stanza? presence = stream.get_flag(Presence.Flag.IDENTITY).get_presence(jid);
            if (presence != null) {
                return new Show(jid, presence.show, new DateTime.now_utc());
            }
        }
        return new Show(jid, Show.OFFLINE, new DateTime.now_utc());
    }

    public HashMap<Jid, ArrayList<Show>>? get_shows(Jid jid, Account account) {
        return shows[jid];
    }

    public Gee.List<Jid>? get_full_jids(Jid jid, Account account) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xmpp.Presence.Flag flag = stream.get_flag(Presence.Flag.IDENTITY);
            if (flag == null) return null;
            return flag.get_resources(jid.bare_jid);
        }
        return null;
    }

    public bool exists_subscription_request(Account account, Jid jid) {
        return subscription_requests.contains(jid);
    }

    public void request_subscription(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Presence.Module.IDENTITY).request_subscription(stream, jid.bare_jid);
    }

    public void approve_subscription(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xmpp.Presence.Module.IDENTITY).approve_subscription(stream, jid.bare_jid);
            subscription_requests.remove(jid);
        }
    }

    public void deny_subscription(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xmpp.Presence.Module.IDENTITY).deny_subscription(stream, jid.bare_jid);
            subscription_requests.remove(jid);
        }
    }

    public void cancel_subscription(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Presence.Module.IDENTITY).cancel_subscription(stream, jid.bare_jid);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_available_show.connect((stream, jid, show) =>
            on_received_available_show(account, jid, show)
        );
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_unavailable.connect((stream, presence) =>
            on_received_unavailable(account, presence.from)
        );
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_subscription_request.connect((stream, jid) => {
            if (!subscription_requests.contains(jid)) {
                subscription_requests.add(jid);
            }
            received_subscription_request(jid, account);
        });
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
        Show show = new Show(jid, s, new DateTime.now_utc());
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
