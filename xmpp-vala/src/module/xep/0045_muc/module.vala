using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Muc {

private const string NS_URI = "http://jabber.org/protocol/muc";
private const string NS_URI_ADMIN = NS_URI + "#admin";
private const string NS_URI_USER = NS_URI + "#user";

public const string AFFILIATION_ADMIN = "admin";
public const string AFFILIATION_MEMBER = "member";
public const string AFFILIATION_NONE = "none";
public const string AFFILIATION_OUTCAST = "outcast";
public const string AFFILIATION_OWNER = "owner";

public const string ROLE_MODERATOR = "moderator";
public const string ROLE_NONE = "none";
public const string ROLE_PARTICIPANT = "participant";
public const string ROLE_VISITOR = "visitor";

public enum MucEnterError {
    PASSWORD_REQUIRED,
    NOT_IN_MEMBER_LIST,
    BANNED,
    NICK_CONFLICT,
    OCCUPANT_LIMIT_REACHED,
    ROOM_DOESNT_EXIST
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0045_muc_module");

    public signal void received_occupant_affiliation(XmppStream stream, string jid, string? affiliation);
    public signal void received_occupant_jid(XmppStream stream, string jid, string? real_jid);
    public signal void received_occupant_role(XmppStream stream, string jid, string? role);
    public signal void subject_set(XmppStream stream, string subject, string jid);
    public signal void room_configuration_changed(XmppStream stream, string jid, StatusCode code);

    public signal void room_entered(XmppStream stream, string jid, string nick);
    public signal void room_enter_error(XmppStream stream, string jid, MucEnterError error);
    public signal void self_removed_from_room(XmppStream stream, string jid, StatusCode code);
    public signal void removed_from_room(XmppStream stream, string jid, StatusCode? code);

    public void enter(XmppStream stream, string bare_jid, string nick, string? password) {
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = bare_jid + "/" + nick;
        StanzaNode x_node = new StanzaNode.build("x", NS_URI).add_self_xmlns();
        if (password != null) {
            x_node.put_node(new StanzaNode.build("password", NS_URI).put_node(new StanzaNode.text(password)));
        }
        presence.stanza.put_node(x_node);

        stream.get_flag(Flag.IDENTITY).start_muc_enter(bare_jid, presence.id);
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void exit(XmppStream stream, string jid) {
        string nick = stream.get_flag(Flag.IDENTITY).get_muc_nick(jid);
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = jid + "/" + nick;
        presence.type_ = Presence.Stanza.TYPE_UNAVAILABLE;
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void change_subject(XmppStream stream, string jid, string subject) {
        Message.Stanza message = new Message.Stanza();
        message.to = jid;
        message.type_ = Message.Stanza.TYPE_GROUPCHAT;
        message.stanza.put_node((new StanzaNode.build("subject")).put_node(new StanzaNode.text(subject)));
        stream.get_module(Message.Module.IDENTITY).send_message(stream, message);
    }

    public void change_nick(XmppStream stream, string jid, string new_nick) {
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = jid + "/" + new_nick;
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void kick(XmppStream stream, string jid, string nick) {
        change_role(stream, jid, nick, "none");
    }

    public override void attach(XmppStream stream) {
        stream.add_flag(new Muc.Flag());
        Message.Module.require(stream);
        stream.get_module(Message.Module.IDENTITY).received_message.connect(on_received_message);
        Presence.Module.require(stream);
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
        stream.get_module(Presence.Module.IDENTITY).received_available.connect(on_received_available);
        stream.get_module(Presence.Module.IDENTITY).received_unavailable.connect(on_received_unavailable);
        if (stream.get_module(ServiceDiscovery.Module.IDENTITY) != null) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Message.Module.IDENTITY).received_message.disconnect(on_received_message);
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
        stream.get_module(Presence.Module.IDENTITY).received_available.disconnect(on_received_available);
        stream.get_module(Presence.Module.IDENTITY).received_unavailable.disconnect(on_received_unavailable);
    }

    public static void require(XmppStream stream) {
        Presence.Module.require(stream);
        if (stream.get_module(IDENTITY) == null) stream.add_module(new Muc.Module());
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void change_role(XmppStream stream, string jid, string nick, string new_role) {
        StanzaNode query = new StanzaNode.build("query", NS_URI_ADMIN).add_self_xmlns();
        query.put_node(new StanzaNode.build("item", NS_URI_ADMIN).put_attribute("nick", nick, NS_URI_ADMIN).put_attribute("role", new_role, NS_URI_ADMIN));
        Iq.Stanza iq = new Iq.Stanza.set(query);
        iq.to = jid;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    private void on_received_message(XmppStream stream, Message.Stanza message) {
        if (message.type_ == Message.Stanza.TYPE_GROUPCHAT) {
            StanzaNode? subject_node = message.stanza.get_subnode("subject");
            if (subject_node != null) {
                string subject = subject_node.get_string_content();
                stream.get_flag(Flag.IDENTITY).set_muc_subject(message.from, subject);
                subject_set(stream, subject, message.from);
            }
        }
    }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        if (presence.is_error() && flag.is_muc_enter_outstanding() && flag.is_occupant(presence.from)) {
            string bare_jid = get_bare_jid(presence.from);
            ErrorStanza? error_stanza = presence.get_error();
            if (flag.get_enter_id(bare_jid) == error_stanza.original_id) {
                MucEnterError? error = null;
                if (error_stanza.condition == ErrorStanza.CONDITION_NOT_AUTHORIZED && ErrorStanza.TYPE_AUTH == error_stanza.type_) {
                    error = MucEnterError.PASSWORD_REQUIRED;
                } else if (ErrorStanza.CONDITION_REGISTRATION_REQUIRED == error_stanza.condition && ErrorStanza.TYPE_AUTH == error_stanza.type_) {
                    error = MucEnterError.NOT_IN_MEMBER_LIST;
                } else if (ErrorStanza.CONDITION_FORBIDDEN == error_stanza.condition && ErrorStanza.TYPE_AUTH == error_stanza.type_) {
                    error = MucEnterError.BANNED;
                } else if (ErrorStanza.CONDITION_CONFLICT == error_stanza.condition && ErrorStanza.TYPE_CANCEL == error_stanza.type_) {
                    error = MucEnterError.NICK_CONFLICT;
                } else if (ErrorStanza.CONDITION_SERVICE_UNAVAILABLE == error_stanza.condition && ErrorStanza.TYPE_WAIT == error_stanza.type_) {
                    error = MucEnterError.OCCUPANT_LIMIT_REACHED;
                } else if (ErrorStanza.CONDITION_ITEM_NOT_FOUND == error_stanza.condition && ErrorStanza.TYPE_CANCEL == error_stanza.type_) {
                    error = MucEnterError.ROOM_DOESNT_EXIST;
                }
                if (error != null) room_enter_error(stream, bare_jid, error);
                flag.finish_muc_enter(bare_jid);
            }
        }
    }

    private void on_received_available(XmppStream stream, Presence.Stanza presence) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        if (flag.is_occupant(presence.from)) {
            StanzaNode? x_node = presence.stanza.get_subnode("x", NS_URI_USER);
            if (x_node != null) {
                ArrayList<int> status_codes = get_status_codes(x_node);
                if (status_codes.contains(StatusCode.SELF_PRESENCE)) {
                    string bare_jid = get_bare_jid(presence.from);
                    if (flag.get_enter_id(bare_jid) != null) {
                        room_entered(stream, bare_jid, get_resource_part(presence.from));
                        flag.finish_muc_enter(bare_jid, get_resource_part(presence.from));
                    }
                }
                string? affiliation = x_node.get_deep_attribute("item", "affiliation");
                if (affiliation != null) {
                    received_occupant_affiliation(stream, presence.from, affiliation);
                }
                string? jid = x_node.get_deep_attribute("item", "jid");
                if (jid != null) {
                    flag.set_real_jid(presence.from, jid);
                    received_occupant_jid(stream, presence.from, jid);
                }
                string? role = x_node.get_deep_attribute("item", "role");
                if (role != null) {
                    received_occupant_role(stream, presence.from, role);
                }
            }
        }
    }

    private void on_received_unavailable(XmppStream stream, Presence.Stanza presence) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        if (!flag.is_occupant(presence.from)) return;

        StanzaNode? x_node = presence.stanza.get_subnode("x", NS_URI_USER);
        if (x_node == null) return;

        ArrayList<int> status_codes = get_status_codes(x_node);

        if (StatusCode.SELF_PRESENCE in status_codes) {
            flag.remove_occupant_info(presence.from);
        }

        foreach (StatusCode code in USER_REMOVED_CODES) {
            if (code in status_codes) {
                if (StatusCode.SELF_PRESENCE in status_codes) {
                    flag.left_muc(stream, get_bare_jid(presence.from));
                    self_removed_from_room(stream, presence.from, code);
                    Presence.Flag presence_flag = stream.get_flag(Presence.Flag.IDENTITY);
                    presence_flag.remove_presence(get_bare_jid(presence.from));
                } else {
                    removed_from_room(stream, presence.from, code);
                }
            }
        }
    }

    private ArrayList<int> get_status_codes(StanzaNode x_node) {
        ArrayList<int> ret = new ArrayList<int>();
        foreach (StanzaNode status_node in x_node.get_subnodes("status", NS_URI_USER)) {
            ret.add(int.parse(status_node.get_attribute("code")));
        }
        return ret;
    }
}

}
