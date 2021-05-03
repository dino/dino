using Signal;
using Gee;
using Xmpp;

namespace Dino.Plugins.Omemo.DtlsSrtpVerificationDraft {
    public const string NS_URI = "http://gultsch.de/xmpp/drafts/omemo/dlts-srtp-verification";

    public class StreamModule : XmppStreamModule {

        public static Xmpp.ModuleIdentity<StreamModule> IDENTITY = new Xmpp.ModuleIdentity<StreamModule>(NS_URI, "dtls_srtp_omemo_verification_draft");

        private VerificationSendListener send_listener = new VerificationSendListener();
        private HashMap<string, int> device_id_by_jingle_sid = new HashMap<string, int>();
        private HashMap<string, Gee.List<string>> content_names_by_jingle_sid = new HashMap<string, Gee.List<string>>();

        private void on_preprocess_incoming_iq_set_get(XmppStream stream, Xmpp.Iq.Stanza iq) {
            if (iq.type_ != Iq.Stanza.TYPE_SET) return;

            Gee.List<StanzaNode> content_nodes = iq.stanza.get_deep_subnodes(Xep.Jingle.NS_URI + ":jingle", Xep.Jingle.NS_URI + ":content");
            if (content_nodes.size == 0) return;

            string? jingle_sid = iq.stanza.get_deep_attribute(Xep.Jingle.NS_URI + ":jingle", "sid");
            if (jingle_sid == null) return;

            Xep.Omemo.OmemoDecryptor decryptor = stream.get_module(Xep.Omemo.OmemoDecryptor.IDENTITY);

            foreach (StanzaNode content_node in content_nodes) {
                string? content_name = content_node.get_attribute("name");
                if (content_name == null) continue;
                StanzaNode? transport_node = content_node.get_subnode("transport", Xep.JingleIceUdp.NS_URI);
                if (transport_node == null) continue;
                StanzaNode? fingerprint_node = transport_node.get_subnode("fingerprint", NS_URI);
                if (fingerprint_node == null) continue;
                StanzaNode? encrypted_node = fingerprint_node.get_subnode("encrypted", Omemo.NS_URI);
                if (encrypted_node == null) continue;

                Xep.Omemo.ParsedData? parsed_data = decryptor.parse_node(encrypted_node);
                if (parsed_data == null || parsed_data.ciphertext == null) continue;

                if (device_id_by_jingle_sid.has_key(jingle_sid) && device_id_by_jingle_sid[jingle_sid] != parsed_data.sid) {
                    warning("Expected DTLS fingerprint to be OMEMO encrypted from %s %d, but it was from %d", iq.from.to_string(), device_id_by_jingle_sid[jingle_sid], parsed_data.sid);
                }

                foreach (Bytes encr_key in parsed_data.our_potential_encrypted_keys.keys) {
                    parsed_data.is_prekey = parsed_data.our_potential_encrypted_keys[encr_key];
                    parsed_data.encrypted_key = encr_key.get_data();

                    try {
                        uint8[] key = decryptor.decrypt_key(parsed_data, iq.from.bare_jid);
                        string cleartext = decryptor.decrypt(parsed_data.ciphertext, key, parsed_data.iv);

                        StanzaNode new_fingerprint_node = new StanzaNode.build("fingerprint", Xep.JingleIceUdp.DTLS_NS_URI).add_self_xmlns()
                                .put_node(new StanzaNode.text(cleartext));
                        string? hash_attr = fingerprint_node.get_attribute("hash", NS_URI);
                        string? setup_attr = fingerprint_node.get_attribute("setup", NS_URI);
                        if (hash_attr != null) new_fingerprint_node.put_attribute("hash", hash_attr);
                        if (setup_attr != null) new_fingerprint_node.put_attribute("setup", setup_attr);
                        transport_node.put_node(new_fingerprint_node);

                        device_id_by_jingle_sid[jingle_sid] = parsed_data.sid;
                        if (!content_names_by_jingle_sid.has_key(content_name)) {
                            content_names_by_jingle_sid[content_name] = new ArrayList<string>();
                        }
                        content_names_by_jingle_sid[content_name].add(content_name);

                        stream.get_flag(Xep.Jingle.Flag.IDENTITY).get_session.begin(jingle_sid, (_, res) => {
                            Xep.Jingle.Session? session = stream.get_flag(Xep.Jingle.Flag.IDENTITY).get_session.end(res);
                            if (session == null || !session.contents_map.has_key(content_name)) return;
                            var encryption = new OmemoContentEncryption() { encryption_ns=NS_URI, encryption_name="OMEMO", our_key=new uint8[0], peer_key=new uint8[0], sid=device_id_by_jingle_sid[jingle_sid], jid=iq.from.bare_jid };
                            session.contents_map[content_name].encryptions[NS_URI] = encryption;

                            if (iq.stanza.get_deep_attribute(Xep.Jingle.NS_URI + ":jingle", "action") == "session-accept") {
                                session.additional_content_add_incoming.connect(on_content_add_received);
                            }
                        });

                        break;
                    } catch (Error e) {
                        debug("Decrypting message from %s/%d failed: %s", iq.from.bare_jid.to_string(), parsed_data.sid, e.message);
                    }
                }
            }
        }

