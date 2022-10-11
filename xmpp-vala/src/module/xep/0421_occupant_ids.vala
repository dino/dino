namespace Xmpp.Xep.OccupantIds {

public const string NS_URI = "urn:xmpp:occupant-id:0";

public static string? get_occupant_id(StanzaNode stanza) {
    StanzaNode? node = stanza.get_subnode("occupant-id", NS_URI);
    if (node == null) return null;

    return node.get_attribute("id");
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0421_occupant_ids");

    public signal void received_occupant_id(XmppStream stream, Jid jid, string occupant_id);
    public signal void received_own_occupant_id(XmppStream stream, Jid jid, string occupant_id);

    public override void attach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_available.connect(parse_occupant_id_from_presence);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_available.disconnect(parse_occupant_id_from_presence);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public void parse_occupant_id_from_presence(XmppStream stream, Presence.Stanza presence) {
        string? occupant_id = get_occupant_id(presence.stanza);
        if (occupant_id == null) return;

        received_occupant_id(stream, presence.from, occupant_id);

        StanzaNode? x_node = presence.stanza.get_subnode("x", "http://jabber.org/protocol/muc#user");
        if (x_node == null) return;
        foreach (StanzaNode status_node in x_node.get_subnodes("status", "http://jabber.org/protocol/muc#user")) {
            if (int.parse(status_node.get_attribute("code")) == 110) {
                received_own_occupant_id(stream, presence.from, occupant_id);
            }
        }
    }
}

}
