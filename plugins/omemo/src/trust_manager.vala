using Dino.Entities;
using Gee;
using Xmpp;
using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

public class TrustManager {

    private StreamInteractor stream_interactor;
    private Database db;
    private ReceivedMessageListener received_message_listener;

    public TrustManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        received_message_listener = new ReceivedMessageListener(stream_interactor, db);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
    }

    public void set_blind_trust(Account account, Jid jid, bool blind_trust) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;
        db.trust.update()
            .with(db.trust.identity_id, "=", identity_id)
            .with(db.trust.address_name, "=", jid.bare_jid.to_string())
            .set(db.trust.blind_trust, blind_trust).perform();
    }

    public void set_device_trust(Account account, Jid jid, int device_id, Database.IdentityMetaTable.TrustLevel trust_level) {
        int identity_id = db.identity.get_id(account.id);
        db.identity_meta.update()
            .with(db.identity_meta.identity_id, "=", identity_id)
            .with(db.identity_meta.address_name, "=", jid.bare_jid.to_string())
            .with(db.identity_meta.device_id, "=", device_id)
            .set(db.identity_meta.trust_level, trust_level).perform();
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
            //Check we have the bundles and device lists needed to send the message
            if (!is_known_address(account, self_jid)) return status;
            status.own_list = true;
            status.own_devices = get_trusted_devices(account, self_jid).size;
            status.other_waiting_lists = 0;
            status.other_devices = 0;
            foreach (Jid recipient in recipients) {
                if (!is_known_address(account, recipient)) {
                    status.other_waiting_lists++;
                }
                if (status.other_waiting_lists > 0) return status;
                status.other_devices += get_trusted_devices(account, recipient).size;
            }
            if (status.own_devices == 0 || status.other_devices == 0) return status;

            //Create a key and use it to encrypt the message
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

            //Encrypt the key for each recipient's device individually
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
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return false;
        return db.identity_meta.with_address(identity_id, jid.to_string()).count() > 0;
    }

    public Gee.List<int32> get_trusted_devices(Account account, Jid jid) {
        Gee.List<int32> devices = new ArrayList<int32>();
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return devices;
        foreach (Row device in db.identity_meta.get_trusted_devices(identity_id, jid.bare_jid.to_string())) {
            if(device[db.identity_meta.trust_level] != Database.IdentityMetaTable.TrustLevel.UNKNOWN || device[db.identity_meta.identity_key_public_base64] == null)
                devices.add(device[db.identity_meta.device_id]);
        }
        return devices;
    }

    private class ReceivedMessageListener : MessageListener {
        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;
        private Database db;

        public ReceivedMessageListener(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            Store store = stream_interactor.module_manager.get_module(conversation.account, StreamModule.IDENTITY).store;

            StanzaNode? _encrypted = stanza.stanza.get_subnode("encrypted", NS_URI);
            if (_encrypted == null || MessageFlag.get_flag(stanza) != null || stanza.from == null) return false;
            StanzaNode encrypted = (!)_encrypted;
            if (!Plugin.ensure_context()) return false;
            MessageFlag flag = new MessageFlag();
            stanza.add_flag(flag);
            StanzaNode? _header = encrypted.get_subnode("header");
            if (_header == null) return false;
            StanzaNode header = (!)_header;
            if (header.get_attribute_int("sid") <= 0) return false;
            foreach (StanzaNode key_node in header.get_subnodes("key")) {
                if (key_node.get_attribute_int("rid") == store.local_registration_id) {
                    try {
                        string? payload = encrypted.get_deep_string_content("payload");
                        string? iv_node = header.get_deep_string_content("iv");
                        string? key_node_content = key_node.get_string_content();
                        if (payload == null || iv_node == null || key_node_content == null) continue;
                        uint8[] key;
                        uint8[] ciphertext = Base64.decode((!)payload);
                        uint8[] iv = Base64.decode((!)iv_node);
                        Jid jid = stanza.from;
                        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                            jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(jid, conversation.account);
                        }

                        Address address = new Address(jid.bare_jid.to_string(), header.get_attribute_int("sid"));
                        if (key_node.get_attribute_bool("prekey")) {
                            PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(Base64.decode((!)key_node_content));
                            SessionCipher cipher = store.create_session_cipher(address);
                            key = cipher.decrypt_pre_key_signal_message(msg);
                        } else {
                            SignalMessage msg = Plugin.get_context().deserialize_signal_message(Base64.decode((!)key_node_content));
                            SessionCipher cipher = store.create_session_cipher(address);
                            key = cipher.decrypt_signal_message(msg);
                        }   
                        address.device_id = 0; // TODO: Hack to have address obj live longer

                        if (key.length >= 32) {
                            int authtaglength = key.length - 16; 
                            uint8[] new_ciphertext = new uint8[ciphertext.length + authtaglength];
                            uint8[] new_key = new uint8[16];
                            Memory.copy(new_ciphertext, ciphertext, ciphertext.length);
                            Memory.copy((uint8*)new_ciphertext + ciphertext.length, (uint8*)key + 16, authtaglength);
                            Memory.copy(new_key, key, 16);
                            ciphertext = new_ciphertext;
                            key = new_key;
                        }

                        message.body = arr_to_str(aes_decrypt(Cipher.AES_GCM_NOPADDING, key, iv, ciphertext));
                        flag.decrypted = true;

                        int identity_id = db.identity.get_id(conversation.account.id);
                        if (identity_id < 0) return false;

                        Database.IdentityMetaTable.TrustLevel trust_level = (Database.IdentityMetaTable.TrustLevel) db.identity_meta.get_device(identity_id, jid.bare_jid.to_string(), header.get_attribute_int("sid"))[db.identity_meta.trust_level];
                        if (trust_level == Database.IdentityMetaTable.TrustLevel.UNTRUSTED) {
                            message.body = _("OMEMO message from a rejected device");
                            message.marked = Message.Marked.WONTSEND;
                        }
                        if (trust_level == Database.IdentityMetaTable.TrustLevel.UNKNOWN) {
                            message.body = _("OMEMO message from an unknown device: ")+message.body;
                            message.marked = Message.Marked.WONTSEND;
                        }
                    } catch (Error e) {
                        if (Plugin.DEBUG) print(@"OMEMO: Signal error while decrypting message: $(e.message)\n");
                    }
                }
            }
            return false;
        }

        private string arr_to_str(uint8[] arr) {
            // null-terminate the array
            uint8[] rarr = new uint8[arr.length+1];
            Memory.copy(rarr, arr, arr.length);
            return (string)rarr;
        }
    }
}

}