        private void on_preprocess_outgoing_iq_set_get(XmppStream stream, Xmpp.Iq.Stanza iq) {
            if (iq.type_ != Iq.Stanza.TYPE_SET) return;

            StanzaNode? jingle_node = iq.stanza.get_subnode("jingle", Xep.Jingle.NS_URI);
            if (jingle_node == null) return;

            string? sid = jingle_node.get_attribute("sid", Xep.Jingle.NS_URI);
            if (sid == null || !device_id_by_jingle_sid.has_key(sid)) return;

            Gee.List<StanzaNode> content_nodes = jingle_node.get_subnodes("content", Xep.Jingle.NS_URI);
            if (content_nodes.size == 0) return;

            foreach (StanzaNode content_node in content_nodes) {
                StanzaNode? transport_node = content_node.get_subnode("transport", Xep.JingleIceUdp.NS_URI);
                if (transport_node == null) continue;
                StanzaNode? fingerprint_node = transport_node.get_subnode("fingerprint", Xep.JingleIceUdp.DTLS_NS_URI);
                if (fingerprint_node == null) continue;
                string fingerprint = fingerprint_node.get_deep_string_content();

                Xep.Omemo.OmemoEncryptor encryptor = stream.get_module(Xep.Omemo.OmemoEncryptor.IDENTITY);
                Xep.Omemo.EncryptionData enc_data = encryptor.encrypt_plaintext(fingerprint);
                encryptor.encrypt_key(enc_data, iq.to.bare_jid, device_id_by_jingle_sid[sid]);

                StanzaNode new_fingerprint_node = new StanzaNode.build("fingerprint", NS_URI).add_self_xmlns().put_node(enc_data.get_encrypted_node());
                string? hash_attr = fingerprint_node.get_attribute("hash", Xep.JingleIceUdp.DTLS_NS_URI);
                string? setup_attr = fingerprint_node.get_attribute("setup", Xep.JingleIceUdp.DTLS_NS_URI);
                if (hash_attr != null) new_fingerprint_node.put_attribute("hash", hash_attr);
                if (setup_attr != null) new_fingerprint_node.put_attribute("setup", setup_attr);
                transport_node.put_node(new_fingerprint_node);

                transport_node.sub_nodes.remove(fingerprint_node);
            }
        }

        private void on_message_received(XmppStream stream, Xmpp.MessageStanza message) {
            StanzaNode? proceed_node = message.stanza.get_subnode("proceed", Xep.JingleMessageInitiation.NS_URI);
            if (proceed_node == null) return;

            string? jingle_sid = proceed_node.get_attribute("id");
            if (jingle_sid == null) return;

            StanzaNode? device_node = proceed_node.get_subnode("device", NS_URI);
            if (device_node == null) return;

            int device_id = device_node.get_attribute_int("id", -1);
            if (device_id == -1) return;

            device_id_by_jingle_sid[jingle_sid] = device_id;
        }

        private void on_session_initiate_received(XmppStream stream, Xep.Jingle.Session session) {
            if (device_id_by_jingle_sid.has_key(session.sid)) {
                foreach (Xep.Jingle.Content content in session.contents) {
                    on_content_add_received(stream, content);
                }
            }
            session.additional_content_add_incoming.connect(on_content_add_received);
        }

        private void on_content_add_received(XmppStream stream, Xep.Jingle.Content content) {
            if (!content_names_by_jingle_sid.has_key(content.session.sid) || content_names_by_jingle_sid[content.session.sid].contains(content.content_name)) {
                var encryption = new OmemoContentEncryption() { encryption_ns=NS_URI, encryption_name="OMEMO", our_key=new uint8[0], peer_key=new uint8[0], sid=device_id_by_jingle_sid[content.session.sid], jid=content.peer_full_jid.bare_jid };
                content.encryptions[encryption.encryption_ns] = encryption;
            }
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Xmpp.MessageModule.IDENTITY).received_message.connect(on_message_received);
            stream.get_module(Xmpp.MessageModule.IDENTITY).send_pipeline.connect(send_listener);
            stream.get_module(Xmpp.Iq.Module.IDENTITY).preprocess_incoming_iq_set_get.connect(on_preprocess_incoming_iq_set_get);
            stream.get_module(Xmpp.Iq.Module.IDENTITY).preprocess_outgoing_iq_set_get.connect(on_preprocess_outgoing_iq_set_get);
            stream.get_module(Xep.Jingle.Module.IDENTITY).session_initiate_received.connect(on_session_initiate_received);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Xmpp.MessageModule.IDENTITY).received_message.disconnect(on_message_received);
            stream.get_module(Xmpp.MessageModule.IDENTITY).send_pipeline.disconnect(send_listener);
            stream.get_module(Xmpp.Iq.Module.IDENTITY).preprocess_incoming_iq_set_get.disconnect(on_preprocess_incoming_iq_set_get);
            stream.get_module(Xmpp.Iq.Module.IDENTITY).preprocess_outgoing_iq_set_get.disconnect(on_preprocess_outgoing_iq_set_get);
            stream.get_module(Xep.Jingle.Module.IDENTITY).session_initiate_received.disconnect(on_session_initiate_received);
        }

        public override string get_ns() { return NS_URI; }

        public override string get_id() { return IDENTITY.id; }
    }

    public class VerificationSendListener : StanzaListener<MessageStanza> {

        private const string[] after_actions_const = {};

        public override string action_group { get { return "REWRITE_NODES"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(XmppStream stream, MessageStanza message) {
            StanzaNode? proceed_node = message.stanza.get_subnode("proceed", Xep.JingleMessageInitiation.NS_URI);
            if (proceed_node == null) return false;

            StanzaNode device_node = new StanzaNode.build("device", NS_URI).add_self_xmlns()
                    .put_attribute("id", stream.get_module(Omemo.StreamModule.IDENTITY).store.local_registration_id.to_string());
            proceed_node.put_node(device_node);
            return false;
        }
    }

    public class OmemoContentEncryption : Xep.Jingle.ContentEncryption {
        public Jid jid { get; set; }
        public int sid { get; set; }
    }
}

