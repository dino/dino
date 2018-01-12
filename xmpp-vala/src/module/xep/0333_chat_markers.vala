using Gee;

namespace Xmpp.Xep.ChatMarkers {
private const string NS_URI = "urn:xmpp:chat-markers:0";

public const string MARKER_RECEIVED = "received";
public const string MARKER_DISPLAYED = "displayed";
public const string MARKER_ACKNOWLEDGED = "acknowledged";

private const string[] MARKERS = {MARKER_RECEIVED, MARKER_DISPLAYED, MARKER_ACKNOWLEDGED};

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0333_chat_markers");

    public signal void marker_received(XmppStream stream, Jid jid, string marker, string id);

    private SendPipelineListener send_pipeline_listener = new SendPipelineListener();

    public void send_marker(XmppStream stream, Jid jid, string message_id, string type_, string marker) {
        MessageStanza received_message = new MessageStanza();
        received_message.to = jid;
        received_message.type_ = type_;
        received_message.stanza.put_node(new StanzaNode.build(marker, NS_URI).add_self_xmlns().put_attribute("id", message_id));
        stream.get_module(MessageModule.IDENTITY).send_message(stream, received_message);
    }

    public static bool requests_marking(MessageStanza message) {
        StanzaNode markable_node = message.stanza.get_subnode("markable", NS_URI);
        return markable_node != null;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).send_pipeline.connect(send_pipeline_listener);
        stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        stream.get_module(MessageModule.IDENTITY).send_pipeline.disconnect(send_pipeline_listener);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_message(XmppStream stream, MessageStanza message) {
        if (message.type_ != MessageStanza.TYPE_CHAT) return;
        Gee.List<StanzaNode> nodes = message.stanza.get_all_subnodes();
        foreach (StanzaNode node in nodes) {
            if (node.ns_uri == NS_URI && node.name in MARKERS) {
                marker_received(stream, message.from, node.name, node.get_attribute("id", NS_URI));
            }
        }
    }
}

public class SendPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {};

    public override string action_group { get { return "ADD_NODES"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async void run(XmppStream stream, MessageStanza message) {
        StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
        if (received_node != null) return;
        if (message.body == null) return;
        if (message.type_ != MessageStanza.TYPE_CHAT) return;
        message.stanza.put_node(new StanzaNode.build("markable", NS_URI).add_self_xmlns());
    }
}

}
