using Dino.Entities;
using Gee;
using Xmpp;
using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

public class TrustManager {

    private StreamInteractor stream_interactor;
    private Database db;

    public TrustManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
    }

    private StanzaNode create_encrypted_key(uint8[] key, Address address, Store store) throws GLib.Error {
        SessionCipher cipher = store.create_session_cipher(address);
        CiphertextMessage device_key = cipher.encrypt(key);
        StanzaNode key_node = new StanzaNode.build("key", NS_URI)
            .put_attribute("rid", address.device_id.to_string())
            .put_node(new StanzaNode.text(Base64.encode(device_key.serialized)));
        if (device_key.type == CiphertextType.PREKEY) key_node.put_attribute("prekey", "true");
        return key_node;
    }

    public EncryptState encrypt(MessageStanza message, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream, Account account) {
        EncryptState status = new EncryptState();
        if (!Plugin.ensure_context()) return status;
        if (message.to == null) return status;

        StreamModule module = stream.get_module(StreamModule.IDENTITY);

        try {
            if (!is_known_address(account, self_jid)) return status;
            status.own_list = true;
            status.own_devices = get_trusted_devices(account, self_jid).size;
            status.other_waiting_lists = 0;
            status.other_devices = 0;
            foreach (Jid recipient in recipients) {
                if (!is_known_address(account, recipient)) {
                    status.other_waiting_lists++;
                    return status;
                }
                status.other_devices += get_trusted_devices(account, recipient).size;
            }
            if (status.own_devices == 0 || status.other_devices == 0) return status;

            uint8[] key = new uint8[16];
            Plugin.get_context().randomize(key);
            uint8[] iv = new uint8[16];
            Plugin.get_context().randomize(iv);

            uint8[] ciphertext = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, message.body.data);

            StanzaNode header;
            StanzaNode encrypted = new StanzaNode.build("encrypted", NS_URI).add_self_xmlns()
                    .put_node(header = new StanzaNode.build("header", NS_URI)
                        .put_attribute("sid", module.store.local_registration_id.to_string())
                        .put_node(new StanzaNode.build("iv", NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(iv)))))
                    .put_node(new StanzaNode.build("payload", NS_URI)
                        .put_node(new StanzaNode.text(Base64.encode(ciphertext))));

            Address address = new Address(message.to.bare_jid.to_string(), 0);
            foreach (Jid recipient in recipients) {
                foreach(int32 device_id in get_trusted_devices(account, recipient)) {
                    if (module.is_ignored_device(recipient, device_id)) {
                        status.other_lost++;
                        continue;
                    }
                    try {
                        address.name = recipient.bare_jid.to_string();
                        address.device_id = (int) device_id;
                        StanzaNode key_node = create_encrypted_key(key, address, module.store);
                        header.put_node(key_node);
                        status.other_success++;
                    } catch (Error e) {
                        if (e.code == ErrorCode.UNKNOWN) status.other_unknown++;
                        else status.other_failure++;
                    }
                }
            }
            address.name = self_jid.bare_jid.to_string();
            foreach(int32 device_id in get_trusted_devices(account, self_jid)) {
                if (module.is_ignored_device(self_jid, device_id)) {
                    status.own_lost++;
                    continue;
                }
                if (device_id != module.store.local_registration_id) {
                    address.device_id = (int) device_id;
                    try {
                        StanzaNode key_node = create_encrypted_key(key, address, module.store);
                        header.put_node(key_node);
                        status.own_success++;
                    } catch (Error e) {
                        if (e.code == ErrorCode.UNKNOWN) status.own_unknown++;
                        else status.own_failure++;
                    }
                }
            }

            message.stanza.put_node(encrypted);
            Xep.ExplicitEncryption.add_encryption_tag_to_message(message, NS_URI, "OMEMO");
            message.body = "[This message is OMEMO encrypted]";
            status.encrypted = true;
        } catch (Error e) {
            if (Plugin.DEBUG) print(@"OMEMO: Signal error while encrypting message: $(e.message)\n");
        }
        return status;
    }

    public bool is_known_address(Account account, Jid jid) {
        return db.identity_meta.with_address(account.id, jid.to_string()).count() > 0;
    }

    public Gee.List<int32> get_trusted_devices(Account account, Jid jid) {
        Gee.List<int32> devices = new ArrayList<int32>();
        foreach (Row device in db.identity_meta.with_address(account.id, jid.to_string()).with(db.identity_meta.trust_level, "!=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).with(db.identity_meta.trust_level, "!=", Database.IdentityMetaTable.TrustLevel.UNTRUSTED).without_null(db.identity_meta.identity_key_public_base64)) {
            devices.add(device[db.identity_meta.device_id]);
        }
        return devices;
    }
}

}
