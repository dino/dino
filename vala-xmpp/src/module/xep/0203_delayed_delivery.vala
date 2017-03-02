using Xmpp.Core;

namespace Xmpp.Xep.DelayedDelivery {
    private const string NS_URI = "urn:xmpp:delay";

    public class Module : XmppStreamModule {
        public const string ID = "0203_delayed_delivery";

        public static DateTime? get_send_time(Message.Stanza message) {
            StanzaNode? delay_node = message.stanza.get_subnode("delay", NS_URI);
            if (delay_node != null) {
                string time = delay_node.get_attribute("stamp");
                return new DateTime.utc(int.parse(time.substring(0, 4)),
                    int.parse(time.substring(5, 2)),
                    int.parse(time.substring(8, 2)),
                    int.parse(time.substring(11, 2)),
                    int.parse(time.substring(14, 2)),
                    int.parse(time.substring(17, 2)));
            } else {
                return null;
            }
        }

        public override void attach(XmppStream stream) {
            Message.Module.get_module(stream).pre_received_message.connect(on_pre_received_message);
        }

        public override void detach(XmppStream stream) { }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private void on_pre_received_message(XmppStream stream, Message.Stanza message) {
            StanzaNode? delay_node = message.stanza.get_subnode("delay", NS_URI);
            if (delay_node != null) {
                string time = delay_node.get_attribute("stamp");
                DateTime datetime = new DateTime.utc(int.parse(time.substring(0, 4)),
                    int.parse(time.substring(5, 2)),
                    int.parse(time.substring(8, 2)),
                    int.parse(time.substring(11, 2)),
                    int.parse(time.substring(14, 2)),
                    int.parse(time.substring(17, 2)));
                message.add_flag(new MessageFlag(datetime));
            }
        }
    }

    public class MessageFlag : Message.MessageFlag {
        public const string ID = "delayed_delivery";

        DateTime datetime;

        public MessageFlag(DateTime datetime) {
            this.datetime = datetime;
        }

        public static MessageFlag? get_flag(Message.Stanza message) { return (MessageFlag) message.get_flag(NS_URI, ID); }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }
}
