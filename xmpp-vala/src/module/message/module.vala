using Gee;



namespace Xmpp {
    private const string NS_URI = "jabber:client";

    public class MessageModule : XmppStreamModule {
        public static ModuleIdentity<MessageModule> IDENTITY = new ModuleIdentity<MessageModule>(NS_URI, "message_module");

        public StanzaListenerHolder<MessageStanza> received_pipeline = new StanzaListenerHolder<MessageStanza>();
        public StanzaListenerHolder<MessageStanza> send_pipeline = new StanzaListenerHolder<MessageStanza>();

        public signal void pre_received_message(XmppStream stream, MessageStanza message);
        public signal void received_message(XmppStream stream, MessageStanza message);

        public void send_message(XmppStream stream, MessageStanza message) {
            send_pipeline.run.begin(stream, message, (obj, res) => {
                stream.write(message.stanza);
            });
        }

        public async void received_message_stanza_async(XmppStream stream, StanzaNode node) {
            MessageStanza message = new MessageStanza.from_stanza(node, stream.get_flag(Bind.Flag.IDENTITY).my_jid);
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
