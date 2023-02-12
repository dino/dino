using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {
    public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation, string? muc_pm_format) {
        if (conversation.type_ == Conversation.Type.CHAT) {
            string? display_name = get_real_display_name(stream_interactor, conversation.account, conversation.counterpart);
            if (display_name != null) return display_name;
            return conversation.counterpart.to_string();
        }
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            return get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart);
        }
        if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
            return (muc_pm_format ?? "%s / %s").printf(get_occupant_display_name(stream_interactor, conversation, conversation.counterpart), get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart.bare_jid));
        }
        return conversation.counterpart.to_string();
    }

    public static string get_participant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid participant, string? self_word = null) {
        if (conversation.type_ == Conversation.Type.CHAT) {
            return get_real_display_name(stream_interactor, conversation.account, participant, self_word) ?? participant.bare_jid.to_string();
        }
        if ((conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM)) {
            return get_occupant_display_name(stream_interactor, conversation, participant);
        }
        return participant.bare_jid.to_string();
    }

    public static string? get_real_display_name(StreamInteractor stream_interactor, Account account, Jid jid, string? self_word = null) {
        if (jid.equals_bare(account.bare_jid)) {
            if (self_word != null && (account.alias == null || account.alias.length == 0)) {
                return self_word;
            }
            return account.alias;
        }
        Roster.Item roster_item = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, jid);
        if (roster_item != null && roster_item.name != null && roster_item.name != "") {
            return roster_item.name;
        }
        return null;
    }

    public static string get_groupchat_display_name(StreamInteractor stream_interactor, Account account, Jid jid) {
        MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
        string? room_name = muc_manager.get_room_name(account, jid);
        if (room_name != null && room_name != jid.localpart) {
            return room_name;
        }
        if (muc_manager.is_private_room(account, jid)) {
            Gee.List<Jid>? other_occupants = muc_manager.get_other_offline_members(jid, account);
            if (other_occupants != null && other_occupants.size > 0) {
                var builder = new StringBuilder ();
                foreach(Jid occupant in other_occupants) {
                    if (builder.len != 0) {
                        builder.append(", ");
                    }
                    builder.append((get_real_display_name(stream_interactor, account, occupant) ?? occupant.localpart ?? occupant.domainpart).split(" ")[0]);
                }
                return builder.str;
            }
        }
        return jid.to_string();
    }

    public static string get_occupant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid jid, string? self_word = null, bool muc_real_name = false) {
        if (muc_real_name) {
            MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
            if (muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
                Jid? real_jid = null;
                if (jid.equals_bare(conversation.counterpart)) {
                    muc_manager.get_real_jid(jid, conversation.account);
                } else {
                    real_jid = jid;
                }
                if (real_jid != null) {
                    string? display_name = get_real_display_name(stream_interactor, conversation.account, real_jid, self_word);
                    if (display_name != null) return display_name;
                }
            }
        }

        // If it's us (jid=our real full JID), display our nick
        if (conversation.type_ == Conversation.Type.GROUPCHAT_PM && conversation.account.bare_jid.equals_bare(jid)) {
            var muc_conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(conversation.counterpart.bare_jid, conversation.account, Conversation.Type.GROUPCHAT);
            if (muc_conv != null && muc_conv.nickname != null) {
                return muc_conv.nickname;
            }
        }

        // If it's someone else's real jid, recover nickname
        if (!jid.equals_bare(conversation.counterpart)) {
            MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
            Jid? occupant_jid = muc_manager.get_occupant_jid(conversation.account, conversation.counterpart.bare_jid, jid);
            if (occupant_jid != null && occupant_jid.resourcepart != null) {
                return occupant_jid.resourcepart;
            }
        }

        return jid.resourcepart ?? jid.to_string();
    }
}