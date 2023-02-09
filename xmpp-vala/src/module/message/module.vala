using Gee;



namespace Xmpp {
    private const string NS_URI = "jabber:client";

    public class MessageModule : XmppStreamModule {
        public static ModuleIdentity<MessageModule> IDENTITY = new ModuleIdentity<MessageModule>(NS_URI, "message_module");

        public StanzaListenerHolder<MessageStanza> received_pipeline = new StanzaListenerHolder<MessageStanza>();
        public StanzaListenerHolder<MessageStanza> send_pipeline = new StanzaListenerHolder<MessageStanza>();

        public signal void received_message(XmppStream stream, MessageStanza message);
        public signal void received_error(XmppStream stream, MessageStanza message, ErrorStanza error);
        public signal void received_message_unprocessed(XmppStream stream, MessageStanza message);

        public async void send_message(XmppStream stream, MessageStanza message) throws IOError {
            yield send_pipeline.run(stream, message);
            yield stream.write_async(message.stanza);
        }

        public async void received_message_stanza_async(XmppStream stream, StanzaNode node) {
            MessageStanza message = new MessageStanza.from_stanza(node, stream.get_flag(Bind.Flag.IDENTITY).my_jid);

            received_message_unprocessed(stream, message);

            if (message.is_error()) {
                ErrorStanza? error_stanza = message.get_error();
                if (error_stanza == null) return;
                received_error(stream, message, error_stanza);
            } else {
                bool abort = yield received_pipeline.run(stream, message);
                if (abort) return;

                received_message(stream, message);
            }
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
