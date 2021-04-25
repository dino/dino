using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Omemo {

    public abstract class OmemoDecryptor : XmppStreamModule {

        public static Xmpp.ModuleIdentity<OmemoDecryptor> IDENTITY = new Xmpp.ModuleIdentity<OmemoDecryptor>(NS_URI, "0384_omemo_decryptor");

        public abstract uint32 own_device_id { get; }

        public abstract string decrypt(uint8[] ciphertext, uint8[] key, uint8[] iv) throws GLib.Error;

        public abstract uint8[] decrypt_key(ParsedData data, Jid from_jid) throws GLib.Error;

        public ParsedData? parse_node(StanzaNode encrypted_node) {
            ParsedData ret = new ParsedData();

            StanzaNode? header_node = encrypted_node.get_subnode("header");
            if (header_node == null) return null;

            ret.sid = header_node.get_attribute_int("sid", -1);
            if (ret.sid == -1) return null;

            string? payload_str = encrypted_node.get_deep_string_content("payload");
            if (payload_str != null) ret.ciphertext = Base64.decode(payload_str);

            string? iv_str = header_node.get_deep_string_content("iv");
            if (iv_str == null) return null;
            ret.iv = Base64.decode(iv_str);

            foreach (StanzaNode key_node in header_node.get_subnodes("key")) {
                debug("Is ours? %d =? %u", key_node.get_attribute_int("rid"), own_device_id);
                if (key_node.get_attribute_int("rid") == own_device_id) {
                    string? key_node_content = key_node.get_string_content();
                    if (key_node_content == null) continue;
                    uchar[] encrypted_key = Base64.decode(key_node_content);
                    ret.our_potential_encrypted_keys[new Bytes.take(encrypted_key)] = key_node.get_attribute_bool("prekey");
                }
            }

            return ret;
        }

        public override void attach(XmppStream stream) { }
        public override void detach(XmppStream stream) { }
        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    public class ParsedData {
        public int sid;
        public uint8[] ciphertext;
        public uint8[] iv;
        public uchar[] encrypted_key;
        public bool is_prekey;

        public HashMap<Bytes, bool> our_potential_encrypted_keys = new HashMap<Bytes, bool>();
    }
}

