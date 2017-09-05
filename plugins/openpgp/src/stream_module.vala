using GPG;

using Xmpp;
using Xmpp.Core;

namespace Dino.Plugins.OpenPgp {
    private const string NS_URI = "jabber:x";
    private const string NS_URI_ENCRYPTED = NS_URI + ":encrypted";
    private const string NS_URI_SIGNED = NS_URI +  ":signed";

    public class Module : XmppStreamModule {
        public static Core.ModuleIdentity<Module> IDENTITY = new Core.ModuleIdentity<Module>(NS_URI, "0027_current_pgp_usage");

        public signal void received_jid_key_id(XmppStream stream, string jid, string key_id);

        private string? signed_status = null;
        private Key? own_key = null;

        public Module(string? own_key_id = null) {
            set_private_key_id(own_key_id);
        }

        public void set_private_key_id(string? own_key_id) {
            if (own_key_id != null) {
                try {
                    own_key = GPGHelper.get_private_key(own_key_id);
                    if (own_key == null) print("PRIV KEY NULL\n");
                } catch (Error e) { }
                if (own_key != null) {
                    signed_status = gpg_sign("", own_key);
                    get_sign_key(signed_status, "");
                }
            }
        }

        public bool encrypt(Message.Stanza message, Gee.List<string> fprs) {
            string[] encrypt_to = new string[fprs.size + 1];
            for (int i = 0; i < fprs.size; i++) encrypt_to[i] = fprs[i];
            encrypt_to[encrypt_to.length - 1] = own_key.fpr;
            string? enc_body = gpg_encrypt(message.body, encrypt_to);
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
            stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
            stream.get_module(Presence.Module.IDENTITY).pre_send_presence_stanza.connect(on_pre_send_presence_stanza);
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
        public override string get_id() { return IDENTITY.id; }

        private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
            StanzaNode x_node = presence.stanza.get_subnode("x", NS_URI_SIGNED);
            if (x_node != null) {
                string? sig = x_node.get_string_content();
                if (sig != null) {
                    string signed_data = presence.status == null ? "" : presence.status;
                    string? key_id = get_sign_key(sig, signed_data);
                    if (key_id != null) {
                        stream.get_flag(Flag.IDENTITY).set_key_id(presence.from, key_id);
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

        private static string? get_sign_key(string sig, string signed_text) {
            string armor = "-----BEGIN PGP MESSAGE-----\n\n" + sig + "\n-----END PGP MESSAGE-----";
            string? sign_key = null;
            try {
                sign_key = GPGHelper.get_sign_key(armor, signed_text);
            } catch (Error e) { }
            return sign_key;
        }

        private static string? gpg_sign(string str, Key key) {
            string signed;
            try {
                signed = GPGHelper.sign(str, GPG.SigMode.CLEAR, key);
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
