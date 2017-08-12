using Xmpp.Core;

namespace Xmpp.Xep.DelayedDelivery {
    private const string NS_URI = "urn:xmpp:delay";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0203_delayed_delivery");

        public static void set_message_delay(Message.Stanza message, DateTime datetime) {
            StanzaNode delay_node = (new StanzaNode.build("delay", NS_URI)).add_self_xmlns();
            delay_node.put_attribute("stamp", (new DateTimeProfiles.Module()).to_datetime(datetime));
            message.stanza.put_node(delay_node);
        }

        public static DateTime? get_send_time(Message.Stanza message) {
            StanzaNode? delay_node = message.stanza.get_subnode("delay", NS_URI);
            if (delay_node != null) {
                string time = delay_node.get_attribute("stamp");
                return (new DateTimeProfiles.Module()).parse_string(time);
            } else {
                return null;
            }
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Message.Module.IDENTITY).pre_received_message.connect(on_pre_received_message);
        }

        public override void detach(XmppStream stream) { }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void on_pre_received_message(XmppStream stream, Message.Stanza message) {
            DateTime? datetime = get_send_time(message);
            if (datetime != null) message.add_flag(new MessageFlag(datetime));
        }
    }

    public class MessageFlag : Message.MessageFlag {
        public const string ID = "delayed_delivery";

        public DateTime datetime { get; private set; }

        public MessageFlag(DateTime datetime) {
            this.datetime = datetime;
        }

        public static MessageFlag? get_flag(Message.Stanza message) { return (MessageFlag) message.get_flag(NS_URI, ID); }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }
}
