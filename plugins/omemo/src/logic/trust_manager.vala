using Dino.Entities;
using Gee;
using Xmpp;
using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

public class TrustManager {

    public signal void bad_message_state_updated(Account account, Jid jid, int device_id);

    private StreamInteractor stream_interactor;
    private Database db;
    private DecryptMessageListener decrypt_message_listener;
    private TagMessageListener tag_message_listener;

    private HashMap<Message, int> message_device_id_map = new HashMap<Message, int>(Message.hash_func, Message.equals_func);

    public TrustManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        decrypt_message_listener = new DecryptMessageListener(stream_interactor, this, db, message_device_id_map);
        tag_message_listener = new TagMessageListener(stream_interactor, this, db, message_device_id_map);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(decrypt_message_listener);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(tag_message_listener);
    }

    public void set_blind_trust(Account account, Jid jid, bool blind_trust) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;
        db.trust.update()
            .with(db.trust.identity_id, "=", identity_id)
            .with(db.trust.address_name, "=", jid.bare_jid.to_string())
            .set(db.trust.blind_trust, blind_trust).perform();
    }

    public void set_device_trust(Account account, Jid jid, int device_id, TrustLevel trust_level) {
        int identity_id = db.identity.get_id(account.id);
        db.identity_meta.update()
            .with(db.identity_meta.identity_id, "=", identity_id)
            .with(db.identity_meta.address_name, "=", jid.bare_jid.to_string())
            .with(db.identity_meta.device_id, "=", device_id)
            .set(db.identity_meta.trust_level, trust_level).perform();

        // Hide messages from untrusted or unknown devices
        string selection = null;
        string[] selection_args = {};
        var app_db = Application.get_default().db;
        foreach (Row row in db.content_item_meta.with_device(identity_id, jid.bare_jid.to_string(), device_id).with(db.content_item_meta.trusted_when_received, "=", false)) {
            if (selection == null) {
                selection = @"$(app_db.content_item.id) = ?";
            } else {
                selection += @" OR $(app_db.content_item.id) = ?";
            }
            selection_args += row[db.content_item_meta.content_item_id].to_string();
        }
        if (selection != null) {
            app_db.content_item.update()
                .set(app_db.content_item.hide, trust_level == TrustLevel.UNTRUSTED || trust_level == TrustLevel.UNKNOWN)
                .where(selection, selection_args)
                .perform();
        }

        if (trust_level == TrustLevel.TRUSTED) {
            db.identity_meta.update_last_message_untrusted(identity_id, device_id, null);
            bad_message_state_updated(account, jid, device_id);
        }
    }

    private StanzaNode create_encrypted_key_node(uint8[] key, Address address, Store store) throws GLib.Error {
        SessionCipher cipher = store.create_session_cipher(address);
        CiphertextMessage device_key = cipher.encrypt(key);
        debug("Created encrypted key for %s/%d", address.name, address.device_id);
        StanzaNode key_node = new StanzaNode.build("key", NS_URI)
            .put_attribute("rid", address.device_id.to_string())
            .put_node(new StanzaNode.text(Base64.encode(device_key.serialized)));
        if (device_key.type == CiphertextType.PREKEY) key_node.put_attribute("prekey", "true");
        return key_node;
    }

    internal EncryptState encrypt_key(StanzaNode header_node, uint8[] keytag, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream, Account account) throws Error {
        EncryptState status = new EncryptState();
        StreamModule module = stream.get_module(StreamModule.IDENTITY);

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


        //Encrypt the key for each recipient's device individually
        Address address = new Address("", 0);
        foreach (Jid recipient in recipients) {
            foreach(int32 device_id in get_trusted_devices(account, recipient)) {
                if (module.is_ignored_device(recipient, device_id)) {
                    status.other_lost++;
                    continue;
                }
                try {
                    address.name = recipient.bare_jid.to_string();
                    address.device_id = (int) device_id;
                    StanzaNode key_node = create_encrypted_key_node(keytag, address, module.store);
                    header_node.put_node(key_node);
                    status.other_success++;
                } catch (Error e) {
                    if (e.code == ErrorCode.UNKNOWN) status.other_unknown++;
                    else status.other_failure++;
                }
            }
        }

        // Encrypt the key for each own device
        address.name = self_jid.bare_jid.to_string();
        foreach(int32 device_id in get_trusted_devices(account, self_jid)) {
            if (module.is_ignored_device(self_jid, device_id)) {
                status.own_lost++;
                continue;
            }
            if (device_id != module.store.local_registration_id) {
                address.device_id = (int) device_id;
                try {
                    StanzaNode key_node = create_encrypted_key_node(keytag, address, module.store);
                    header_node.put_node(key_node);
                    status.own_success++;
                } catch (Error e) {
                    if (e.code == ErrorCode.UNKNOWN) status.own_unknown++;
                    else status.own_failure++;
                }
            }
        }

        return status;
    }

    public EncryptState encrypt(MessageStanza message, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream, Account account) {
        EncryptState status = new EncryptState();
        if (!Plugin.ensure_context()) return status;
        if (message.to == null) return status;

        StreamModule module = stream.get_module(StreamModule.IDENTITY);

        try {
            //Create a key and use it to encrypt the message
            uint8[] key = new uint8[16];
            Plugin.get_context().randomize(key);
            uint8[] iv = new uint8[16];
            Plugin.get_context().randomize(iv);

            uint8[] aes_encrypt_result = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, message.body.data);
            uint8[] ciphertext = aes_encrypt_result[0:aes_encrypt_result.length-16];
            uint8[] tag = aes_encrypt_result[aes_encrypt_result.length-16:aes_encrypt_result.length];
            uint8[] keytag = new uint8[key.length + tag.length];
            Memory.copy(keytag, key, key.length);
            Memory.copy((uint8*)keytag + key.length, tag, tag.length);

            StanzaNode header_node;
            StanzaNode encrypted_node = new StanzaNode.build("encrypted", NS_URI).add_self_xmlns()
                    .put_node(header_node = new StanzaNode.build("header", NS_URI)
                        .put_attribute("sid", module.store.local_registration_id.to_string())
                        .put_node(new StanzaNode.build("iv", NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(iv)))))
                    .put_node(new StanzaNode.build("payload", NS_URI)
                        .put_node(new StanzaNode.text(Base64.encode(ciphertext))));

            status = encrypt_key(header_node, keytag, self_jid, recipients, stream, account);

            message.stanza.put_node(encrypted_node);
            Xep.ExplicitEncryption.add_encryption_tag_to_message(message, NS_URI, "OMEMO");
            message.body = "[This message is OMEMO encrypted]";
            status.encrypted = true;
        } catch (Error e) {
            warning(@"Signal error while encrypting message: $(e.message)\n");
            message.body = "[OMEMO encryption failed]";
            status.encrypted = false;
        }
        return status;
    }

    public bool is_known_address(Account account, Jid jid) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return false;
        return db.identity_meta.with_address(identity_id, jid.to_string()).with(db.identity_meta.last_active, ">", 0).count() > 0;
    }

    public Gee.List<int32> get_trusted_devices(Account account, Jid jid) {
        Gee.List<int32> devices = new ArrayList<int32>();
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return devices;
        foreach (Row device in db.identity_meta.get_trusted_devices(identity_id, jid.bare_jid.to_string())) {
            if(device[db.identity_meta.trust_level] != TrustLevel.UNKNOWN || device[db.identity_meta.identity_key_public_base64] == null)
                devices.add(device[db.identity_meta.device_id]);
        }
        return devices;
    }

    private class TagMessageListener : MessageListener {
        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "DECRYPT_TAG"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;
        private TrustManager trust_manager;
        private Database db;
        private HashMap<Message, int> message_device_id_map;

        public TagMessageListener(StreamInteractor stream_interactor, TrustManager trust_manager, Database db, HashMap<Message, int> message_device_id_map) {
            this.stream_interactor = stream_interactor;
            this.trust_manager = trust_manager;
            this.db = db;
            this.message_device_id_map = message_device_id_map;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            int device_id = 0;
            if (message_device_id_map.has_key(message)) {
                device_id = message_device_id_map[message];
                message_device_id_map.unset(message);
            }

            // TODO: Handling of files

            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);

            if (content_item != null && device_id != 0) {
                Jid jid = content_item.jid;
                if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    jid = message.real_jid;
                }

                int identity_id = db.identity.get_id(conversation.account.id);
                TrustLevel trust_level = (TrustLevel) db.identity_meta.get_device(identity_id, jid.bare_jid.to_string(), device_id)[db.identity_meta.trust_level];
                if (trust_level == TrustLevel.UNTRUSTED || trust_level == TrustLevel.UNKNOWN) {
                    stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
                    db.identity_meta.update_last_message_untrusted(identity_id, device_id, message.time);
                    trust_manager.bad_message_state_updated(conversation.account, jid, device_id);
                }

                db.content_item_meta.insert()
                    .value(db.content_item_meta.content_item_id, content_item.id)
                    .value(db.content_item_meta.identity_id, identity_id)
                    .value(db.content_item_meta.address_name, jid.bare_jid.to_string())
                    .value(db.content_item_meta.device_id, device_id)
                    .value(db.content_item_meta.trusted_when_received, trust_level != TrustLevel.UNTRUSTED)
                    .perform();
            }
            return false;
        }
    }

    private class DecryptMessageListener : MessageListener {
        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;
        private TrustManager trust_manager;
        private Database db;
        private HashMap<Message, int> message_device_id_map;

        public DecryptMessageListener(StreamInteractor stream_interactor, TrustManager trust_manager, Database db, HashMap<Message, int> message_device_id_map) {
            this.stream_interactor = stream_interactor;
            this.trust_manager = trust_manager;
            this.db = db;
            this.message_device_id_map = message_device_id_map;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            StreamModule module = stream_interactor.module_manager.get_module(conversation.account, StreamModule.IDENTITY);
            Store store = module.store;

            StanzaNode? _encrypted = stanza.stanza.get_subnode("encrypted", NS_URI);
            if (_encrypted == null || MessageFlag.get_flag(stanza) != null || stanza.from == null) return false;
            StanzaNode encrypted = (!)_encrypted;
            if (message.body == null && Xep.ExplicitEncryption.get_encryption_tag(stanza) == NS_URI) {
                message.body = "[This message is OMEMO encrypted]"; // TODO temporary
            };
            if (!Plugin.ensure_context()) return false;
            int identity_id = db.identity.get_id(conversation.account.id);
            MessageFlag flag = new MessageFlag();
            stanza.add_flag(flag);
            StanzaNode? _header = encrypted.get_subnode("header");
            if (_header == null) return false;
            StanzaNode header = (!)_header;
            int sid = header.get_attribute_int("sid");
            if (sid <= 0) return false;

            var our_nodes = new ArrayList<StanzaNode>();
            foreach (StanzaNode key_node in header.get_subnodes("key")) {
                debug("Is ours? %d =? %u", key_node.get_attribute_int("rid"), store.local_registration_id);
                if (key_node.get_attribute_int("rid") == store.local_registration_id) {
                    our_nodes.add(key_node);
                }
            }

            foreach (StanzaNode key_node in our_nodes) {
                string? payload = encrypted.get_deep_string_content("payload");
                string? iv_node = header.get_deep_string_content("iv");
                string? key_node_content = key_node.get_string_content();
                if (payload == null || iv_node == null || key_node_content == null) continue;
                uint8[] key;
                uint8[] ciphertext = Base64.decode((!)payload);
                uint8[] iv = Base64.decode((!)iv_node);
                Gee.List<Jid> possible_jids = new ArrayList<Jid>();
                if (conversation.type_ == Conversation.Type.CHAT) {
                    possible_jids.add(stanza.from.bare_jid);
                } else {
                    Jid? real_jid = message.real_jid;
                    if (real_jid != null) {
                        possible_jids.add(real_jid.bare_jid);
                    } else if (key_node.get_attribute_bool("prekey")) {
                        // pre key messages do store the identity key, so we can use that to find the real jid
                        PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(Base64.decode((!)key_node_content));
                        string identity_key = Base64.encode(msg.identity_key.serialize());
                        foreach (Row row in db.identity_meta.get_with_device_id(identity_id, sid).with(db.identity_meta.identity_key_public_base64, "=", identity_key)) {
                            try {
                                possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                            } catch (InvalidJidError e) {
                                warning("Ignoring invalid jid from database: %s", e.message);
                            }
                        }
                        if (possible_jids.size != 1) {
                            continue;
                        }
                    } else {
                        // If we don't know the device name (MUC history w/o MAM), test decryption with all keys with fitting device id
                        foreach (Row row in db.identity_meta.get_with_device_id(identity_id, sid)) {
                            try {
                                possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                            } catch (InvalidJidError e) {
                                warning("Ignoring invalid jid from database: %s", e.message);
                            }
                        }
                    }
                }

                if (possible_jids.size == 0) {
                    debug("Received message from unknown entity with device id %d", sid);
                }

                foreach (Jid possible_jid in possible_jids) {
                    try {
                        Address address = new Address(possible_jid.to_string(), sid);
                        if (key_node.get_attribute_bool("prekey")) {
                            Row? device = db.identity_meta.get_device(identity_id, possible_jid.to_string(), sid);
                            PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(Base64.decode((!)key_node_content));
                            string identity_key = Base64.encode(msg.identity_key.serialize());
                            if (device != null && device[db.identity_meta.identity_key_public_base64] != null) {
                                if (device[db.identity_meta.identity_key_public_base64] != identity_key) {
                                    critical("Tried to use a different identity key for a known device id.");
                                    continue;
                                }
                            } else {
                                debug("Learn new device from incoming message from %s/%d", possible_jid.to_string(), sid);
                                bool blind_trust = db.trust.get_blind_trust(identity_id, possible_jid.to_string(), true);
                                if (db.identity_meta.insert_device_session(identity_id, possible_jid.to_string(), sid, identity_key, blind_trust ? TrustLevel.TRUSTED : TrustLevel.UNKNOWN) < 0) {
                                    critical("Failed learning a device.");
                                    continue;
                                }
                                XmppStream? stream = stream_interactor.get_stream(conversation.account);
                                if (device == null && stream != null) {
                                    module.request_user_devicelist.begin(stream, possible_jid);
                                }
                            }
                            debug("Starting new session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                            SessionCipher cipher = store.create_session_cipher(address);
                            key = cipher.decrypt_pre_key_signal_message(msg);
                            // TODO: Finish session
                        } else {
                            debug("Continuing session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                            SignalMessage msg = Plugin.get_context().deserialize_signal_message(Base64.decode((!)key_node_content));
                            SessionCipher cipher = store.create_session_cipher(address);
                            key = cipher.decrypt_signal_message(msg);
                        }
                        //address.device_id = 0; // TODO: Hack to have address obj live longer

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
                        message_device_id_map[message] = address.device_id;
                        message.encryption = Encryption.OMEMO;
                        flag.decrypted = true;
                    } catch (Error e) {
                        debug("Decrypting message from %s/%d failed: %s", possible_jid.to_string(), sid, e.message);
                        continue;
                    }

                    // If we figured out which real jid a message comes from due to decryption working, save it
                    if (conversation.type_ == Conversation.Type.GROUPCHAT && message.real_jid == null) {
                        message.real_jid = possible_jid;
                    }
                    return false;
                }
            }

            if (our_nodes.size == 0 && module.store.local_registration_id != sid) {
                db.identity_meta.update_last_message_undecryptable(identity_id, sid, message.time);
                trust_manager.bad_message_state_updated(conversation.account, message.from, sid);
            }

            debug("Received OMEMO encryped message that could not be decrypted.");
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
