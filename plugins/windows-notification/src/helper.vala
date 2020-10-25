using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.Util {

private static Jid get_relevant_jid(StreamInteractor stream_interactor, Account account, Jid jid, Conversation? conversation = null) {
    Conversation conversation_ = conversation ?? stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid.bare_jid, account);
    if (conversation_ != null && conversation_.type_ == Conversation.Type.GROUPCHAT) {
        Jid? real_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(jid, account);
        if (real_jid != null) {
            return real_jid.bare_jid;
        }
    } else {
        return jid.bare_jid;
    }
    return jid;
}

public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation) {
    if (conversation.type_ == Conversation.Type.CHAT) {
        string? display_name = get_real_display_name(stream_interactor, conversation.account, conversation.counterpart);
        if (display_name != null) return display_name;
        return conversation.counterpart.to_string();
    }
    if (conversation.type_ == Conversation.Type.GROUPCHAT) {
        return get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart);
    }
    if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
        return "%s from %s".printf(get_occupant_display_name(stream_interactor, conversation, conversation.counterpart), get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart.bare_jid));
    }
    return conversation.counterpart.to_string();
}

public static string get_participant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid participant, bool me_is_me = false) {
    if (me_is_me) {
        if (conversation.account.bare_jid.equals_bare(participant) ||
                (conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM) &&
                        conversation.nickname != null && participant.equals_bare(conversation.counterpart) && conversation.nickname == participant.resourcepart) {
            return "Me";
        }
    }
    if (conversation.type_ == Conversation.Type.CHAT) {
        return get_real_display_name(stream_interactor, conversation.account, participant, me_is_me) ?? participant.bare_jid.to_string();
    }
    if ((conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM) && conversation.counterpart.equals_bare(participant)) {
        return get_occupant_display_name(stream_interactor, conversation, participant);
    }
    return participant.bare_jid.to_string();
}

private static string? get_real_display_name(StreamInteractor stream_interactor, Account account, Jid jid, bool me_is_me = false) {
    if (jid.equals_bare(account.bare_jid)) {
        if (me_is_me || account.alias == null || account.alias.length == 0) {
            return "Me";
        }
        return account.alias;
    }
    Roster.Item roster_item = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, jid);
    if (roster_item != null && roster_item.name != null && roster_item.name != "") {
        return roster_item.name;
    }
    return null;
}

private static string get_groupchat_display_name(StreamInteractor stream_interactor, Account account, Jid jid) {
    MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
    string room_name = muc_manager.get_room_name(account, jid);
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

private static string get_occupant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid jid, bool me_is_me = false, bool muc_real_name = false) {
    if (muc_real_name) {
        MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
        if (muc_manager.is_private_room(conversation.account, jid.bare_jid)) {
            Jid? real_jid = muc_manager.get_real_jid(jid, conversation.account);
            if (real_jid != null) {
                string? display_name = get_real_display_name(stream_interactor, conversation.account, real_jid, me_is_me);
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

    return jid.resourcepart ?? jid.to_string();
}

}
