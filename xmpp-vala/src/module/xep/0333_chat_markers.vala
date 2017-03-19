using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ChatMarkers {
private const string NS_URI = "urn:xmpp:chat-markers:0";

public const string MARKER_RECEIVED = "received";
public const string MARKER_DISPLAYED = "displayed";
public const string MARKER_ACKNOWLEDGED = "acknowledged";

private const string[] MARKERS = {MARKER_RECEIVED, MARKER_DISPLAYED, MARKER_ACKNOWLEDGED};

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0333_chat_markers");

    public signal void marker_received(XmppStream stream, string jid, string marker, string id);

    public void send_marker(XmppStream stream, string jid, string message_id, string type_, string marker) {
        Message.Stanza received_message = new Message.Stanza();
        received_message.to = jid;
        received_message.type_ = type_;
        received_message.stanza.put_node(new StanzaNode.build(marker, NS_URI).add_self_xmlns().put_attribute("id", message_id));
        stream.get_module(Message.Module.IDENTITY).send_message(stream, received_message);
    }

    public static bool requests_marking(Message.Stanza message) {
        StanzaNode markable_node = message.stanza.get_subnode("markable", NS_URI);
        return markable_node != null;
    }

    public override void attach(XmppStream stream) {
        Iq.Module.require(stream);
        Message.Module.require(stream);
        ServiceDiscovery.Module.require(stream);

        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Message.Module.IDENTITY).pre_send_message.connect(on_pre_send_message);
        stream.get_module(Message.Module.IDENTITY).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Message.Module.IDENTITY).pre_send_message.disconnect(on_pre_send_message);
        stream.get_module(Message.Module.IDENTITY).received_message.disconnect(on_received_message);
    }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stream.add_module(new ChatMarkers.Module());
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_message(XmppStream stream, Message.Stanza message) {
        if (message.type_ != Message.Stanza.TYPE_CHAT) return;
        if (requests_marking(message)) {
            send_marker(stream, message.from, message.id, message.type_, MARKER_RECEIVED);
            return;
        }
        ArrayList<StanzaNode> nodes = message.stanza.get_all_subnodes();
        foreach (StanzaNode node in nodes) {
            if (node.ns_uri == NS_URI && node.name in MARKERS) {
                marker_received(stream, message.from, node.name, node.get_attribute("id", NS_URI));
            }
        }
    }

    private void on_pre_send_message(XmppStream stream, Message.Stanza message) {
        StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
        if (received_node != null) return;
        if (message.body == null) return;
        if (message.type_ != Message.Stanza.TYPE_CHAT) return;
        message.stanza.put_node(new StanzaNode.build("markable", NS_URI).add_self_xmlns());
    }
}

}
