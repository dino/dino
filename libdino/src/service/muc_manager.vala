using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class MucManager : StreamInteractionModule, Object {
    public static ModuleIdentity<MucManager> IDENTITY = new ModuleIdentity<MucManager>("muc_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void joined(Account account, Jid jid, string nick);
    public signal void left(Account account, Jid jid);
    public signal void subject_set(Account account, Jid jid, string? subject);
    public signal void bookmarks_updated(Account account, ArrayList<Xep.Bookmarks.Conference> conferences);

    private StreamInteractor stream_interactor;

    public static void start(StreamInteractor stream_interactor) {
        MucManager m = new MucManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private MucManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_received.connect(on_pre_message_received);
    }

    public void join(Account account, Jid jid, string? nick, string? password) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        string nick_ = nick ?? account.bare_jid.localpart ?? account.bare_jid.domainpart;
        stream.get_module(Xep.Muc.Module.IDENTITY).enter(stream, jid.bare_jid.to_string(), nick_, password);
    }

    public void part(Account account, Jid jid) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).exit(stream, jid.bare_jid.to_string());
    }

    public void change_subject(Account account, Jid jid, string subject) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_subject(stream, jid.bare_jid.to_string(), subject);
    }

    public void change_nick(Account account, Jid jid, string new_nick) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_nick(stream, jid.bare_jid.to_string(), new_nick);
    }

    public void kick(Account account, Jid jid, string nick) {
        Core.XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).kick(stream, jid.bare_jid.to_string(), nick);
    }

    public ArrayList<Jid>? get_occupants(Jid jid, Account account) {
        if (is_groupchat(jid, account)) {
            return stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);
        }
        return null;
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
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        return !jid.is_full() && conversation != null && conversation.type_ == Conversation.Type.GROUPCHAT;
    }

    public bool is_groupchat_occupant(Jid jid, Account account) {
        return is_groupchat(jid.bare_jid, account) && jid.is_full();
    }

    public void get_bookmarks(Account account, Xep.Bookmarks.Module.OnResult listener, Object? store) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, listener, store);
        }
    }

    public void add_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).add_conference(stream, conference);
        }
    }

    public void replace_bookmark(Account account, Xep.Bookmarks.Conference was, Xep.Bookmarks.Conference replace) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).replace_conference(stream, was, replace);
        }
    }

    public void remove_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).remove_conference(stream, conference);
        }
    }

    public string? get_groupchat_subject(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            return stream.get_flag(Xep.Muc.Flag.IDENTITY).get_muc_subject(jid.bare_jid.to_string());
        }
        return null;
    }

    public Jid? get_real_jid(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            string? real_jid = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_real_jid(jid.to_string());
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
            Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
            if (flag != null) return flag.get_muc_nick(jid.bare_jid.to_string());
        }
        return null;
    }

    public bool is_joined(Jid jid, Account account) {
        return get_nick(jid, account) != null;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_entered.connect( (stream, jid, nick) => {
            joined(account, new Jid(jid), nick);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).self_removed_from_room.connect( (stream, jid, code) => {
            left(account, new Jid(jid));
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).subject_set.connect( (stream, subject, jid) => {
            subject_set(account, new Jid(jid), subject);
        });
        stream_interactor.module_manager.get_module(account, Xep.Bookmarks.Module.IDENTITY).conferences_updated.connect( (stream, conferences) => {
            bookmarks_updated(account, conferences);
        });
    }

    private void on_stream_negotiated(Account account, Core.XmppStream stream) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences, o) => {
            Tuple<MucManager, Account> tuple = o as Tuple<MucManager, Account>;
            MucManager outer_ = tuple.a;
            Account account_ = tuple.b;
            foreach (Xep.Bookmarks.Conference bookmark in conferences) {
                Jid jid = new Jid(bookmark.jid);
                if (bookmark.autojoin) {
                    outer_.join(account_, jid, bookmark.nick, bookmark.password);
                }
            }
        }, Tuple.create(this, account));
    }

    private void on_pre_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
        if (conversation.type_ != Conversation.Type.GROUPCHAT) return;
        Core.XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return;
        if (Xep.DelayedDelivery.MessageFlag.get_flag(message.stanza) == null) {
            string? real_jid = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_real_jid(message.counterpart.to_string());
            if (real_jid != null && real_jid != message.counterpart.to_string()) {
                message.real_jid = real_jid;
            }
        }
        string? muc_nick = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_muc_nick(conversation.counterpart.bare_jid.to_string());
        if (muc_nick != null && message.from.equals(new Jid(@"$(message.from.bare_jid)/$muc_nick"))) { // TODO better from own
            Gee.List<Entities.Message> messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation);
            foreach (Entities.Message m in messages) { // TODO not here
                if (m.equals(message)) {
                    m.marked = Entities.Message.Marked.RECEIVED;
                }
            }
        }
    }
}

}