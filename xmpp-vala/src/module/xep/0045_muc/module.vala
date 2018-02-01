using Gee;

namespace Xmpp.Xep.Muc {

private const string NS_URI = "http://jabber.org/protocol/muc";
private const string NS_URI_ADMIN = NS_URI + "#admin";
private const string NS_URI_OWNER = NS_URI + "#owner";
private const string NS_URI_USER = NS_URI + "#user";

public enum MucEnterError {
    NONE,
    PASSWORD_REQUIRED,
    BANNED,
    ROOM_DOESNT_EXIST,
    CREATION_RESTRICTED,
    USE_RESERVED_ROOMNICK,
    NOT_IN_MEMBER_LIST,
    NICK_CONFLICT,
    OCCUPANT_LIMIT_REACHED,
}

public enum Affiliation {
    NONE,
    ADMIN,
    MEMBER,
    OUTCAST,
    OWNER
}

public enum Role {
    NONE,
    MODERATOR,
    PARTICIPANT,
    VISITOR
}

public enum Feature {
    REGISTER,
    ROOMCONFIG,
    ROOMINFO,
    HIDDEN,
    MEMBERS_ONLY,
    MODERATED,
    NON_ANONYMOUS,
    OPEN,
    PASSWORD_PROTECTED,
    PERSISTENT,
    PUBLIC,
    ROOMS,
    SEMI_ANONYMOUS,
    TEMPORARY,
    UNMODERATED,
    UNSECURED
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0045_muc_module");

    public signal void received_occupant_affiliation(XmppStream stream, Jid jid, Affiliation? affiliation);
    public signal void received_occupant_jid(XmppStream stream, Jid jid, Jid? real_jid);
    public signal void received_occupant_role(XmppStream stream, Jid jid, Role? role);
    public signal void subject_set(XmppStream stream, string? subject, Jid jid);
    public signal void room_configuration_changed(XmppStream stream, Jid jid, StatusCode code);

    public signal void room_entered(XmppStream stream, Jid jid, string nick);
    public signal void room_enter_error(XmppStream stream, Jid jid, MucEnterError? error); // TODO "?" shoudln't be necessary (vala bug), remove someday
    public signal void self_removed_from_room(XmppStream stream, Jid jid, StatusCode code);
    public signal void removed_from_room(XmppStream stream, Jid jid, StatusCode? code);

