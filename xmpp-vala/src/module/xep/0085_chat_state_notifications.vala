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
    public const string ID = "0085_chat_state_notifications";
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

    public signal void chat_state_received(XmppStream stream, string jid, string state);

    /**
    * "A message stanza that does not contain standard messaging content [...] SHOULD be a state other than <active/>" (0085, 5.6)
    */
    public void send_state(XmppStream stream, string jid, string state) {
        Message.Stanza message = new Message.Stanza();
        message.to = jid;
        message.type_ = Message.Stanza.TYPE_CHAT;
        message.stanza.put_node(new StanzaNode.build(state, NS_URI).add_self_xmlns());
        Message.Module.get_module(stream).send_message(stream, message);
    }

    public override void attach(XmppStream stream) {
        ServiceDiscovery.Module.require(stream);
        ServiceDiscovery.Module.get_module(stream).add_feature(stream, NS_URI);
        Message.Module.get_module(stream).pre_send_message.connect(on_pre_send_message);
        Message.Module.get_module(stream).received_message.connect(on_received_message);
    }

    public override void detach(XmppStream stream) {
        Message.Module.get_module(stream).pre_send_message.disconnect(on_pre_send_message);
        Message.Module.get_module(stream).received_message.disconnect(on_received_message);
    }

    public static Module? get_module(XmppStream stream) {
        return (Module?) stream.get_module(IDENTITY);
    }

    public static void require(XmppStream stream) {
        if (get_module(stream) == null) stream.add_module(new Module()); ;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }

    private void on_pre_send_message(XmppStream stream, Message.Stanza message) {
        if (message.body == null) return;
        if (message.type_ != Message.Stanza.TYPE_CHAT) return;
        message.stanza.put_node(new StanzaNode.build(STATE_ACTIVE, NS_URI).add_self_xmlns());
    }

    private void on_received_message(XmppStream stream, Message.Stanza message) {
        if (!message.is_error()) {
            ArrayList<StanzaNode> nodes = message.stanza.get_all_subnodes();
            foreach (StanzaNode node in nodes) {
                if (node.ns_uri == NS_URI &&
                    node.name in STATES) {
                    chat_state_received(stream, message.from, node.name);
                }
            }
        }
    }
}

}
