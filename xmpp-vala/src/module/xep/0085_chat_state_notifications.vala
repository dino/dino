using Gee;

namespace Xmpp.Xep.ChatStateNotifications {
private const string NS_URI = "http://jabber.org/protocol/chatstates";

public const string STATE_ACTIVE = "active";
public const string STATE_INACTIVE = "inactive";
public const string STATE_GONE = "gone";
public const string STATE_COMPOSING = "composing";
public const string STATE_PAUSED = "paused";

private const string[] STATES = { STATE_ACTIVE, STATE_INACTIVE, STATE_GONE, STATE_COMPOSING, STATE_PAUSED };

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0085_chat_state_notifications");

    public signal void chat_state_received(XmppStream stream, Jid jid, string state, MessageStanza stanza);

    private SendPipelineListener send_pipeline_listener = new SendPipelineListener();

    /**
    * "A message stanza that does not contain standard messaging content [...] SHOULD be a state other than <active/>" (0085, 5.6)
    */
    public void send_state(XmppStream stream, Jid jid, string message_type, string state) {
        MessageStanza message = new MessageStanza() { to=jid, type_=message_type };
        message.stanza.put_node(new StanzaNode.build(state, NS_URI).add_self_xmlns());

        MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_NO_STORE);

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).send_pipeline.connect(send_pipeline_listener);
        stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        stream.get_module(MessageModule.IDENTITY).send_pipeline.disconnect(send_pipeline_listener);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_message(XmppStream stream, MessageStanza message) {
        if (!message.is_error()) {
            Gee.List<StanzaNode> nodes = message.stanza.get_all_subnodes();
            foreach (StanzaNode node in nodes) {
                if (node.ns_uri == NS_URI && node.name in STATES) {
                    chat_state_received(stream, message.from, node.name, message);
                }
            }
        }
    }
}

public class SendPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {"MODIFY_BODY"};

    public override string action_group { get { return "ADD_NODES"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(XmppStream stream, MessageStanza message) {
        if (message.body == null) return false;
        if (message.type_ != MessageStanza.TYPE_CHAT) return false;
        message.stanza.put_node(new StanzaNode.build(STATE_ACTIVE, NS_URI).add_self_xmlns());
        return false;
    }
}

}
