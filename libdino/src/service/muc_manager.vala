using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class MucManager : StreamInteractionModule, Object {
    public const string id = "muc_manager";

    public signal void groupchat_joined(Account account, Jid jid, string nick);
    public signal void groupchat_subject_set(Account account, Jid jid, string subject);
    public signal void bookmarks_updated(Account account, ArrayList<Xep.Bookmarks.Conference> conferences);

    private StreamInteractor stream_interactor;
    protected HashMap<Jid, Xep.Bookmarks.Conference> conference_bookmarks = new HashMap<Jid, Xep.Bookmarks.Conference>();

    public static void start(StreamInteractor stream_interactor) {
        MucManager m = new MucManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private MucManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        MessageManager.get_instance(stream_interactor).pre_message_received.connect(on_pre_message_received);
    }

    public void join(Account account, Jid jid, string nick, string? password = null) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Muc.Module.get_module(stream).enter(stream, jid.bare_jid.to_string(), nick, password, new MucEnterListenerImpl(this, jid, nick, account));
    }

    public void part(Account account, Jid jid) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Muc.Module.get_module(stream).exit(stream, jid.bare_jid.to_string());
    }

    public void change_subject(Account account, Jid jid, string subject) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Muc.Module.get_module(stream).change_subject(stream, jid.bare_jid.to_string(), subject);
    }

    public void change_nick(Account account, Jid jid, string new_nick) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Muc.Module.get_module(stream).change_nick(stream, jid.bare_jid.to_string(), new_nick);
    }

    public void kick(Account account, Jid jid, string nick) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Muc.Module.get_module(stream).kick(stream, jid.bare_jid.to_string(), nick);
    }

    public ArrayList<Jid>? get_occupants(Jid jid, Account account) {
        return PresenceManager.get_instance(stream_interactor).get_full_jids(jid, account);
    }

    public ArrayList<Jid>? get_other_occupants(Jid jid, Account account) {
        ArrayList<Jid>? occupants = get_occupants(jid, account);
        string? nick = get_nick(jid, account);
        if (occupants != null && nick != null) {
            occupants.remove(new Jid(@"$(jid.bare_jid)/$nick"));
        }
        return occupants;
    }

    public bool is_groupchat(Jid jid, Account account) {
        Conversation? conversation = ConversationManager.get_instance(stream_interactor).get_conversation(jid, account);
        return !jid.is_full() && conversation != null && conversation.type_ == Conversation.Type.GROUPCHAT;
    }

    public bool is_groupchat_occupant(Jid jid, Account account) {
        return is_groupchat(jid.bare_jid, account) && jid.is_full();
    }

    public void get_bookmarks(Account account, Xep.Bookmarks.ConferencesRetrieveResponseListener listener) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.Bookmarks.Module.get_module(stream).get_conferences(stream, listener);
        }
    }

    public void add_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.Bookmarks.Module.get_module(stream).add_conference(stream, conference);
        }
    }

    public void replace_bookmark(Account account, Xep.Bookmarks.Conference was, Xep.Bookmarks.Conference replace) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.Bookmarks.Module.get_module(stream).replace_conference(stream, was, replace);
        }
    }

    public void remove_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.Bookmarks.Module.get_module(stream).remove_conference(stream, conference);
        }
    }

    public string? get_groupchat_subject(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            return Xep.Muc.Flag.get_flag(stream).get_muc_subject(jid.bare_jid.to_string());
        }
        return null;
    }

    public Jid? get_real_jid(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            string? real_jid = Xep.Muc.Flag.get_flag(stream).get_real_jid(jid.to_string());
            if (real_jid != null) {
                return new Jid(real_jid);
            }
        }
        return null;
    }

    public Jid? get_message_real_jid(Entities.Message message) {
        if (message.real_jid != null) {
            return new Jid(message.real_jid);
        }
        return null;
    }

    public string? get_nick(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            return Xep.Muc.Flag.get_flag(stream).get_muc_nick(jid.bare_jid.to_string());
        }
        return null;
    }

    public static MucManager? get_instance(StreamInteractor stream_interactor) {
        return (MucManager) stream_interactor.get_module(id);
    }

    internal string get_id() {
        return id;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).subject_set.connect( (stream, subject, jid) => {
            on_subject_set(account, new Jid(jid), subject);
        });
        stream_interactor.module_manager.get_module(account, Xep.Bookmarks.Module.IDENTITY).conferences_updated.connect( (stream, conferences) => {
            bookmarks_updated(account, conferences);
        });
    }

    private void on_subject_set(Account account, Jid sender_jid, string subject) {
        groupchat_subject_set(account, sender_jid, subject);
    }

    private void on_stream_negotiated(Account account) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) Xep.Bookmarks.Module.get_module(stream).get_conferences(stream, new BookmarksRetrieveResponseListener(this, account));
    }

    private void on_pre_message_received(Entities.Message message, Conversation conversation) {
        if (conversation.type_ != Conversation.Type.GROUPCHAT) return;
        Core.XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return;
        if (Xep.DelayedDelivery.MessageFlag.get_flag(message.stanza) == null) {
            string? real_jid = Xep.Muc.Flag.get_flag(stream).get_real_jid(message.counterpart.to_string());
            if (real_jid != null && real_jid != message.counterpart.to_string()) {
                message.real_jid = real_jid;
            }
        }
        string muc_nick = Xep.Muc.Flag.get_flag(stream).get_muc_nick(conversation.counterpart.bare_jid.to_string());
        if (message.from.equals(new Jid(@"$(message.from.bare_jid)/$muc_nick"))) { // TODO better from own
            Gee.List<Entities.Message>? messages = MessageManager.get_instance(stream_interactor).get_messages(conversation);
            if (messages != null) { // TODO not here
                foreach (Entities.Message m in messages) {
                    if (m.equals(message)) {
                        m.marked = Entities.Message.Marked.RECEIVED;
                    }
                }
            }
        }
    }

    private class BookmarksRetrieveResponseListener : Xep.Bookmarks.ConferencesRetrieveResponseListener, Object {
        MucManager outer = null;
        Account account = null;

        public BookmarksRetrieveResponseListener(MucManager outer, Account account) {
            this.outer = outer;
            this.account = account;
        }

        public void on_result(Core.XmppStream stream, ArrayList<Xep.Bookmarks.Conference> conferences) {
            foreach (Xep.Bookmarks.Conference bookmark in conferences) {
                Jid jid = new Jid(bookmark.jid);
                outer.conference_bookmarks[jid] = bookmark;
                if (bookmark.autojoin) {
                    outer.join(account, jid, bookmark.nick);
                }
            }
        }
    }

    private class MucEnterListenerImpl : Xep.Muc.MucEnterListener, Object { // TODO
        private MucManager outer;
        private Jid jid;
        private string nick;
        private Account account;
        public MucEnterListenerImpl(MucManager outer, Jid jid, string nick, Account account) {
            this.outer = outer;
            this.jid = jid;
            this.nick = nick;
            this.account = account;
        }
        public void on_success() {
            outer.groupchat_joined(account, jid, nick);
        }
        public void on_error(Xep.Muc.MucEnterError error) { }
    }
}
}