    public void enter(XmppStream stream, Jid bare_jid, string nick, string? password, DateTime? history_since) {
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = bare_jid.with_resource(nick);
        StanzaNode x_node = new StanzaNode.build("x", NS_URI).add_self_xmlns();
        if (password != null) {
            x_node.put_node(new StanzaNode.build("password", NS_URI).put_node(new StanzaNode.text(password)));
        }
        if (history_since != null) {
            StanzaNode history_node = new StanzaNode.build("history", NS_URI);
            history_node.set_attribute("since", DateTimeProfiles.to_datetime(history_since));
            x_node.put_node(history_node);
        }
        presence.stanza.put_node(x_node);

        stream.get_flag(Flag.IDENTITY).start_muc_enter(bare_jid, presence.id);

        query_room_info(stream, bare_jid);
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void exit(XmppStream stream, Jid jid) {
        string nick = stream.get_flag(Flag.IDENTITY).get_muc_nick(jid);
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = jid.with_resource(nick);
        presence.type_ = Presence.Stanza.TYPE_UNAVAILABLE;
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void change_subject(XmppStream stream, Jid jid, string subject) {
        MessageStanza message = new MessageStanza();
        message.to = jid;
        message.type_ = MessageStanza.TYPE_GROUPCHAT;
        message.stanza.put_node((new StanzaNode.build("subject")).put_node(new StanzaNode.text(subject)));
        stream.get_module(MessageModule.IDENTITY).send_message(stream, message);
    }

    public void change_nick(XmppStream stream, Jid jid, string new_nick) {
        Presence.Stanza presence = new Presence.Stanza();
        presence.to = jid.with_resource(new_nick);
        stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
    }

    public void invite(XmppStream stream, Jid to_muc, Jid jid) {
        MessageStanza message = new MessageStanza();
        message.to = to_muc;
        StanzaNode invite_node = new StanzaNode.build("x", NS_URI_USER).add_self_xmlns()
            .put_node(new StanzaNode.build("invite", NS_URI_USER).put_attribute("to", jid.to_string()));
        message.stanza.put_node(invite_node);
        stream.get_module(MessageModule.IDENTITY).send_message(stream, message);
    }

    public void kick(XmppStream stream, Jid jid, string nick) {
        change_role(stream, jid, nick, "none");
    }

    /* XEP 0046: "A user cannot be kicked by a moderator with a lower affiliation." (XEP 0045 8.2) */
    public bool kick_possible(XmppStream stream, Jid occupant) {
        Jid muc_jid = occupant.bare_jid;
        Flag flag = stream.get_flag(Flag.IDENTITY);
        string own_nick = flag.get_muc_nick(muc_jid);
        Affiliation my_affiliation = flag.get_affiliation(muc_jid, muc_jid.with_resource(own_nick));
        Affiliation other_affiliation = flag.get_affiliation(muc_jid, occupant);
        switch (my_affiliation) {
            case Affiliation.MEMBER:
                if (other_affiliation == Affiliation.ADMIN || other_affiliation == Affiliation.OWNER) return false;
                break;
            case Affiliation.ADMIN:
                if (other_affiliation == Affiliation.OWNER) return false;
                break;
        }
        return true;
    }

    public void change_role(XmppStream stream, Jid jid, string nick, string new_role) {
        StanzaNode query = new StanzaNode.build("query", NS_URI_ADMIN).add_self_xmlns();
        query.put_node(new StanzaNode.build("item", NS_URI_ADMIN).put_attribute("nick", nick, NS_URI_ADMIN).put_attribute("role", new_role, NS_URI_ADMIN));
        Iq.Stanza iq = new Iq.Stanza.set(query) { to=jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    public void change_affiliation(XmppStream stream, Jid jid, string nick, string new_affiliation) {
        StanzaNode query = new StanzaNode.build("query", NS_URI_ADMIN).add_self_xmlns();
        query.put_node(new StanzaNode.build("item", NS_URI_ADMIN).put_attribute("nick", nick, NS_URI_ADMIN).put_attribute("affiliation", new_affiliation, NS_URI_ADMIN));
        Iq.Stanza iq = new Iq.Stanza.set(query) { to=jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    public delegate void OnConfigFormResult(XmppStream stream, Jid jid, DataForms.DataForm data_form);
    public void get_config_form(XmppStream stream, Jid jid, owned OnConfigFormResult listener) {
        Iq.Stanza get_iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_OWNER).add_self_xmlns()) { to=jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, get_iq, (stream, form_iq) => {
            StanzaNode? x_node = form_iq.stanza.get_deep_subnode(NS_URI_OWNER + ":query", DataForms.NS_URI + ":x");
            if (x_node != null) {
                DataForms.DataForm data_form = DataForms.DataForm.create_from_node(stream, x_node, (stream, node) => {
                    StanzaNode stanza_node = new StanzaNode.build("query", NS_URI_OWNER);
                    stanza_node.add_self_xmlns().put_node(node);
                    Iq.Stanza set_iq = new Iq.Stanza.set(stanza_node);
                    set_iq.to = form_iq.from;
                    stream.get_module(Iq.Module.IDENTITY).send_iq(stream, set_iq);
                });
                listener(stream, form_iq.from, data_form);
            }
        });
    }

    public override void attach(XmppStream stream) {
        stream.add_flag(new Muc.Flag());
        stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(check_for_enter_error);
        stream.get_module(Presence.Module.IDENTITY).received_available.connect(on_received_available);
        stream.get_module(Presence.Module.IDENTITY).received_unavailable.connect(on_received_unavailable);
        if (stream.get_module(ServiceDiscovery.Module.IDENTITY) != null) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }

        room_entered.connect((stream, jid, nick) => {
            query_affiliation(stream, jid, "member", null);
            query_affiliation(stream, jid, "admin", null);
            query_affiliation(stream, jid, "owner", null);
        });
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(check_for_enter_error);
        stream.get_module(Presence.Module.IDENTITY).received_available.disconnect(on_received_available);
        stream.get_module(Presence.Module.IDENTITY).received_unavailable.disconnect(on_received_unavailable);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_message(XmppStream stream, MessageStanza message) {
        if (message.type_ == MessageStanza.TYPE_GROUPCHAT) {
            StanzaNode? subject_node = message.stanza.get_subnode("subject");
            if (subject_node != null) {
                string subject = subject_node.get_string_content();
                stream.get_flag(Flag.IDENTITY).set_muc_subject(message.from, subject);
                subject_set(stream, subject, message.from);
            }
        }
    }

    private void check_for_enter_error(XmppStream stream, Presence.Stanza presence) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        if (presence.is_error() && flag.is_muc_enter_outstanding() && flag.is_occupant(presence.from)) {
            Jid bare_jid = presence.from.bare_jid;
            ErrorStanza? error_stanza = presence.get_error();
            if (flag.get_enter_id(bare_jid) == presence.id) {
                MucEnterError error = MucEnterError.NONE;
                switch (error_stanza.condition) {
                    case ErrorStanza.CONDITION_NOT_AUTHORIZED:
                        if (ErrorStanza.TYPE_AUTH == error_stanza.type_) error = MucEnterError.PASSWORD_REQUIRED;
                        break;
                    case ErrorStanza.CONDITION_REGISTRATION_REQUIRED:
                        if (ErrorStanza.TYPE_AUTH == error_stanza.type_) error = MucEnterError.NOT_IN_MEMBER_LIST;
                        break;
                    case ErrorStanza.CONDITION_FORBIDDEN:
                        if (ErrorStanza.TYPE_AUTH == error_stanza.type_) error = MucEnterError.BANNED;
                        break;
                    case ErrorStanza.CONDITION_SERVICE_UNAVAILABLE:
                        if (ErrorStanza.TYPE_WAIT == error_stanza.type_) error = MucEnterError.OCCUPANT_LIMIT_REACHED;
                        break;
                    case ErrorStanza.CONDITION_ITEM_NOT_FOUND:
                        if (ErrorStanza.TYPE_CANCEL == error_stanza.type_) error = MucEnterError.ROOM_DOESNT_EXIST;
                        break;
                    case ErrorStanza.CONDITION_CONFLICT:
                        if (ErrorStanza.TYPE_CANCEL == error_stanza.type_) error = MucEnterError.NICK_CONFLICT;
                        break;
                    case ErrorStanza.CONDITION_NOT_ALLOWED:
                        if (ErrorStanza.TYPE_CANCEL == error_stanza.type_) error = MucEnterError.CREATION_RESTRICTED;
                        break;
                    case ErrorStanza.CONDITION_NOT_ACCEPTABLE:
                        if (ErrorStanza.TYPE_CANCEL == error_stanza.type_) error = MucEnterError.USE_RESERVED_ROOMNICK;
                        break;
                }
                if (error != MucEnterError.NONE) room_enter_error(stream, bare_jid, error);
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
                    Jid bare_jid = presence.from.bare_jid;
                    if (flag.get_enter_id(bare_jid) != null) {
                        room_entered(stream, bare_jid, presence.from.resourcepart);
                        flag.finish_muc_enter(bare_jid, presence.from.resourcepart);
                    }
                }
                string? affiliation_str = x_node.get_deep_attribute("item", "affiliation");
                if (affiliation_str != null) {
                    Affiliation affiliation = parse_affiliation(affiliation_str);
                    flag.set_affiliation(presence.from.bare_jid, presence.from, affiliation);
                    received_occupant_affiliation(stream, presence.from, affiliation);
                }
                string? jid_ = x_node.get_deep_attribute("item", "jid");
                if (jid_ != null) {
                    Jid? jid = Jid.parse(jid_);
                    flag.set_real_jid(presence.from, jid);
                    received_occupant_jid(stream, presence.from, jid);
                }
                string? role_str = x_node.get_deep_attribute("item", "role");
                if (role_str != null) {
                    Role role = parse_role(role_str);
                    flag.set_occupant_role(presence.from, role);
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
                    flag.left_muc(stream, presence.from.bare_jid);
                    self_removed_from_room(stream, presence.from, code);
                    Presence.Flag presence_flag = stream.get_flag(Presence.Flag.IDENTITY);
                    presence_flag.remove_presence(presence.from.bare_jid);
                } else {
                    removed_from_room(stream, presence.from, code);
                }
            }
        }
    }

    private void query_room_info(XmppStream stream, Jid jid) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, jid, (stream, query_result) => {

            Gee.List<Feature> features = new ArrayList<Feature>();
            if (query_result != null) {

                foreach (ServiceDiscovery.Identity identity in query_result.identities) {
                    if (identity.category == "conference") {
                        stream.get_flag(Flag.IDENTITY).set_room_name(jid, identity.name);
                    }
                }

                foreach (string feature in query_result.features) {
                    Feature? parsed = null;
                    switch (feature) {
                        case "http://jabber.org/protocol/muc#register": parsed = Feature.REGISTER; break;
                        case "http://jabber.org/protocol/muc#roomconfig": parsed = Feature.ROOMCONFIG; break;
                        case "http://jabber.org/protocol/muc#roominfo": parsed = Feature.ROOMINFO; break;
                        case "muc_hidden": parsed = Feature.HIDDEN; break;
                        case "muc_membersonly": parsed = Feature.MEMBERS_ONLY; break;
                        case "muc_moderated": parsed = Feature.MODERATED; break;
                        case "muc_nonanonymous": parsed = Feature.NON_ANONYMOUS; break;
                        case "muc_open": parsed = Feature.OPEN; break;
                        case "muc_passwordprotected": parsed = Feature.PASSWORD_PROTECTED; break;
                        case "muc_persistent": parsed = Feature.PERSISTENT; break;
                        case "muc_public": parsed = Feature.PUBLIC; break;
                        case "muc_rooms": parsed = Feature.ROOMS; break;
                        case "muc_semianonymous": parsed = Feature.SEMI_ANONYMOUS; break;
                        case "muc_temporary": parsed = Feature.TEMPORARY; break;
                        case "muc_unmoderated": parsed = Feature.UNMODERATED; break;
                        case "muc_unsecured": parsed = Feature.UNSECURED; break;
                    }
                    if (parsed != null) features.add(parsed);
                }
            }
            stream.get_flag(Flag.IDENTITY).set_room_features(jid, features);
        });
    }

