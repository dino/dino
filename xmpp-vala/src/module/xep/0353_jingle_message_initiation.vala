using Gee;

namespace Xmpp.Xep.JingleMessageInitiation {
    public const string NS_URI = "urn:xmpp:jingle-message:0";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0353_jingle_message_initiation");

        public signal void session_proposed(Jid from, Jid to, string sid, Gee.List<StanzaNode> descriptions);
        public signal void session_retracted(Jid from, Jid to, string sid);
        public signal void session_accepted(Jid from, string sid);
        public signal void session_rejected(Jid from, Jid to, string sid);

        public void send_session_propose_to_peer(XmppStream stream, Jid to, string sid, Gee.List<StanzaNode> descriptions) {
            StanzaNode propose_node = new StanzaNode.build("propose", NS_URI).add_self_xmlns().put_attribute("id", sid, NS_URI);
            foreach (StanzaNode desc_node in descriptions) {
                propose_node.put_node(desc_node);
            }

            MessageStanza accepted_message = new MessageStanza() { to=to };
            accepted_message.stanza.put_node(propose_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        public void send_session_retract_to_peer(XmppStream stream, Jid to, string sid) {
            MessageStanza retract_message = new MessageStanza() { to=to };
            retract_message.stanza.put_node(
                    new StanzaNode.build("retract", NS_URI).add_self_xmlns()
                            .put_attribute("id", sid, NS_URI));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, retract_message);
        }

        public void send_session_accept_to_self(XmppStream stream, string sid) {
            MessageStanza accepted_message = new MessageStanza() { to=Bind.Flag.get_my_jid(stream).bare_jid };
            accepted_message.stanza.put_node(
                    new StanzaNode.build("accept", NS_URI).add_self_xmlns()
                            .put_attribute("id", sid, NS_URI));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        public void send_session_reject_to_self(XmppStream stream, string sid) {
            MessageStanza accepted_message = new MessageStanza() { to=Bind.Flag.get_my_jid(stream).bare_jid };
            accepted_message.stanza.put_node(
                    new StanzaNode.build("reject", NS_URI).add_self_xmlns()
                            .put_attribute("id", sid, NS_URI));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        public void send_session_proceed_to_peer(XmppStream stream, Jid to, string sid) {
            MessageStanza accepted_message = new MessageStanza() { to=to };
            accepted_message.stanza.put_node(
                    new StanzaNode.build("proceed", NS_URI).add_self_xmlns()
                            .put_attribute("id", sid, NS_URI));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        public void send_session_reject_to_peer(XmppStream stream, Jid to, string sid) {
            MessageStanza accepted_message = new MessageStanza() { to=to };
            accepted_message.stanza.put_node(
                    new StanzaNode.build("reject", NS_URI).add_self_xmlns()
                            .put_attribute("id", sid, NS_URI));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            Xep.MessageArchiveManagement.MessageFlag? mam_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
            if (mam_flag != null) return;

            StanzaNode? mi_node = null;
            foreach (StanzaNode node in message.stanza.sub_nodes) {
                if (node.ns_uri == NS_URI) {
                    mi_node = node;
                }
            }
            if (mi_node == null) return;

            switch (mi_node.name) {
                case "accept":
                case "proceed":
                    session_accepted(message.from, mi_node.get_attribute("id"));
                    break;
                case "propose":
                    ArrayList<StanzaNode> descriptions = new ArrayList<StanzaNode>();

                    foreach (StanzaNode node in mi_node.sub_nodes) {
                        if (node.name != "description") continue;
                        descriptions.add(node);
                    }

                    if (descriptions.size > 0) {
                        session_proposed(message.from, message.to, mi_node.get_attribute("id"), descriptions);
                    }
                    break;
                case "retract":
                    session_retracted(message.from, message.to, mi_node.get_attribute("id"));
                    break;
                case "reject":
                    if (!message.from.equals_bare(Bind.Flag.get_my_jid(stream))) return;
                    session_rejected(message.from, message.to, mi_node.get_attribute("id"));
                    break;
            }
        }

        public override void attach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
