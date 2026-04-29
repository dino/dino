namespace Xmpp.Xep.UserNickname {
private const string NS_URI = "http://jabber.org/protocol/nick";
private const string NODE = "nick";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0172_user_nickname");

    public override void attach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
        stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
        stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI, on_pubsub_item, null, null);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
        stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        stream.get_module(Pubsub.Module.IDENTITY).remove_filtered_notification(stream, NS_URI);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        if (presence.type_ != Presence.Stanza.TYPE_SUBSCRIBE) {
            return;
        }
        StanzaNode? nick_node = presence.stanza.get_subnode(NODE, NS_URI);
        if (nick_node == null) return;
        string? nick = nick_node.get_string_content();
        add_roster_contact(stream, presence.from, nick);
    }

    private void on_received_message(XmppStream stream, MessageStanza message) {
        if (message.type_ != MessageStanza.TYPE_CHAT) {
            return;
        }
        StanzaNode? nick_node = message.stanza.get_subnode(NODE, NS_URI);
        if (nick_node == null) return;
        string? nick = nick_node.get_string_content();
        add_roster_contact(stream, message.from, nick);
    }

    private void on_pubsub_item(XmppStream stream, Jid jid, string? id, StanzaNode? node) {
        if (node == null || node.name != NODE || node.ns_uri != NS_URI) {
            return;
        }
        string? nick = node.get_string_content();
        add_roster_contact(stream, jid, nick);
    }

    private void add_roster_contact(XmppStream stream, Jid jid, string? nick) {
        if (nick == null) return;
        Roster.Flag? flag = stream.get_flag(Roster.Flag.IDENTITY);
        if (flag == null) return;
        Roster.Item? item = flag.get_item(jid.bare_jid);
        if (item != null && item.jid != null && (item.name == null || item.name == "" || item.name == jid.localpart)) {
            stream.get_module(Roster.Module.IDENTITY).set_jid_handle(stream, jid, nick);
        }
    }
}

}
