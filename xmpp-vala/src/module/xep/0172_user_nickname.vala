namespace Xmpp.Xep.UserNickname {

private const string NS_URI = "http://jabber.org/protocol/nick";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0172_user_nickname");

    public signal void received_nick(XmppStream stream, Jid jid, string nick);

    public void publish_nick(XmppStream stream, string nick) {
        StanzaNode nick_node = new StanzaNode.build("nick", NS_URI)
            .put_node(new StanzaNode.text(nick));
        stream.get_module(Pubsub.Module.IDENTITY).publish(stream, null, NS_URI, null, nick_node);
    }

    public async string? request_nick(XmppStream stream, Jid jid) {
        string? nick = null;
        stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid, NS_URI, (stream, jid, id, node) => {
            if (node != null && node.name == "nick" && node.ns_uri == NS_URI) {
                nick = node.get_string_content();
            }
            Idle.add(request_nick.callback);
        });
        yield;
        return nick;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI, on_pubsub_event, null);
    }

    public override void detach(XmppStream stream) {}

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public void on_pubsub_event(XmppStream stream, Jid jid, string id, StanzaNode? node) {
        if (node != null && node.name == "nick" && node.ns_uri == NS_URI) {
            string nick = node.get_string_content();
            received_nick(stream, jid, nick);
        }
    }
}

}
