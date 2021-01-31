namespace Xmpp.Xep.DirectMucInvitations {

    private const string NS_URI = "jabber:x:conference";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0249_direct_muc_invitations");

        public signal void invite_received(XmppStream stream, Jid room_jid, Jid from_jid, string? password, string? reason);

        public void invite(XmppStream stream, Jid to_muc, Jid jid) {
            MessageStanza message = new MessageStanza() { to=jid };
            StanzaNode invite_node = new StanzaNode.build("x", NS_URI).add_self_xmlns()
                    .put_attribute("jid", to_muc.to_string());
            message.stanza.put_node(invite_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
        }

        private void received_message(XmppStream stream, MessageStanza message) {
            StanzaNode? x_node = message.stanza.get_subnode("x", NS_URI);
            if (x_node == null) return;

            string? room_str = x_node.get_attribute("jid", NS_URI);
            if (room_str == null) return;
            Jid? room_jid = null;
            try {
                room_jid = new Jid(room_str);
            } catch (Error e) {
                return;
            }
            if (room_jid == null) return;

            string? password = x_node.get_attribute("password", NS_URI);
            string? reason = x_node.get_attribute("reason", NS_URI);

            invite_received(stream, room_jid, message.from, password, reason);
        }

        public override void attach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.connect(received_message);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.connect(received_message);
        }

        public override string get_ns() {
            return NS_URI;
        }

        public override string get_id() {
            return IDENTITY.id;
        }
    }

}
