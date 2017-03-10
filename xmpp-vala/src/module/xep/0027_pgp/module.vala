using GPG;

using Xmpp.Core;

namespace Xmpp.Xep.Pgp {
    private const string NS_URI = "jabber:x";
    private const string NS_URI_ENCRYPTED = NS_URI + ":encrypted";
    private const string NS_URI_SIGNED = NS_URI +  ":signed";

    public class Module : XmppStreamModule {
        public const string ID = "0027_current_pgp_usage";

        public signal void received_jid_key_id(XmppStream stream, string jid, string key_id);

        private static Object mutex = new Object();

        private string? signed_status;
        private string? own_key_id;

        public Module() {
            GPG.check_version();
            signed_status = gpg_sign("");
            if (signed_status != null) own_key_id = gpg_verify(signed_status, "");
        }

        public bool encrypt(Message.Stanza message, string key_id) {
            string? enc_body = gpg_encrypt(message.body, new string[] {key_id, own_key_id});
            if (enc_body != null) {
                message.stanza.put_node(new StanzaNode.build("x", NS_URI_ENCRYPTED).add_self_xmlns().put_node(new StanzaNode.text(enc_body)));
                message.body = "[This message is OpenPGP encrypted (see XEP-0027)]";
                return true;
            }
            return false;
        }

        public string? get_cyphertext(Message.Stanza message) {
            StanzaNode? x_node = message.stanza.get_subnode("x", NS_URI_ENCRYPTED);
            return x_node == null ? null : x_node.get_string_content();
        }

        public override void attach(XmppStream stream) {
            Presence.Module.require(stream);
            Presence.Module.get_module(stream).received_presence.connect(on_received_presence);
            Presence.Module.get_module(stream).pre_send_presence_stanza.connect(on_pre_send_presence_stanza);
            Message.Module.require(stream);
            Message.Module.get_module(stream).pre_received_message.connect(on_pre_received_message);
            stream.add_flag(new Flag());
        }

        public override void detach(XmppStream stream) {
            Presence.Module.get_module(stream).received_presence.disconnect(on_received_presence);
            Presence.Module.get_module(stream).pre_send_presence_stanza.disconnect(on_pre_send_presence_stanza);
            Message.Module.get_module(stream).pre_received_message.disconnect(on_pre_received_message);
        }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
            StanzaNode x_node = presence.stanza.get_subnode("x", NS_URI_SIGNED);
            if (x_node != null) {
                string? sig = x_node.get_string_content();
                if (sig != null) {
                    string signed_data = presence.status == null ? "" : presence.status;
                    string? key_id = gpg_verify(sig, signed_data);
                    if (key_id != null) {
                        Flag.get_flag(stream).set_key_id(presence.from, key_id);
                        received_jid_key_id(stream, presence.from, key_id);
                    }
                }
            }
        }

        private void on_pre_send_presence_stanza(XmppStream stream, Presence.Stanza presence) {
            if (presence.type_ == Presence.Stanza.TYPE_AVAILABLE && signed_status != null) {
                presence.stanza.put_node(new StanzaNode.build("x", NS_URI_SIGNED).add_self_xmlns().put_node(new StanzaNode.text(signed_status)));
            }
        }

        private void on_pre_received_message(XmppStream stream, Message.Stanza message) {
            string? encrypted = get_cyphertext(message);
            if (encrypted != null) {
                MessageFlag flag = new MessageFlag();
                message.add_flag(flag);
                string? decrypted = gpg_decrypt(encrypted);
                if (decrypted != null) {
                    flag.decrypted = true;
                    message.body = decrypted;
                }
            }
        }

        private static string? gpg_encrypt(string plain, string[] key_ids) {
            lock (mutex) {
                GPG.Context context;
                GPGError.ErrorCode e = GPG.Context.Context(out context); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                context.set_armor(true);

                Key[] keys = new Key[key_ids.length];
                for (int i = 0; i < key_ids.length; i++) {
                    Key key;
                    e = context.get_key(key_ids[i], out key, false); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                    keys[i] = key;
                }

                GPG.Data plain_data;
                e = GPG.Data.create_from_memory(out plain_data, plain.data, false);
                GPG.Data enc_data;
                e = GPG.Data.create(out enc_data);
                e = context.op_encrypt(keys, GPG.EncryptFlags.ALWAYS_TRUST, plain_data, enc_data);

                string encr = get_string_from_data(enc_data);
                int encryption_start = encr.index_of("\n\n") + 2;
                return encr.substring(encryption_start, encr.length - "\n-----END PGP MESSAGE-----".length - encryption_start);
            }
        }

        private static string? gpg_decrypt(string enc) {
            lock (mutex) {
                string armor = "-----BEGIN PGP MESSAGE-----\n\n" + enc + "\n-----END PGP MESSAGE-----";

                GPG.Data enc_data;
                GPGError.ErrorCode e = GPG.Data.create_from_memory(out enc_data, armor.data, false); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Data dec_data;
                e = GPG.Data.create(out dec_data); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Context context;
                e = GPG.Context.Context(out context); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                e = context.op_decrypt(enc_data, dec_data); if (e != GPGError.ErrorCode.NO_ERROR) return null;

                string plain = get_string_from_data(dec_data);
                return plain;
            }
        }

        private static string? gpg_verify(string sig, string signed_text) {
            lock (mutex) {
                string armor = "-----BEGIN PGP MESSAGE-----\n\n" + sig + "\n-----END PGP MESSAGE-----";

                GPG.Data sig_data;
                GPGError.ErrorCode e = GPG.Data.create_from_memory(out sig_data, armor.data, false); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Data plain_data;
                e = GPG.Data.create(out plain_data); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Context context;
                e = GPG.Context.Context(out context); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                e = context.op_verify(sig_data, null, plain_data); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.VerifyResult* verify_res = context.op_verify_result();
                if (verify_res == null || verify_res.signatures == null) return null;
                return verify_res.signatures.fpr;
            }
        }

        private static string? gpg_sign(string status) {
            lock (mutex) {
                GPG.Data status_data;
                GPGError.ErrorCode e = GPG.Data.create_from_memory(out status_data, status.data, false); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Data signed_data;
                e = GPG.Data.create(out signed_data); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                GPG.Context context;
                e = GPG.Context.Context(out context); if (e != GPGError.ErrorCode.NO_ERROR) return null;
                e = context.op_sign(status_data, signed_data, GPG.SigMode.CLEAR); if (e != GPGError.ErrorCode.NO_ERROR) return null;

                string signed = get_string_from_data(signed_data);
                int signature_start = signed.index_of("-----BEGIN PGP SIGNATURE-----");
                signature_start = signed.index_of("\n\n", signature_start) + 2;
                return signed.substring(signature_start, signed.length - "\n-----END PGP SIGNATURE-----".length - signature_start);
            }
        }

        private static string get_string_from_data(GPG.Data data) {
            data.seek(0);
            uint8[] buf = new uint8[256];
            ssize_t? len = null;
            string res = "";
            do {
                len = data.read(buf);
                if (len > 0) {
                    string part = (string) buf;
                    part = part.substring(0, (long) len);
                    res += part;
                }
            } while (len > 0);
            return res;
        }
    }

    public class MessageFlag : Message.MessageFlag {
        public const string id = "pgp";

        public bool decrypted = false;

        public static MessageFlag? get_flag(Message.Stanza message) {
            return (MessageFlag) message.get_flag(NS_URI, id);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return id; }
    }
}
