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
    public signal void room_name_set(Account account, Jid jid, string? room_name);
    public signal void private_room_occupant_updated(Account account, Jid room, Jid occupant);
    public signal void bookmarks_updated(Account account, Gee.List<Xep.Bookmarks.Conference> conferences);

    private StreamInteractor stream_interactor;
    private HashMap<Jid, Xep.Muc.MucEnterError> enter_errors = new HashMap<Jid, Xep.Muc.MucEnterError>(Jid.hash_func, Jid.equals_func);
    private ReceivedMessageListener received_message_listener;

    public static void start(StreamInteractor stream_interactor) {
        MucManager m = new MucManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private MucManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.received_message_listener = new ReceivedMessageListener(stream_interactor);
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
    }

    public void join(Account account, Jid jid, string? nick, string? password) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        string nick_ = nick ?? account.bare_jid.localpart ?? account.bare_jid.domainpart;

        DateTime? history_since = null;
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) {
            Entities.Message? last_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
            if (last_message != null) history_since = last_message.time;
        }

        stream.get_module(Xep.Muc.Module.IDENTITY).enter(stream, jid.bare_jid, nick_, password, history_since);
    }

    public void part(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        unset_autojoin(stream, jid);
        stream.get_module(Xep.Muc.Module.IDENTITY).exit(stream, jid.bare_jid);

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
    }

    public delegate void OnResult(Jid jid, Xep.DataForms.DataForm data_form);
    public void get_config_form(Account account, Jid jid, owned OnResult listener) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        stream.get_module(Xep.Muc.Module.IDENTITY).get_config_form(stream, jid, (stream, jid, data_form) => {
            listener(jid, data_form);
        });
    }

    public void change_subject(Account account, Jid jid, string subject) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_subject(stream, jid.bare_jid, subject);
    }

    public void change_nick(Account account, Jid jid, string new_nick) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_nick(stream, jid.bare_jid, new_nick);
    }

    public void invite(Account account, Jid muc, Jid invitee) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).invite(stream, muc.bare_jid, invitee.bare_jid);
    }

    public void kick(Account account, Jid jid, string nick) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).kick(stream, jid.bare_jid, nick);
    }

    public void change_affiliation(Account account, Jid jid, string nick, string role) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_affiliation(stream, jid.bare_jid, nick, role);
    }

    public bool kick_possible(Account account, Jid occupant) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) return stream.get_module(Xep.Muc.Module.IDENTITY).kick_possible(stream, occupant);
        return false;
    }

    //the term `private room` is a short hand for members-only+non-anonymous rooms
    public bool is_private_room(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return false;
        }
        Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
        if (flag == null) {
            return false;
        }
        return flag.has_room_feature(jid, Xep.Muc.Feature.NON_ANONYMOUS) && flag.has_room_feature(jid, Xep.Muc.Feature.MEMBERS_ONLY);
    }

    public bool is_public_room(Account account, Jid jid) {
        return is_groupchat(jid, account) && !is_private_room(account, jid);
    }

    public Gee.List<Jid>? get_occupants(Jid jid, Account account) {
        if (is_groupchat(jid, account)) {
            Gee.List<Jid> ret = new ArrayList<Jid>(Jid.equals_func);
            Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);
            if (full_jids != null) {
                ret.add_all(full_jids);
                // Remove eventual presence from bare jid
                ret.remove(jid);
            }
            return ret;
        }
        return null;
    }

    public Gee.List<Jid>? get_other_occupants(Jid jid, Account account) {
        Gee.List<Jid>? occupants = get_occupants(jid, account);
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
        return is_groupchat(jid.bare_jid, account) && jid.resourcepart != null;
    }

    public void get_bookmarks(Account account, owned Xep.Bookmarks.Module.OnResult listener) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (owned)listener);
    }

    public void add_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).add_conference(stream, conference);
        }
    }

    public void replace_bookmark(Account account, Xep.Bookmarks.Conference was, Xep.Bookmarks.Conference replace) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).replace_conference(stream, was, replace);
        }
    }

    public void remove_bookmark(Account account, Xep.Bookmarks.Conference conference) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).remove_conference(stream, conference);
        }
    }

    public string? get_room_name(Account account, Jid jid) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_room_name(jid);
        }
        return null;
    }

    public string? get_groupchat_subject(Jid jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_muc_subject(jid.bare_jid);
        }
        return null;
    }

    public Jid? get_real_jid(Jid jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_real_jid(jid);
        }
        return null;
    }

    public Xep.Muc.Role? get_role(Jid jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_occupant_role(jid);
        }
        return null;
    }

    public Xep.Muc.Affiliation? get_affiliation(Jid muc_jid, Jid jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_affiliation(muc_jid, jid);
        }
        return null;
    }

    public Gee.List<Jid>? get_offline_members(Jid jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            return flag.get_offline_members(jid);
        }
        return null;
    }

     public Gee.List<Jid>? get_other_offline_members(Jid jid, Account account) {
        Gee.List<Jid>? occupants = get_offline_members(jid, account);
        if (occupants != null) {
            occupants.remove(account.bare_jid);
        }
        return occupants;
    }

    public Jid? get_own_jid(Jid muc_jid, Account account) {
        Xep.Muc.Flag? flag = get_muc_flag(account);
        if (flag != null) {
            string? nick  = flag.get_muc_nick(muc_jid);
            if (nick != null) return muc_jid.with_resource(nick);
        }
        return null;
    }

    private Xep.Muc.Flag? get_muc_flag(Account account) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            return stream.get_flag(Xep.Muc.Flag.IDENTITY);
        }
        return null;
    }

    public bool is_joined(Jid jid, Account account) {
        return get_own_jid(jid, account) != null;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_entered.connect( (stream, jid, nick) => {
            on_room_entred(account, stream, jid, nick);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_enter_error.connect( (stream, jid, error) => {
            enter_errors[jid] = error;
            enter_error(account, jid, error);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).self_removed_from_room.connect( (stream, jid, code) => {
            left(account, jid);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).subject_set.connect( (stream, subject, jid) => {
            subject_set(account, jid, subject);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_name_set.connect( (stream, jid, room_name) => {
            room_name_set(account, jid, room_name);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).received_occupant_jid.connect( (stream, room, occupant) => {
            if (is_private_room(account, room.bare_jid)) {
                private_room_occupant_updated(account, room, occupant);
            }
        });
        stream_interactor.module_manager.get_module(account, Xep.Bookmarks.Module.IDENTITY).received_conferences.connect( (stream, conferences) => {
            sync_autojoin_active(account, conferences);
            bookmarks_updated(account, conferences);
        });
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            if (conferences == null) {
                join_all_active(account);
            } else {
                foreach (Xep.Bookmarks.Conference bookmark in conferences) {
                    if (bookmark.autojoin) {
                        join(account, bookmark.jid, bookmark.nick, bookmark.password);
                    }
                }
            }
        });
    }

    private void on_room_entred(Account account, XmppStream stream, Jid jid, string nick) {
        enter_errors.unset(jid);
        set_autojoin(stream, jid, nick, null); // TODO password
        joined(account, jid, nick);
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_unsent_messages(account, jid);
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.GROUPCHAT);
        stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation);
        conversation.nickname = nick;
    }

    private void join_all_active(Account account) {
        Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations(account);
        foreach (Conversation conversation in conversations) {
            if (conversation.type_ == Conversation.Type.GROUPCHAT && conversation.nickname != null) {
                join(account, conversation.counterpart, conversation.nickname, null);
            }
        }
    }

    private void sync_autojoin_active(Account account, Gee.List<Xep.Bookmarks.Conference> conferences) {
        Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations(account);
        leave_non_autojoin(account, conferences, conversations);
        join_autojoin(account, conferences, conversations);
    }

    private void leave_non_autojoin(Account account, Gee.List<Xep.Bookmarks.Conference> conferences, Gee.List<Conversation> conversations) {
        foreach (Conversation conversation in conversations) {
            if (conversation.type_ != Conversation.Type.GROUPCHAT || !conversation.account.equals(account)) continue;
            bool is_autojoin = false;
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid.equals(conversation.counterpart)) {
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
                if (conference.jid.equals(conversation.counterpart)) is_active = true;
            }
            if (!is_active) {
                join(account, conference.jid, conference.nick, conference.password);
            }
        }
    }

    private void set_autojoin(XmppStream stream, Jid jid, string? nick, string? password) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            if (conferences == null) return;
            Xep.Bookmarks.Conference changed = new Xep.Bookmarks.Conference(jid) { nick=nick, password=password, autojoin=true };
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid.equals_bare(jid) && conference.nick == nick && conference.password == password) {
                    if (!conference.autojoin) {
                        conference.autojoin = true;
                        stream.get_module(Xep.Bookmarks.Module.IDENTITY).set_conferences(stream, conferences);
                    }
                    return;
                }
            }
            stream.get_module(Xep.Bookmarks.Module.IDENTITY).add_conference(stream, changed);
        });
    }

    private void unset_autojoin(XmppStream stream, Jid jid) {
        stream.get_module(Xep.Bookmarks.Module.IDENTITY).get_conferences(stream, (stream, conferences) => {
            if (conferences == null) return;
            foreach (Xep.Bookmarks.Conference conference in conferences) {
                if (conference.jid.equals_bare(jid)) {
                    if (conference.autojoin) {
                        conference.autojoin = false;
                        stream.get_module(Xep.Bookmarks.Module.IDENTITY).set_conferences(stream, conferences);
                        return;
                    }
                }
            }
        });
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "MUC"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (conversation.type_ != Conversation.Type.GROUPCHAT) return false;
            XmppStream stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) return false;
            if (Xep.DelayedDelivery.MessageFlag.get_flag(stanza) == null) {
                Jid? real_jid = stream.get_flag(Xep.Muc.Flag.IDENTITY).get_real_jid(message.counterpart);
                if (real_jid != null && !real_jid.equals(message.counterpart)) {
                    message.real_jid = real_jid.bare_jid;
                }
            }
            Jid? own_muc_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(message.counterpart.bare_jid, conversation.account);
            if (stanza.id != null && own_muc_jid != null && message.from.equals(own_muc_jid)) {
                Entities.Message? m = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_stanza_id(stanza.id, conversation);
                if (m != null) {
                    // For own messages from this device (msg is a duplicate)
                    m.marked = Message.Marked.RECEIVED;
                }
                // For own messages from other devices (msg is not a duplicate msg)
                message.marked = Message.Marked.RECEIVED;
            }

            return false;
        }
    }
}

}
