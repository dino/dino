using GPG;

using Xmpp.Core;

namespace Xmpp.Xep.Pgp {
    private const string NS_URI = "jabber:x";
    private const string NS_URI_ENCRYPTED = NS_URI + ":encrypted";
    private const string NS_URI_SIGNED = NS_URI +  ":signed";

    public class Module : XmppStreamModule {
        public const string ID = "0027_current_pgp_usage";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public signal void received_jid_key_id(XmppStream stream, string jid, string key_id);

        private string? signed_status;
        private string? own_key_id;

        public Module() {
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
            stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
            stream.get_module(Presence.Module.IDENTITY).pre_send_presence_stanza.connect(on_pre_send_presence_stanza);
            Message.Module.require(stream);
            stream.get_module(Message.Module.IDENTITY).pre_received_message.connect(on_pre_received_message);
            stream.add_flag(new Flag());
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
            stream.get_module(Presence.Module.IDENTITY).pre_send_presence_stanza.disconnect(on_pre_send_presence_stanza);
            stream.get_module(Message.Module.IDENTITY).pre_received_message.disconnect(on_pre_received_message);
        }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new Module());
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
            GPG.Key[] keys = new GPG.Key[key_ids.length];
            string encr;
            try {
                for (int i = 0; i < key_ids.length; i++) {
                    keys[i] = GPGHelper.get_public_key(key_ids[i]);
                }
                encr = GPGHelper.encrypt_armor(plain, keys, GPG.EncryptFlags.ALWAYS_TRUST);
            } catch (Error e) {
                return null;
            }
            int encryption_start = encr.index_of("\n\n") + 2;
            return encr.substring(encryption_start, encr.length - "\n-----END PGP MESSAGE-----".length - encryption_start);
        }

        private static string? gpg_decrypt(string enc) {
            string armor = "-----BEGIN PGP MESSAGE-----\n\n" + enc + "\n-----END PGP MESSAGE-----";
            string? decr = null;
            try {
                decr = GPGHelper.decrypt(armor);
            } catch (Error e) { }
            return decr;
        }

        private static string? gpg_verify(string sig, string signed_text) {
            string armor = "-----BEGIN PGP MESSAGE-----\n\n" + sig + "\n-----END PGP MESSAGE-----";
            string? sign_key = null;
            try {
                sign_key = GPGHelper.get_sign_key(armor, signed_text);
            } catch (Error e) { }
            return sign_key;
        }

        private static string? gpg_sign(string str) {
            string signed;
            try {
                signed = GPGHelper.sign(str, GPG.SigMode.CLEAR);
            } catch (Error e) {
                return null;
            }
            int signature_start = signed.index_of("-----BEGIN PGP SIGNATURE-----");
            signature_start = signed.index_of("\n\n", signature_start) + 2;
            return signed.substring(signature_start, signed.length - "\n-----END PGP SIGNATURE-----".length - signature_start);
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
