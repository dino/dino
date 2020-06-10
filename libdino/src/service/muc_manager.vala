using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

namespace Dino {
public class MucManager : StreamInteractionModule, Object {
    public static ModuleIdentity<MucManager> IDENTITY = new ModuleIdentity<MucManager>("muc_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void left(Account account, Jid jid);
    public signal void subject_set(Account account, Jid jid, string? subject);
    public signal void room_info_updated(Account account, Jid muc_jid);
    public signal void private_room_occupant_updated(Account account, Jid room, Jid occupant);
    public signal void invite_received(Account account, Jid room_jid, Jid from_jid, string? password, string? reason);
    public signal void voice_request_received(Account account, Jid room_jid, Jid from_jid, string? nick, string? role, string? label);
    public signal void received_occupant_role(Account account, Jid jid, Xep.Muc.Role? role);
    public signal void bookmarks_updated(Account account, Set<Conference> conferences);
    public signal void conference_added(Account account, Conference conference);
    public signal void conference_removed(Account account, Jid jid);

    private StreamInteractor stream_interactor;
    private HashMap<Account, Gee.List<Jid>> mucs_joining = new HashMap<Account, ArrayList<Jid>>(Account.hash_func, Account.equals_func);
    private HashMap<Jid, Xep.Muc.MucEnterError> enter_errors = new HashMap<Jid, Xep.Muc.MucEnterError>(Jid.hash_func, Jid.equals_func);
    private ReceivedMessageListener received_message_listener;
    private HashMap<Account, BookmarksProvider> bookmarks_provider = new HashMap<Account, BookmarksProvider>(Account.hash_func, Account.equals_func);

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
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect((conversation) => {
            if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                part(conversation.account, conversation.counterpart);
            }
        });
    }

    public async Muc.JoinResult? join(Account account, Jid jid, string? nick, string? password) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return null;

        string nick_ = (nick ?? account.localpart) ?? account.domainpart;

