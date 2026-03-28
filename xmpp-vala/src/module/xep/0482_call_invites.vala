using Gee;
namespace Xmpp.Xep.CallInvites {

    public const string NS_URI = "urn:xmpp:call-invites:0";
    public const string NS_URI_CUSTOM = "urn:xmpp:call-message:1";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "call_invites");

        public signal void call_proposed(Jid from, Jid to, string call_id, bool video, Gee.List<StanzaNode> join_methods, MessageStanza message);
        public signal void call_retracted(Jid from, Jid to, string call_id, string message_type);
        public signal void call_accepted(Jid from, Jid to, string call_id, string message_type);
        public signal void call_rejected(Jid from, Jid to, string call_id, string message_type);
        public signal void call_left(Jid from, Jid to, string call_id, string message_type);

        public void send_jingle_propose(XmppStream stream, string call_id, Jid invitee, string sid, bool video, string message_type = MessageStanza.TYPE_CHAT) {
            StanzaNode method = new StanzaNode.build("jingle", CallInvites.NS_URI).put_attribute("sid", sid);
            StanzaNode legacy_method = new StanzaNode.build("jingle", CallInvites.NS_URI_CUSTOM).put_attribute("sid", sid);
            send_propose(stream, call_id, invitee, video, false, message_type, method, legacy_method);
        }

        public void send_muji_propose(XmppStream stream, string call_id, Jid invitee, Jid muc_jid, bool video, string message_type) {
            StanzaNode method = new StanzaNode.build("muji", Muji.NS_URI).add_self_xmlns().put_attribute("room", muc_jid.to_string());
            send_propose(stream, call_id, invitee, video, true, message_type, method, method);
        }

        public void send_propose(XmppStream stream, string call_id, Jid invitee, bool video, bool multi, string message_type, StanzaNode method, StanzaNode? legacy_method = null) {
            MessageStanza invite_message = new MessageStanza() { to=invitee, type_=message_type };
            invite_message.stanza.put_node(
                    new StanzaNode.build("invite", NS_URI).add_self_xmlns()
                            .put_attribute("id", call_id)
                            .put_attribute("video", video.to_string())
                            .put_attribute("multi", multi.to_string())
                            .put_node(method)
            );
            if (legacy_method != null) {
                invite_message.stanza.put_node( // Custom legacy protocol
                        new StanzaNode.build("propose", NS_URI_CUSTOM).add_self_xmlns()
                                .put_attribute("id", call_id)
                                .put_attribute("video", video.to_string())
                                .put_attribute("multi", multi.to_string())
                                .put_node(legacy_method)
                );
            }
            MessageProcessingHints.set_message_hint(invite_message, MessageProcessingHints.HINT_STORE);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, invite_message);
        }

        public void send_jingle_accept(XmppStream stream, Jid inviter, string call_id, string sid, string message_type) {
            StanzaNode method = new StanzaNode.build("jingle", NS_URI).put_attribute("sid", sid);
            StanzaNode legacy_method = new StanzaNode.build("jingle", NS_URI_CUSTOM).put_attribute("sid", sid);
            send_accept(stream, inviter, call_id, message_type, method, legacy_method);
        }

        public void send_muji_accept(XmppStream stream, Jid inviter, string call_id, Jid room, string message_type) {
            StanzaNode method = new StanzaNode.build("muji", Muji.NS_URI).add_self_xmlns().put_attribute("room", room.to_string());
            send_accept(stream, inviter, call_id, message_type, method, method);
        }

        public void send_accept(XmppStream stream, Jid inviter, string call_id, string message_type, StanzaNode method, StanzaNode? legacy_method = null) {
            MessageStanza invite_message = new MessageStanza() { to=inviter, type_=message_type };
            invite_message.stanza.put_node(
                    new StanzaNode.build("accept", NS_URI).add_self_xmlns()
                            .put_attribute("id", call_id)
                            .put_node(method)
            );
            if (legacy_method != null) {
                invite_message.stanza.put_node(
                        new StanzaNode.build("accept", NS_URI_CUSTOM).add_self_xmlns()
                                .put_attribute("id", call_id)
                                .put_node(legacy_method)
                );
            }
            MessageProcessingHints.set_message_hint(invite_message, MessageProcessingHints.HINT_STORE);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, invite_message);
        }

        public void send_retract(XmppStream stream, Jid to, string call_id, string message_type) {
            send_message(stream, to, call_id, "retract", message_type);
        }

        public void send_reject(XmppStream stream, Jid to, string call_id, string message_type) {
            send_message(stream, to, call_id, "reject", message_type);
        }

        public void send_left(XmppStream stream, Jid to, string call_id, string message_type) {
            MessageStanza message = new MessageStanza() { to=to, type_=message_type };

            StanzaNode inner_node = new StanzaNode.build("left", NS_URI).add_self_xmlns().put_attribute("id", call_id);
            message.stanza.put_node(inner_node);

            // Custom legacy protocol
            StanzaNode custom_node = new StanzaNode.build("finish", NS_URI_CUSTOM).add_self_xmlns().put_attribute("id", call_id);
            message.stanza.put_node(custom_node);

            MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_STORE);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
        }

        private void send_message(XmppStream stream, Jid to, string call_id, string action, string message_type) {
            MessageStanza message = new MessageStanza() { to=to, type_=message_type };

            StanzaNode inner_node = new StanzaNode.build(action, NS_URI).add_self_xmlns().put_attribute("id", call_id);
            message.stanza.put_node(inner_node);

            // Custom legacy protocol
            StanzaNode custom_node = new StanzaNode.build(action, NS_URI_CUSTOM).add_self_xmlns().put_attribute("id", call_id);
            message.stanza.put_node(custom_node);

            MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_STORE);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            Xmpp.MessageArchiveManagement.MessageFlag? mam_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message);
            if (mam_flag != null) return;

            StanzaNode? relevant_node = null;

            foreach (StanzaNode node in message.stanza.sub_nodes) {
                if (node.ns_uri == NS_URI) {
                    relevant_node = node;
                    break;
                }
            }
            if (relevant_node == null) {
                foreach (StanzaNode node in message.stanza.sub_nodes) {
                    if (node.ns_uri == NS_URI_CUSTOM) {
                        relevant_node = node;
                        break;
                    }
                }
            }
            if (relevant_node == null) return;

            string? call_id = relevant_node.get_attribute("id");
            if (call_id == null) return;

            if (relevant_node.name == "invite" || /* custom legacy */relevant_node.name == "propose") {
                if (relevant_node.sub_nodes.is_empty) return;

                // If there's also a JMI node, just use that one instead.
                foreach (StanzaNode node in message.stanza.sub_nodes) {
                    if (node.ns_uri == JingleMessageInitiation.NS_URI) return;
                }

                bool video = relevant_node.get_attribute_bool("video", false);
                call_proposed(message.from, message.to, call_id, video, relevant_node.sub_nodes, message);
                return;
            }

            switch (relevant_node.name) {
                case "accept":
                    call_accepted(message.from, message.to, call_id, message.type_);
                    break;
                case "retract":
                    call_retracted(message.from, message.to, call_id, message.type_);
                    break;
                case "reject":
                    call_rejected(message.from, message.to, call_id, message.type_);
                    break;
                case "finish":
                    call_left(message.from, message.to, call_id, message.type_);
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