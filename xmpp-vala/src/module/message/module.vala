using Gee;

using Xmpp.Core;

namespace Xmpp.Message {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamModule {
        public const string ID = "message_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public signal void pre_send_message(XmppStream stream, Message.Stanza message);
        public signal void pre_received_message(XmppStream stream, Message.Stanza message);
        public signal void received_message(XmppStream stream, Message.Stanza message);

        public void send_message(XmppStream stream, Message.Stanza message) {
            pre_send_message(stream, message);
            stream.write(message.stanza);
        }

        public void received_message_stanza(XmppStream stream, StanzaNode node) {
            Message.Stanza message = new Message.Stanza.from_stanza(node, Bind.Flag.get_flag(stream).my_jid);
            do {
                message.rerun_parsing = false;
                pre_received_message(stream, message);
            } while(message.rerun_parsing);
            received_message(stream, message);
        }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(IDENTITY);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Message.Module());
        }

        public override void attach(XmppStream stream) {
            Bind.Module.require(stream);
            stream.received_message_stanza.connect(received_message_stanza);
        }

        public override void detach(XmppStream stream) {
            stream.received_message_stanza.disconnect(received_message_stanza);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

}
