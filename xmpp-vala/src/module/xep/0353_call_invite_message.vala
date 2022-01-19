using Gee;
namespace Xmpp.Xep.CallInvites {

    public const string NS_URI = "urn:xmpp:call-invites:0";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "call_invites");

        public signal void call_proposed(Jid from, Jid to, bool video, Gee.List<StanzaNode> join_methods, MessageStanza message);
        public signal void call_retracted(Jid from, Jid to, string invite_id, string message_type);
        public signal void call_accepted(Jid from, string invite_id, string message_type);
        public signal void call_rejected(Jid from, Jid to, string invite_id, string message_type);

        public void send_invite(XmppStream stream, Jid invitee, Jid muc_jid, bool video, string message_type) {
            StanzaNode muji_node = new StanzaNode.build("muji", Muji.NS_URI).add_self_xmlns().put_attribute("room", muc_jid.to_string());
            StanzaNode invite_node = new StanzaNode.build("propose", NS_URI).add_self_xmlns()
                    .put_attribute("video", video.to_string())
                    .put_node(muji_node);
            MessageStanza invite_message = new MessageStanza() { to=invitee, type_=message_type };
            MessageProcessingHints.set_message_hint(invite_message, MessageProcessingHints.HINT_STORE);
            invite_message.stanza.put_node(invite_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, invite_message);
        }

        public void send_retract(XmppStream stream, Jid to, string invite_id, string message_type) {
            send_message(stream, "retract", to, invite_id, message_type);
        }

        public void send_accept(XmppStream stream, Jid to, string invite_id, string message_type) {
            send_message(stream, "accept", to, invite_id, message_type);
        }

        public void send_reject(XmppStream stream, Jid to, string invite_id, string message_type) {
            send_message(stream, "reject", to, invite_id, message_type);
        }

        private void send_message(XmppStream stream, string action, Jid to, string invite_id, string message_type) {
            StanzaNode inner_node = new StanzaNode.build(action, NS_URI).add_self_xmlns().put_attribute("id", invite_id);
            MessageStanza message = new MessageStanza() { to=to, type_=message_type };
            message.stanza.put_node(inner_node);
            MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_STORE);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            Xep.MessageArchiveManagement.MessageFlag? mam_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
            if (mam_flag != null) return;

            StanzaNode? relevant_node = null;

            foreach (StanzaNode node in message.stanza.sub_nodes) {
                if (node.ns_uri == NS_URI) {
                    relevant_node = node;
                    break;
                }
            }
            if (relevant_node == null) return;

            if (relevant_node.name == "propose") {
                if (relevant_node.sub_nodes.is_empty) return;
                bool video = relevant_node.get_attribute_bool("video", false);
                call_proposed(message.from, message.to, video, relevant_node.sub_nodes, message);
                return;
            }

            string? invite_id = relevant_node.get_attribute("id");
            if (invite_id == null) return;

            switch (relevant_node.name) {
                case "accept":
                    call_accepted(message.from, invite_id, message.type_);
                    break;
                case "retract":
                    call_retracted(message.from, message.to, invite_id, message.type_);
                    break;
                case "reject":
                    call_rejected(message.from, message.to, invite_id, message.type_);
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