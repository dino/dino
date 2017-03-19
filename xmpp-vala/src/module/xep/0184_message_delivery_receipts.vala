using Gdk;

using Xmpp.Core;

namespace Xmpp.Xep.MessageDeliveryReceipts {
    private const string NS_URI = "urn:xmpp:receipts";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0184_message_delivery_receipts");

        public signal void receipt_received(XmppStream stream, string jid, string id);

        public override void attach(XmppStream stream) {
            ServiceDiscovery.Module.require(stream);
            Message.Module.require(stream);

            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Message.Module.IDENTITY).received_message.connect(received_message);
            stream.get_module(Message.Module.IDENTITY).pre_send_message.connect(pre_send_message);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Message.Module.IDENTITY).received_message.disconnect(received_message);
            stream.get_module(Message.Module.IDENTITY).pre_send_message.disconnect(pre_send_message);
        }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void received_message(XmppStream stream, Message.Stanza message) {
            StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
            if (received_node != null) {
                receipt_received(stream, message.from, received_node.get_attribute("id", NS_URI));
            } else if (message.stanza.get_subnode("request", NS_URI) != null) {
                send_received(stream, message);
            }
        }

        private void send_received(XmppStream stream, Message.Stanza message) {
            Message.Stanza received_message = new Message.Stanza();
            received_message.to = message.from;
            received_message.stanza.put_node(new StanzaNode.build("received", NS_URI).add_self_xmlns().put_attribute("id", message.id));
            stream.get_module(Message.Module.IDENTITY).send_message(stream, received_message);
        }

        private void pre_send_message(XmppStream stream, Message.Stanza message) {
            StanzaNode? received_node = message.stanza.get_subnode("received", NS_URI);
            if (received_node != null) return;
            if (message.body == null) return;
            if (message.type_ == Message.Stanza.TYPE_GROUPCHAT) return;
            message.stanza.put_node(new StanzaNode.build("request", NS_URI).add_self_xmlns());
        }
    }
}
