using Gee;
using Omemo;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep.Omemo;

namespace Dino.Plugins.Omemo {

    public class OmemoEncryptor : Xep.Omemo.OmemoEncryptor {

        private Account account;
        private Store store;
        private TrustManager trust_manager;

        public override uint32 own_device_id { get { return store.local_registration_id; }}

        public OmemoEncryptor(Account account, TrustManager trust_manager, Store store) {
            this.account = account;
            this.trust_manager = trust_manager;
            this.store = store;
        }

        public override Xep.Omemo.EncryptionData encrypt_plaintext(string plaintext) throws GLib.Error {
            const uint KEY_SIZE = 16;
            const uint IV_SIZE = 12;

            //Create a key and use it to encrypt the message
            uint8[] key = new uint8[KEY_SIZE];
            Plugin.get_context().randomize(key);
            uint8[] iv = new uint8[IV_SIZE];
            Plugin.get_context().randomize(iv);

            uint8[] aes_encrypt_result = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, plaintext.data);
            uint8[] ciphertext = aes_encrypt_result[0:aes_encrypt_result.length - 16];
            uint8[] tag = aes_encrypt_result[aes_encrypt_result.length - 16:aes_encrypt_result.length];
            uint8[] keytag = new uint8[key.length + tag.length];
            Memory.copy(keytag, key, key.length);
            Memory.copy((uint8*)keytag + key.length, tag, tag.length);

            var ret = new Xep.Omemo.EncryptionData(own_device_id);
            ret.ciphertext = ciphertext;
            ret.keytag = keytag;
            ret.iv = iv;
            return ret;
        }

        public EncryptState encrypt(MessageStanza message, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream) {

            EncryptState status = new EncryptState();
            if (!Plugin.ensure_context()) return status;
            if (message.to == null) return status;

            try {
                EncryptionData enc_data = encrypt_plaintext(message.body);
                status = encrypt_key_to_recipients(enc_data, self_jid, recipients, stream);

                message.stanza.put_node(enc_data.get_encrypted_node());
                Xep.ExplicitEncryption.add_encryption_tag_to_message(message, NS_URI, "OMEMO");
                message.body = "[This message is OMEMO encrypted]";
                status.encrypted = true;
            } catch (Error e) {
                warning(@"error while encrypting message: $(e.message)\n");
                message.body = "[OMEMO encryption failed]";
                status.encrypted = false;
            }
            return status;
        }

        internal EncryptState encrypt_key_to_recipients(EncryptionData enc_data, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream) throws Error {
            EncryptState status = new EncryptState();

            //Check we have the bundles and device lists needed to send the message
            if (!trust_manager.is_known_address(account, self_jid)) return status;
            status.own_list = true;
            status.own_devices = trust_manager.get_trusted_devices(account, self_jid).size;
            status.other_waiting_lists = 0;
            status.other_devices = 0;
            foreach (Jid recipient in recipients) {
                if (!trust_manager.is_known_address(account, recipient)) {
                    status.other_waiting_lists++;
                }
                if (status.other_waiting_lists > 0) return status;
                status.other_devices += trust_manager.get_trusted_devices(account, recipient).size;
            }
            if (status.own_devices == 0 || status.other_devices == 0) return status;


            //Encrypt the key for each recipient's device individually
            foreach (Jid recipient in recipients) {
                EncryptionResult enc_res = encrypt_key_to_recipient(stream, enc_data, recipient);
                status.add_result(enc_res, false);
            }

            // Encrypt the key for each own device
            EncryptionResult enc_res = encrypt_key_to_recipient(stream, enc_data, self_jid);
            status.add_result(enc_res, true);

            return status;
        }

        public override EncryptionResult encrypt_key_to_recipient(XmppStream stream, Xep.Omemo.EncryptionData enc_data, Jid recipient) throws GLib.Error {
            var result = new EncryptionResult();
            StreamModule module = stream.get_module(StreamModule.IDENTITY);

            foreach(int32 device_id in trust_manager.get_trusted_devices(account, recipient)) {
                if (module.is_ignored_device(recipient, device_id)) {
                    result.lost++;
                    continue;
                }
                try {
                    encrypt_key(enc_data, recipient, device_id);
                    result.success++;
                } catch (Error e) {
                    if (e.code == ErrorCode.UNKNOWN) result.unknown++;
                    else result.failure++;
                }
            }
            return result;
        }

        public override void encrypt_key(Xep.Omemo.EncryptionData encryption_data, Jid jid, int32 device_id) throws GLib.Error {
            Address address = new Address(jid.to_string(), device_id);
            SessionCipher cipher = store.create_session_cipher(address);
            CiphertextMessage device_key = cipher.encrypt(encryption_data.keytag);
            address.device_id = 0;
            debug("Created encrypted key for %s/%d", jid.to_string(), device_id);

            encryption_data.add_device_key(device_id, device_key.serialized, device_key.type == CiphertextType.PREKEY);
        }
    }
}