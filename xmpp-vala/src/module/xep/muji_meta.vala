using Gee;
namespace Xmpp.Xep.MujiMeta {

    public const string NS_URI = "http://telepathy.freedesktop.org/muji";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "muji_meta");

        public signal void call_proposed(Jid from, Jid to, Jid muc_jid, Gee.List<StanzaNode> descriptions, string message_type);
        public signal void call_retracted(Jid from, Jid to, Jid muc_jid, string message_type);
        public signal void call_accepted(Jid from, Jid muc_jid, string message_type);
        public signal void call_rejected(Jid from, Jid to, Jid muc_jid, string message_type);

        public void send_invite(XmppStream stream, Jid invitee, Jid muc_jid, bool video, string? message_type = null) {
            var invite_node = new StanzaNode.build("propose", NS_URI).put_attribute("muc", muc_jid.to_string());
            invite_node.put_node(new StanzaNode.build("description", Xep.JingleRtp.NS_URI).add_self_xmlns().put_attribute("media", "audio"));
            if (video) {
                invite_node.put_node(new StanzaNode.build("description", Xep.JingleRtp.NS_URI).add_self_xmlns().put_attribute("media", "video"));
            }
            var muji_node = new StanzaNode.build("muji", NS_URI).add_self_xmlns().put_node(invite_node);
            MessageStanza invite_message = new MessageStanza() { to=invitee, type_=message_type };
            invite_message.stanza.put_node(muji_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, invite_message);
        }

        public void send_invite_retract_to_peer(XmppStream stream, Jid invitee, Jid muc_jid, string? message_type = null) {
            send_jmi_message(stream, "retract", invitee, muc_jid, message_type);
        }

        public void send_invite_accept_to_peer(XmppStream stream, Jid invitor, Jid muc_jid, string? message_type = null) {
            send_jmi_message(stream, "accept", invitor, muc_jid, message_type);
        }

        public void send_invite_accept_to_self(XmppStream stream, Jid muc_jid) {
            send_jmi_message(stream, "accept", Bind.Flag.get_my_jid(stream).bare_jid, muc_jid);
        }

        public void send_invite_reject_to_peer(XmppStream stream, Jid invitor, Jid muc_jid, string? message_type = null) {
            send_jmi_message(stream, "reject", invitor, muc_jid, message_type);
        }

        public void send_invite_reject_to_self(XmppStream stream, Jid muc_jid) {
            send_jmi_message(stream, "reject", Bind.Flag.get_my_jid(stream).bare_jid, muc_jid);
        }

        private void send_jmi_message(XmppStream stream, string name, Jid to, Jid muc, string? message_type = null) {
            var jmi_node = new StanzaNode.build(name, NS_URI).add_self_xmlns().put_attribute("muc", muc.to_string());
            var muji_node = new StanzaNode.build("muji", NS_URI).add_self_xmlns().put_node(jmi_node);

            MessageStanza accepted_message = new MessageStanza() { to=to, type_= message_type ?? MessageStanza.TYPE_CHAT };
            accepted_message.stanza.put_node(muji_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, accepted_message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            Xep.MessageArchiveManagement.MessageFlag? mam_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
            if (mam_flag != null) return;

            var muji_node = message.stanza.get_subnode("muji", NS_URI);
            if (muji_node == null) return;

            StanzaNode? mi_node = null;
            foreach (StanzaNode node in muji_node.sub_nodes) {
                if (node.ns_uri == NS_URI) {
                    mi_node = node;
                }
            }
            if (mi_node == null) return;

            string? jid_str = mi_node.get_attribute("muc");
            if (jid_str == null) return;

            Jid muc_jid = null;
            try {
                muc_jid = new Jid(jid_str);
            } catch (Error e) {
                return;
            }

            switch (mi_node.name) {
                case "accept":
                case "proceed":
                    call_accepted(message.from, muc_jid, message.type_);
                    break;
                case "propose":
                    ArrayList<StanzaNode> descriptions = new ArrayList<StanzaNode>();

                    foreach (StanzaNode node in mi_node.sub_nodes) {
                        if (node.name != "description") continue;
                        descriptions.add(node);
                    }

                    if (descriptions.size > 0) {
                        call_proposed(message.from, message.to, muc_jid, descriptions, message.type_);
                    }
                    break;
                case "retract":
                    call_retracted(message.from, message.to, muc_jid, message.type_);
                    break;
                case "reject":
                    call_rejected(message.from, message.to, muc_jid, message.type_);
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