    public delegate void OnAffiliationResult(XmppStream stream, Gee.List<Jid> jids);
    private void query_affiliation(XmppStream stream, Jid jid, string affiliation, owned OnAffiliationResult? listener) {
        Iq.Stanza iq = new Iq.Stanza.get(
            new StanzaNode.build("query", NS_URI_ADMIN)
                .add_self_xmlns()
                .put_node(new StanzaNode.build("item", NS_URI_ADMIN)
                    .put_attribute("affiliation", affiliation))
        ) { to=jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            if (iq.is_error()) return;
            StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI_ADMIN);
            if (query_node == null) return;
            Gee.List<StanzaNode> item_nodes = query_node.get_subnodes("item", NS_URI_ADMIN);
            Gee.List<Jid> ret_jids = new ArrayList<Jid>(Jid.equals_func);
            foreach (StanzaNode item in item_nodes) {
                Jid? jid_ = Jid.parse(item.get_attribute("jid"));
                string? affiliation_ = item.get_attribute("affiliation");
                if (jid_ != null && affiliation_ != null) {
                    stream.get_flag(Muc.Flag.IDENTITY).set_offline_member(iq.from, jid_, parse_affiliation(affiliation_));
                    ret_jids.add(jid_);
                }
            }
            if (listener != null) listener(stream, ret_jids);
        });
    }

    private static ArrayList<int> get_status_codes(StanzaNode x_node) {
        ArrayList<int> ret = new ArrayList<int>();
        foreach (StanzaNode status_node in x_node.get_subnodes("status", NS_URI_USER)) {
            ret.add(int.parse(status_node.get_attribute("code")));
        }
        return ret;
    }

    private static Affiliation parse_affiliation(string affiliation_str) {
        Affiliation affiliation;
        switch (affiliation_str) {
            case "admin":
                affiliation = Affiliation.ADMIN; break;
            case "member":
                affiliation = Affiliation.MEMBER; break;
            case "outcast":
                affiliation = Affiliation.OUTCAST; break;
            case "owner":
                affiliation = Affiliation.OWNER; break;
            default:
                affiliation = Affiliation.NONE; break;
        }
        return affiliation;
    }

    private static Role parse_role(string role_str) {
        Role role;
        switch (role_str) {
            case "moderator":
                role = Role.MODERATOR; break;
            case "participant":
                role = Role.PARTICIPANT; break;
            case "visitor":
                role = Role.VISITOR; break;
            default:
                role = Role.NONE; break;
        }
        return role;
    }
}

}
