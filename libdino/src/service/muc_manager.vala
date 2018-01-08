using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class MucManager : StreamInteractionModule, Object {
    public static ModuleIdentity<MucManager> IDENTITY = new ModuleIdentity<MucManager>("muc_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void joined(Account account, Jid jid, string nick);
    public signal void enter_error(Account account, Jid jid, Xep.Muc.MucEnterError error);
    public signal void left(Account account, Jid jid);
    public signal void subject_set(Account account, Jid jid, string? subject);
    public signal void bookmarks_updated(Account account, Gee.List<Xep.Bookmarks.Conference> conferences);

    private StreamInteractor stream_interactor;
    private HashMap<Jid, Xep.Muc.MucEnterError> enter_errors = new HashMap<Jid, Xep.Muc.MucEnterError>(Jid.hash_func, Jid.equals_func);

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
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        string nick_ = nick ?? account.bare_jid.localpart ?? account.bare_jid.domainpart;

        DateTime? history_since = null;
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) {
            Entities.Message? last_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
            if (last_message != null) history_since = last_message.time;
        }
        
        stream.get_module(Xep.Muc.Module.IDENTITY).enter(stream, jid.bare_jid.to_string(), nick_, password, history_since);
    }

    public void part(Account account, Jid jid) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        unset_autojoin(stream, jid);
        stream.get_module(Xep.Muc.Module.IDENTITY).exit(stream, jid.bare_jid.to_string());

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
    }

    public delegate void OnResult(Jid jid, Xep.DataForms.DataForm data_form);
    public void get_config_form(Account account, Jid jid, owned OnResult listener) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        stream.get_module(Xep.Muc.Module.IDENTITY).get_config_form(stream, jid.to_string(), (stream, jid, data_form) => {
            listener(new Jid(jid), data_form);
        });
    }

    public void change_subject(Account account, Jid jid, string subject) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_subject(stream, jid.bare_jid.to_string(), subject);
    }

    public void change_nick(Account account, Jid jid, string new_nick) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_nick(stream, jid.bare_jid.to_string(), new_nick);
    }

    public void invite(Account account, Jid muc, Jid invitee) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).invite(stream, muc.bare_jid.to_string(), invitee.bare_jid.to_string());
    }

    public void kick(Account account, Jid jid, string nick) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).kick(stream, jid.bare_jid.to_string(), nick);
    }

    public void change_affiliation(Account account, Jid jid,  string role, string nick) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_affiliation(stream, jid.bare_jid.to_string(), role, nick);
    }

    public bool kick_possible(Account account, Jid occupant) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) return stream.get_module(Xep.Muc.Module.IDENTITY).kick_possible(stream, occupant.to_string());
        return false;
    }

    public ArrayList<Jid>? get_occupants(Jid jid, Account account) {
        if (is_groupchat(jid, account)) {
            return stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);
        }
        return null;
    }

    public ArrayList<Jid>? get_other_occupants(Jid jid, Account account) {
        ArrayList<Jid>? occupants = get_occupants(jid, account);
        Jid? own_jid = get_own_jid(jid, account);
        if (occupants != null && own_jid != null) {
            occupants.remove(own_jid);
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

    public void get_bookmarks(Account account, owned Xep.Bookmarks.Module.OnResult listener) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (owned)listener);
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

    public string? get_room_name(Account account, Jid jid) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        return stream != null ? stream.get_flag(Xep.Muc.Flag.IDENTITY).get_room_name(jid.to_string()) : null;
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

    public Xep.Muc.Role? get_role(Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) return stream.get_flag(Xep.Muc.Flag.IDENTITY).get_occupant_role(jid.to_string());
        return null;
    }

    public Xep.Muc.Affiliation? get_affiliation(Jid muc_jid, Jid jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) return stream.get_flag(Xep.Muc.Flag.IDENTITY).get_affiliation(muc_jid.to_string(), jid.to_string());
        return null;
    }

    public Gee.List<Jid>? get_offline_members(Jid jid, Account account) {
        Gee.List<Jid> ret = new ArrayList<Jid>(Jid.equals_func);
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Gee.List<string>? members = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_offline_members(jid.to_string());
            if (members == null) return null;
            foreach (string member in members) {
                ret.add(new Jid(member));
            }
        }
        return ret;
    }

    public Jid? get_own_jid(Jid muc_jid, Account account) {
        Core.XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
            if (flag == null) return null;
            string? nick  = flag.get_muc_nick(muc_jid.bare_jid.to_string());
            if (nick != null) return new Jid.with_resource(muc_jid.bare_jid.to_string(), nick);
        }
        return null;
    }

    public bool is_joined(Jid jid, Account account) {
        return get_own_jid(jid, account) != null;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_entered.connect( (stream, jid_string, nick) => {
            Jid jid = new Jid(jid_string);
            enter_errors.unset(jid);
            set_autojoin(stream, jid, nick, null); // TODO password
            joined(account, jid, nick);
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_unsent_messages(account, jid);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_enter_error.connect( (stream, jid_str, error) => {
            Jid jid = new Jid(jid_str);
            enter_errors[jid] = error;
            enter_error(account, jid, error);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).self_removed_from_room.connect( (stream, jid, code) => {
            left(account, new Jid(jid));
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).subject_set.connect( (stream, subject, jid) => {
            subject_set(account, new Jid(jid), subject);
        });
        stream_interactor.module_manager.get_module(account, Xep.Bookmarks.Module.IDENTITY).received_conferences.connect( (stream, conferences) => {
            sync_autojoin_active(account, conferences);
            bookmarks_updated(account, conferences);
        });
    }

    private void on_stream_negotiated(Account account, Core.XmppStream stream) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            foreach (Xep.Bookmarks.Conference bookmark in conferences) {
                Jid jid = new Jid(bookmark.jid);
                if (bookmark.autojoin) {
                    join(account, jid, bookmark.nick, bookmark.password);
                }
            }
        });
    }

    private void on_pre_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
        if (conversation.type_ != Conversation.Type.GROUPCHAT) return;
        Core.XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return;
        if (Xep.DelayedDelivery.MessageFlag.get_flag(message.stanza) == null) {
            string? real_jid = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_real_jid(message.counterpart.to_string());
            if (real_jid != null && real_jid != message.counterpart.to_string()) {
                message.real_jid = new Jid(real_jid).bare_jid;
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

    private void sync_autojoin_active(Account account, Gee.List<Xep.Bookmarks.Conference> conferences) {
        Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations();
        leave_non_autojoin(account, conferences, conversations);
        join_autojoin(account, conferences, conversations);
    }

    private void leave_non_autojoin(Account account, Gee.List<Xep.Bookmarks.Conference> conferences, Gee.List<Conversation> conversations) {
        foreach (Conversation conversation in conversations) {
            if (conversation.type_ != Conversation.Type.GROUPCHAT || !conversation.account.equals(account)) continue;
            bool is_autojoin = false;
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid == conversation.counterpart.to_string()) {
                    if (conference.autojoin) is_autojoin = true;
                }
            }
            if (!is_autojoin) {
                part(account, conversation.counterpart);
            }
        }
    }

    private void join_autojoin(Account account, Gee.List<Xep.Bookmarks.Conference> conferences, Gee.List<Conversation> conversations) {
        foreach (Xep.Bookmarks.Conference conference in conferences) {
            if (!conference.autojoin) continue;
            bool is_active = false;
            foreach (Conversation conversation in conversations) {
                if (conference.jid == conversation.counterpart.to_string()) is_active = true;
            }
            if (!is_active) {
                join(account, new Jid(conference.jid), conference.nick, conference.password);
            }
        }
    }

    private void set_autojoin(Core.XmppStream stream, Jid jid, string? nick, string? password) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            Xep.Bookmarks.Conference changed = new Xep.Bookmarks.Conference(jid.to_string()) { nick=nick, password=password, autojoin=true };
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid == jid.bare_jid.to_string() && conference.nick == nick && conference.password == password) {
                    if (!conference.autojoin) {
                        stream.get_module(Xep.Bookmarks.Module.IDENTITY).replace_conference(stream, conference, changed);
                    }
                    return;
                }
            }
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).add_conference(stream, changed);
        });
    }

    private void unset_autojoin(Core.XmppStream stream, Jid jid) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid == jid.bare_jid.to_string()) {
                    if (conference.autojoin) {
                        Xep.Bookmarks.Conference change = new Xep.Bookmarks.Conference(conference.jid) { nick=conference.nick, password=conference.password, autojoin=false };
                        stream.get_module(Xep.Bookmarks.Module.IDENTITY).replace_conference(stream, conference, change);
                    }
                }
            }
        });
    }
}

}
