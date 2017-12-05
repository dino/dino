using Xmpp.Core;

namespace Xmpp.Xep.MessageDeliveryReceipts {
    private const string NS_URI = "urn:xmpp:receipts";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0184_message_delivery_receipts");

        public signal void receipt_received(XmppStream stream, string jid, string id);

        private SendPipelineListener send_pipeline_listener = new SendPipelineListener();

        public void send_received(XmppStream stream, string from, string message_id) {
            Message.Stanza received_message = new Message.Stanza();
            received_message.to = from;
            received_message.stanza.put_node(new StanzaNode.build("received", NS_URI).add_self_xmlns().put_attribute("id", message_id));
            stream.get_module(Message.Module.IDENTITY).send_message(stream, received_message);
        }

        public static bool requests_receipt(Message.Stanza message) {
            return message.stanza.get_subnode("request", NS_URI) != null;
        }

        public override void attach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Message.Module.IDENTITY).received_message.connect(received_message);
            stream.get_module(Message.Module.IDENTITY).send_pipeline.connect(send_pipeline_listener);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Message.Module.IDENTITY).received_message.disconnect(received_message);
            stream.get_module(Message.Module.IDENTITY).send_pipeline.disconnect(send_pipeline_listener);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void received_message(XmppStream stream, Message.Stanza message) {
            StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
            if (received_node != null) {
                receipt_received(stream, message.from, received_node.get_attribute("id", NS_URI));
            }
        }
    }

public class SendPipelineListener : StanzaListener<Message.Stanza> {

    private const string[] after_actions_const = {};

    public override string action_group { get { return "ADD_NODES"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async void run(Core.XmppStream stream, Message.Stanza message) {
        StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
        if (received_node != null) return;
        if (message.body == null) return;
        if (message.type_ == Message.Stanza.TYPE_GROUPCHAT) return;
        message.stanza.put_node(new StanzaNode.build("request", NS_URI).add_self_xmlns());
    }
}

}