        DateTime? history_since = null;
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) {
            Entities.Message? last_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
            if (last_message != null) history_since = last_message.time;
        }

        if (!mucs_joining.has_key(account)) {
            mucs_joining[account] = new ArrayList<Jid>();
        }
        mucs_joining[account].add(jid);

        Muc.JoinResult? res = yield stream.get_module(Xep.Muc.Module.IDENTITY).enter(stream, jid.bare_jid, nick_, password, history_since);

        mucs_joining[account].remove(jid);

        if (res.nick != null) {
            // Join completed
            enter_errors.unset(jid);
            set_autojoin(account, stream, jid, nick, password);
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_unsent_muc_messages(account, jid);

            Conversation joined_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.GROUPCHAT);
            joined_conversation.nickname = nick;
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(joined_conversation);
        } else if (res.muc_error != null) {
            // Join failed
            enter_errors[jid] = res.muc_error;
        }

        return res;
    }

    public void part(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        unset_autojoin(account, stream, jid);
        stream.get_module(Xep.Muc.Module.IDENTITY).exit(stream, jid.bare_jid);

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
    }

    public async DataForms.DataForm? get_config_form(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return null;
        return yield stream.get_module(Xep.Muc.Module.IDENTITY).get_config_form(stream, jid);
    }

    public void set_config_form(Account account, Jid jid, DataForms.DataForm data_form) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        stream.get_module(Xep.Muc.Module.IDENTITY).set_config_form(stream, jid, data_form);
    }

    public void change_subject(Account account, Jid jid, string subject) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_subject(stream, jid.bare_jid, subject);
    }

    public async void change_nick(Conversation conversation, string new_nick) {
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return;

        // Check if this would be a valid nick
        try {
            conversation.counterpart.with_resource(new_nick);
        } catch (InvalidJidError error) { return; }

        stream.get_module(Xep.Muc.Module.IDENTITY).change_nick(stream, conversation.counterpart, new_nick);

        conversation.nickname = new_nick;

        // Update nick in bookmark
        Set<Conference>? conferences = yield bookmarks_provider[conversation.account].get_conferences(stream);
        if (conferences == null) return;
        foreach (Conference conference in conferences) {
            if (conference.jid.equals(conversation.counterpart)) {
                Conference new_conference = new Conference() { jid=conversation.counterpart, nick=new_nick, name=conference.name, password=conference.password, autojoin=conference.autojoin };
                bookmarks_provider[conversation.account].replace_conference.begin(stream, conversation.counterpart, new_conference);
                break;
            }
        }
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

    public void change_role(Account account, Jid jid, string nick, string role) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).change_role(stream, jid.bare_jid, nick, role);
    }

    public void request_voice(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xep.Muc.Module.IDENTITY).request_voice(stream, jid.bare_jid);
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

    public bool is_moderated_room(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return false;
        }
        Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
        if (flag == null) {
            return false;
        }
        return flag.has_room_feature(jid, Xep.Muc.Feature.MODERATED);
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
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account, Conversation.Type.GROUPCHAT);
        return !jid.is_full() && conversation != null;
    }

    public bool might_be_groupchat(Jid jid, Account account) {
        if (mucs_joining.has_key(account) && mucs_joining[account].contains(jid)) return true;
        return is_groupchat(jid, account);
    }

    public bool is_groupchat_occupant(Jid jid, Account account) {
        return is_groupchat(jid.bare_jid, account) && jid.resourcepart != null;
    }

    public async Set<Conference>? get_bookmarks(Account account) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return null;

        return yield bookmarks_provider[account].get_conferences(stream);
    }

    public void add_bookmark(Account account, Conference conference) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            bookmarks_provider[account].add_conference.begin(stream, conference);
        }
    }

    public void remove_bookmark(Account account, Conference conference) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            bookmarks_provider[account].remove_conference.begin(stream, conference);
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
        try {
            Xep.Muc.Flag? flag = get_muc_flag(account);
            if (flag != null) {
                string? nick  = flag.get_muc_nick(muc_jid);
                if (nick != null) return muc_jid.with_resource(nick);
            }
        } catch (InvalidJidError e) {
            warning("Joined MUC with invalid Jid: %s", e.message);
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
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).self_removed_from_room.connect( (stream, jid, code) => {
            left(account, jid);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).subject_set.connect( (stream, subject, jid) => {
            subject_set(account, jid, subject);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).invite_received.connect( (stream, room_jid, from_jid, password, reason) => {
            invite_received(account, room_jid, from_jid, password, reason);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).voice_request_received.connect( (stream, room_jid, from_jid, nick, role, label) => {
            voice_request_received(account, room_jid, from_jid, nick, role, label);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).received_occupant_role.connect( (stream, from_jid, role) => {
            received_occupant_role(account, from_jid, role);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).room_info_updated.connect( (stream, muc_jid) => {
            room_info_updated(account, muc_jid);
        });
        stream_interactor.module_manager.get_module(account, Xep.Muc.Module.IDENTITY).received_occupant_jid.connect( (stream, room, occupant) => {
            if (is_private_room(account, room.bare_jid)) {
                private_room_occupant_updated(account, room, occupant);
            }
        });

        bookmarks_provider[account] = stream_interactor.module_manager.get_module(account, Xep.Bookmarks.Module.IDENTITY);

        bookmarks_provider[account].received_conferences.connect( (stream, conferences) => {
            sync_autojoin_active(account, conferences);
            bookmarks_updated(account, conferences);
        });
        bookmarks_provider[account].conference_added.connect( (stream, conference) => {
            // TODO join (for Bookmarks2)
            conference_added(account, conference);
        });
        bookmarks_provider[account].conference_removed.connect( (stream, jid) => {
            // TODO part (for Bookmarks2)
            conference_removed(account, jid);
        });
    }

    private async void on_stream_negotiated(Account account, XmppStream stream) {
        if (bookmarks_provider[account] == null) return;

        Set<Conference>? conferences = yield bookmarks_provider[account].get_conferences(stream);

        if (conferences == null) {
            join_all_active(account);
        } else {
            sync_autojoin_active(account, conferences);
        }
    }

    private void join_all_active(Account account) {
        Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations(account);
        foreach (Conversation conversation in conversations) {
            if (conversation.type_ == Conversation.Type.GROUPCHAT && conversation.nickname != null) {
                join.begin(account, conversation.counterpart, conversation.nickname, null);
            }
        }
    }

    private void sync_autojoin_active(Account account, Set<Conference> conferences) {
        Gee.List<Conversation> active_conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations(account);

        // Join auto-join MUCs
        foreach (Conference conference in conferences) {
            if (!conference.autojoin) continue;

            bool is_active = false;
            foreach (Conversation conversation in active_conversations) {
                if (conference.jid.equals(conversation.counterpart)) {
                    is_active = true;
                }
            }
            if (!is_active || !is_joined(conference.jid, account)) {
                join.begin(account, conference.jid, conference.nick, conference.password);
            }
        }

        // Part MUCs that aren't auto-join (which closes those conversations)
        foreach (Conversation conversation in active_conversations) {
            if (conversation.type_ != Conversation.Type.GROUPCHAT) continue;

            bool should_be_active = false;
            foreach (Conference conference in conferences) {
                if (conference.jid.equals(conversation.counterpart) && conference.autojoin) {
                    should_be_active = true;
                }
            }
            if (!should_be_active) {
                part(conversation.account, conversation.counterpart);
            }
        }
    }

    private void set_autojoin(Account account, XmppStream stream, Jid jid, string? nick, string? password) {
        bookmarks_provider[account].get_conferences.begin(stream, (_, res) => {
            Set<Conference>? conferences = bookmarks_provider[account].get_conferences.end(res);
            if (conferences == null) return;

            foreach (Conference conference in conferences) {
                if (conference.jid.equals(jid)) {
                    if (!conference.autojoin) {
                        Conference new_conference = new Conference() { jid=jid, nick=nick ?? conference.nick, name=conference.name, password=password ?? conference.password, autojoin=true };
                        bookmarks_provider[account].replace_conference.begin(stream, jid, new_conference);
                    }
                    return;
                }
            }
            Conference changed = new Xep.Bookmarks.Bookmarks1Conference(jid) { nick=nick, password=password, autojoin=true };
            bookmarks_provider[account].add_conference.begin(stream, changed);
        });
    }

    private void unset_autojoin(Account account, XmppStream stream, Jid jid) {
        bookmarks_provider[account].get_conferences.begin(stream, (_, res) => {
            Set<Conference>? conferences = bookmarks_provider[account].get_conferences.end(res);
            if (conferences == null) return;

            foreach (Conference conference in conferences) {
                if (conference.jid.equals(jid)) {
                    if (conference.autojoin) {
                        Conference new_conference = new Conference() { jid=jid, nick=conference.nick, name=conference.name, password=conference.password, autojoin=false };
                        bookmarks_provider[account].replace_conference.begin(stream, jid, new_conference);
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
