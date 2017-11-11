using Gee;

using Xmpp.Core;

namespace Xmpp.Message {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "message_module");

        public StanzaListenerHolder<Message.Stanza> received_pipeline = new StanzaListenerHolder<Message.Stanza>();
        public StanzaListenerHolder<Message.Stanza> send_pipeline = new StanzaListenerHolder<Message.Stanza>();

        public signal void pre_received_message(XmppStream stream, Message.Stanza message);
        public signal void received_message(XmppStream stream, Message.Stanza message);

        public void send_message(XmppStream stream, Message.Stanza message) {
            send_pipeline.run.begin(stream, message);
            stream.write(message.stanza);
        }

        public async void received_message_stanza_async(XmppStream stream, StanzaNode node) {
            Message.Stanza message = new Message.Stanza.from_stanza(node, stream.get_flag(Bind.Flag.IDENTITY).my_jid);
            yield received_pipeline.run(stream, message);
            received_message(stream, message);
        }

        private void received_message_stanza(XmppStream stream, StanzaNode node) {
            received_message_stanza_async.begin(stream, node);
        }

        public override void attach(XmppStream stream) {
            stream.received_message_stanza.connect(received_message_stanza);
        }

        public override void detach(XmppStream stream) {
            stream.received_message_stanza.disconnect(received_message_stanza);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

}
