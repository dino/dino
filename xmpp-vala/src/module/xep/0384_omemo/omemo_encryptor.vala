using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Omemo {

    public const string NS_URI = "eu.siacs.conversations.axolotl";
    public const string NODE_DEVICELIST = NS_URI + ".devicelist";
    public const string NODE_BUNDLES = NS_URI + ".bundles";
    public const string NODE_VERIFICATION = NS_URI + ".verification";

    public abstract class OmemoEncryptor : XmppStreamModule {

        public static Xmpp.ModuleIdentity<OmemoEncryptor> IDENTITY = new Xmpp.ModuleIdentity<OmemoEncryptor>(NS_URI, "0384_omemo_encryptor");

        public abstract uint32 own_device_id { get; }

        public abstract EncryptionData encrypt_plaintext(string plaintext) throws GLib.Error;

        public abstract void encrypt_key(Xep.Omemo.EncryptionData encryption_data, Jid jid, int32 device_id) throws GLib.Error;

        public abstract EncryptionResult encrypt_key_to_recipient(XmppStream stream, Xep.Omemo.EncryptionData enc_data, Jid recipient) throws GLib.Error;

        public override void attach(XmppStream stream) { }
        public override void detach(XmppStream stream) { }
        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    public class EncryptionData {
        public uint32 own_device_id;
        public uint8[] ciphertext;
        public uint8[] keytag;
        public uint8[] iv;

        public Gee.List<StanzaNode> key_nodes = new ArrayList<StanzaNode>();

        public EncryptionData(uint32 own_device_id) {
            this.own_device_id = own_device_id;
        }

        public void add_device_key(int device_id, uint8[] device_key, bool prekey) {
            StanzaNode key_node = new StanzaNode.build("key", NS_URI)
                    .put_attribute("rid", device_id.to_string())
                    .put_node(new StanzaNode.text(Base64.encode(device_key)));
            if (prekey) {
                key_node.put_attribute("prekey", "true");
            }
            key_nodes.add(key_node);
        }

        public StanzaNode get_encrypted_node() {
            StanzaNode encrypted_node = new StanzaNode.build("encrypted", NS_URI).add_self_xmlns();

            StanzaNode header_node = new StanzaNode.build("header", NS_URI)
                    .put_attribute("sid", own_device_id.to_string())
                    .put_node(new StanzaNode.build("iv", NS_URI).put_node(new StanzaNode.text(Base64.encode(iv))));
            encrypted_node.put_node(header_node);

            if (ciphertext != null) {
                StanzaNode payload_node = new StanzaNode.build("payload", NS_URI)
                        .put_node(new StanzaNode.text(Base64.encode(ciphertext)));
                encrypted_node.put_node(payload_node);
            }

            foreach (StanzaNode key_node in key_nodes) {
                header_node.put_node(key_node);
            }

            return encrypted_node;
        }
    }

    public class EncryptionResult {
        public int lost { get; set; }
        public int success { get; set; }
        public int unknown { get; set; }
        public int failure { get; set; }
    }

    public class EncryptState {
        public bool encrypted { get; set; }
        public int other_devices { get; set; }
        public int other_success { get; set; }
        public int other_lost { get; set; }
        public int other_unknown { get; set; }
        public int other_failure { get; set; }
        public int other_waiting_lists { get; set; }

        public int own_devices { get; set; }
        public int own_success { get; set; }
        public int own_lost { get; set; }
        public int own_unknown { get; set; }
        public int own_failure { get; set; }
        public bool own_list { get; set; }

        public void add_result(EncryptionResult enc_res, bool own) {
            if (own) {
                own_lost += enc_res.lost;
                own_success += enc_res.success;
                own_unknown += enc_res.unknown;
                own_failure += enc_res.failure;
            } else {
                other_lost += enc_res.lost;
                other_success += enc_res.success;
                other_unknown += enc_res.unknown;
                other_failure += enc_res.failure;
            }
        }

        public string to_string() {
            return @"EncryptState (encrypted=$encrypted, other=(devices=$other_devices, success=$other_success, lost=$other_lost, unknown=$other_unknown, failure=$other_failure, waiting_lists=$other_waiting_lists, own=(devices=$own_devices, success=$own_success, lost=$own_lost, unknown=$own_unknown, failure=$own_failure, list=$own_list))";
        }
    }
}

