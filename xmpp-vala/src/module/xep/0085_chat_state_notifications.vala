using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ChatStateNotifications {
private const string NS_URI = "http://jabber.org/protocol/chatstates";

public const string STATE_ACTIVE = "active";
public const string STATE_INACTIVE = "inactive";
public const string STATE_GONE = "gone";
public const string STATE_COMPOSING = "composing";
public const string STATE_PAUSED = "paused";

private const string[] STATES = {STATE_ACTIVE, STATE_INACTIVE, STATE_GONE, STATE_COMPOSING, STATE_PAUSED};

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0085_chat_state_notifications");

    public signal void chat_state_received(XmppStream stream, string jid, string state);

    /**
    * "A message stanza that does not contain standard messaging content [...] SHOULD be a state other than <active/>" (0085, 5.6)
    */
    public void send_state(XmppStream stream, string jid, string state) {
        Message.Stanza message = new Message.Stanza();
        message.to = jid;
        message.type_ = Message.Stanza.TYPE_CHAT;
        message.stanza.put_node(new StanzaNode.build(state, NS_URI).add_self_xmlns());
        stream.get_module(Message.Module.IDENTITY).send_message(stream, message);
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Message.Module.IDENTITY).send_pipeline.connect(new SendPipelineListener());
        stream.get_module(Message.Module.IDENTITY).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Message.Module.IDENTITY).received_message.disconnect(on_received_message);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_message(XmppStream stream, Message.Stanza message) {
        if (!message.is_error()) {
            Gee.List<StanzaNode> nodes = message.stanza.get_all_subnodes();
            foreach (StanzaNode node in nodes) {
                if (node.ns_uri == NS_URI &&
                    node.name in STATES) {
                    chat_state_received(stream, message.from, node.name);
                }
            }
        }
    }
}

public class SendPipelineListener : StanzaListener<Message.Stanza> {

    private const string[] after_actions_const = {"MODIFY_BODY"};

    public override string action_group { get { return "ADD_NODES"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async void run(Core.XmppStream stream, Message.Stanza message) {
        if (message.body == null) return;
        if (message.type_ != Message.Stanza.TYPE_CHAT) return;
        message.stanza.put_node(new StanzaNode.build(STATE_ACTIVE, NS_URI).add_self_xmlns());
    }
}

}
