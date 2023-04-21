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

    /**
    * "A message stanza that does not contain standard messaging content [...] SHOULD be a state other than <active/>" (0085, 5.6)
    */
    public void send_state(XmppStream stream, Jid jid, string message_type, string state) {
        MessageStanza message = new MessageStanza() { to=jid, type_=message_type };
        add_state_to_message(message, state);

        MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_NO_STORE);

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
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

public static void add_state_to_message(MessageStanza message, string state) {
    message.stanza.put_node(new StanzaNode.build(state, NS_URI).add_self_xmlns());
}

}
