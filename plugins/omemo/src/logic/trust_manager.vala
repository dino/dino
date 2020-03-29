using Dino.Entities;
using Gee;
using Xmpp;
using Omemo;
using Qlite;

namespace Dino.Plugins.Omemo {

public class TrustedDevice {
    public int32 device_id;
    public ProtocolVersion version;
}

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

    private StanzaNode create_legacy_encrypted_key_node(uint8[] key, Address address, Store store) throws GLib.Error {
        SessionCipher cipher = store.create_session_cipher(address);
        CiphertextMessage device_key = cipher.encrypt(key);
        debug("[Legacy] Created encrypted key for %s/%d", address.name, address.device_id);
        StanzaNode key_node = new StanzaNode.build("key", Legacy.NS_URI)
            .put_attribute("rid", address.device_id.to_string())
            .put_node(new StanzaNode.text(Base64.encode(device_key.serialized)));
        if (device_key.type == CiphertextType.PREKEY) key_node.put_attribute("prekey", "true");
        return key_node;
    }

    private void append_v1_encrypted_key_node(StanzaNode v1_header_node, uint8[] key, Address address, Store store) throws GLib.Error {
        SessionCipher cipher = store.create_session_cipher(address);
        cipher.version = 4;
        uint32 version;
        cipher.get_session_version(out version);
        if (version != 4) {
            warning(@"OMEMO:1 not configured: Session version: $(version) != 4 for $(address.name):$(address.device_id)");
            throw new Error(-1, ErrorCode.UNKNOWN, "Session is outdated");
        }
        CiphertextMessage device_key = cipher.encrypt(key);
        debug("[V1] Created encrypted key for %s/%d", address.name, address.device_id);
        StanzaNode key_node = new StanzaNode.build("key", V1.NS_URI)
                .put_attribute("rid", address.device_id.to_string())
                .put_node(new StanzaNode.text(Base64.encode(device_key.serialized)));
        if (device_key.type == CiphertextType.PREKEY) key_node.put_attribute("kex", "true");
        bool matched = false;
        foreach (Xmpp.StanzaNode keys in v1_header_node.get_subnodes("keys")) {
            if (keys.get_attribute("jid") == address.name) {
                keys.put_node(key_node);
                matched = true;
                break;
            }
        }
        if (!matched) {
            v1_header_node.put_node(new StanzaNode.build("keys", V1.NS_URI).put_attribute("jid", address.name).put_node(key_node));
        }
    }

    private BaseStreamModule? pick_module(Legacy.StreamModule? legacy_module, V1.StreamModule? v1_module, ProtocolVersion version) {
        switch (version) {
            case ProtocolVersion.LEGACY: return legacy_module;
            case ProtocolVersion.V1: return v1_module;
        }
        return null;
    }

    internal EncryptState encrypt_key(StanzaNode legacy_header_node, StanzaNode v1_header_node, uint8[] legacy_keytag, uint8[] v1_keymac, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream, Account account) throws Error {
        EncryptState status = new EncryptState();
        Legacy.StreamModule? legacy_module = stream.get_module(Legacy.StreamModule.IDENTITY);
        V1.StreamModule? v1_module = stream.get_module(V1.StreamModule.IDENTITY);

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
            foreach(TrustedDevice device in get_trusted_devices(account, recipient)) {
                if (pick_module(legacy_module, v1_module, device.version).is_ignored_device(recipient, device.device_id)) {
                    status.other_lost++;
                    continue;
                }
                try {
                    address.name = recipient.bare_jid.to_string();
                    address.device_id = (int) device.device_id;
                    switch (device.version) {
                        case ProtocolVersion.LEGACY:
                            if (legacy_header_node == null) continue;
                            StanzaNode key_node = create_legacy_encrypted_key_node(legacy_keytag, address, legacy_module.store);
                            legacy_header_node.put_node(key_node);
                            break;
                        case ProtocolVersion.V1:
                            if (v1_header_node == null) continue;
                            append_v1_encrypted_key_node(v1_header_node, v1_keymac, address, v1_module.store);
                            break;
                    }
                    status.other_success++;
                } catch (Error e) {
                    if (e.code == ErrorCode.UNKNOWN) status.other_unknown++;
                    else status.other_failure++;
                }
            }
        }

        // Encrypt the key for each own device
        address.name = self_jid.bare_jid.to_string();
        foreach(TrustedDevice device in get_trusted_devices(account, self_jid)) {
            if (pick_module(legacy_module, v1_module, device.version).is_ignored_device(self_jid, device.device_id)) {
                status.own_lost++;
                continue;
            }
            if (device.device_id != v1_module.store.local_registration_id) {
                address.device_id = (int) device.device_id;
                try {
                    switch (device.version) {
                        case ProtocolVersion.LEGACY:
                            if (legacy_header_node == null) continue;
                            StanzaNode key_node = create_legacy_encrypted_key_node(legacy_keytag, address, legacy_module.store);
                            legacy_header_node.put_node(key_node);
                            break;
                        case ProtocolVersion.V1:
                            if (v1_header_node == null) continue;
                            append_v1_encrypted_key_node(v1_header_node, v1_keymac, address, v1_module.store);
                            break;
                    }
                    status.own_success++;
                } catch (Error e) {
                    debug(@"Error while encrypting: $(e.message)[$(e.code)]");
                    if (e.code == ErrorCode.UNKNOWN) status.own_unknown++;
                    else status.own_failure++;
                }
            }
        }

        return status;
    }

    private static uint8[] hmac(ChecksumType type, uint8[] key, uint8[] data) {
        Hmac hmac = new Hmac(type, key);
        hmac.update(data);
        uint8[] res = new uint8[type.get_length()];
        size_t resl = res.length;
        hmac.get_digest(res, ref resl);
        return res;
    }

    public EncryptState encrypt(MessageStanza message, Jid self_jid, Gee.List<Jid> recipients, XmppStream stream, Account account) {
        EncryptState status = new EncryptState();
        if (!Plugin.ensure_context()) return status;
        if (message.to == null) return status;

        Legacy.StreamModule legacy_module = stream.get_module(Legacy.StreamModule.IDENTITY);
        Legacy.StreamModule v1_module = stream.get_module(Legacy.StreamModule.IDENTITY);

        try {
            //Create legacy key and use it to encrypt the message
            uint8[] legacy_key = new uint8[16];
            Plugin.get_context().randomize(legacy_key);
            uint8[] legacy_iv = new uint8[12];
            Plugin.get_context().randomize(legacy_iv);
            uint8[] legacy_aes_encrypt_result = aes_encrypt(Cipher.AES_GCM_NOPADDING, legacy_key, legacy_iv, message.body.data);
            uint8[] legacy_ciphertext = legacy_aes_encrypt_result[0:legacy_aes_encrypt_result.length-16];
            uint8[] legacy_tag = legacy_aes_encrypt_result[legacy_aes_encrypt_result.length-16:legacy_aes_encrypt_result.length];
            uint8[] legacy_keytag = new uint8[legacy_key.length + legacy_tag.length];
            Memory.copy(legacy_keytag, legacy_key, legacy_key.length);
            Memory.copy((uint8*)legacy_keytag + legacy_key.length, legacy_tag, legacy_tag.length);

            // Same for v1
            uint8[] v1_key = new uint8[32];
            Plugin.get_context().randomize(v1_key);
            uint8[] v1_hkdf = Plugin.get_context().derive_payload_secret(v1_key, 80);
            uint8[] v1_enc_key = v1_hkdf[0:32];
            uint8[] v1_auth_key = v1_hkdf[32:64];
            uint8[] v1_iv = v1_hkdf[64:80];
            // TODO: build proper sce message
            string v1_sce_content = @"<content xmlns='urn:xmpp:sce:0'><payload><body xmlns='jabber:client'>$(message.body.replace("&", "&amp;").replace("\"", "&quot;").replace("'", "&apos;").replace("<", "&lt;").replace(">", "&gt;"))</body></payload><rpad>nope</rpad></content>";
            uint8[] v1_ciphertext = aes_encrypt(Cipher.AES_CBC_PKCS5, v1_enc_key, v1_iv, v1_sce_content.data);
            uint8[] v1_hmac = hmac(ChecksumType.SHA256, v1_auth_key, v1_sce_content.data);
            uint8[] v1_keymac = new uint8[v1_key.length + v1_hmac.length];
            Memory.copy(v1_keymac, v1_key, v1_key.length);
            Memory.copy((uint8*)v1_keymac + v1_key.length, v1_hmac, v1_hmac.length);

            StanzaNode legacy_header_node = null, legacy_encrypted_node = null;
            if (legacy_module != null) {
                legacy_encrypted_node = new StanzaNode.build("encrypted", Legacy.NS_URI).add_self_xmlns()
                        .put_node(legacy_header_node = new StanzaNode.build("header", Legacy.NS_URI)
                            .put_attribute("sid", legacy_module.store.local_registration_id.to_string())
                            .put_node(new StanzaNode.build("iv", Legacy.NS_URI)
                                .put_node(new StanzaNode.text(Base64.encode(legacy_iv)))))
                        .put_node(new StanzaNode.build("payload", Legacy.NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(legacy_ciphertext))));
            }

            StanzaNode v1_header_node = null, v1_encrypted_node = null;
            if (v1_module != null) {
                v1_encrypted_node = new StanzaNode.build("encrypted", V1.NS_URI).add_self_xmlns()
                        .put_node(v1_header_node = new StanzaNode.build("header", V1.NS_URI)
                            .put_attribute("sid", v1_module.store.local_registration_id.to_string()))
                        .put_node(new StanzaNode.build("payload", V1.NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(v1_ciphertext))));
            }

            status = encrypt_key(legacy_header_node, v1_header_node, legacy_keytag, v1_keymac, self_jid, recipients, stream, account);

            if (legacy_header_node.get_subnodes("key").size > 0) {
                message.stanza.put_node(legacy_encrypted_node);
                Xep.ExplicitEncryption.add_encryption_tag_to_message(message, Legacy.NS_URI, "OMEMO");
            }
            if (v1_header_node.get_subnodes("keys").size > 0) {
                message.stanza.put_node(v1_encrypted_node);
                Xep.ExplicitEncryption.add_encryption_tag_to_message(message, V1.NS_URI, "OMEMO");
            }
            message.body = "[This message is OMEMO encrypted]";
            status.encrypted = true;
        } catch (Error e) {
            warning(@"OMEMO error while encrypting message: $(e.message)\n");
            message.body = "[OMEMO encryption failed]";
            status.encrypted = false;
        }
        return status;
    }

    public async void send_empty_message(Account account, Jid full_jid, int32 device_id) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;
        var device_meta = db.identity_meta.get_device(identity_id, full_jid.bare_jid.to_string(), device_id);
        if (device_meta == null) return;
        switch (ProtocolVersion.from_int(device_meta[db.identity_meta.version])) {
            case ProtocolVersion.LEGACY:
                yield send_empty_legacy_message(account, full_jid, device_id);
                break;
            case ProtocolVersion.V1:
                yield send_empty_v1_message(account, full_jid, device_id);
                break;
        }
    }

    private async void send_empty_v1_message(Account account, Jid full_jid, int32 device_id) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        V1.StreamModule v1_module = stream.get_module(V1.StreamModule.IDENTITY);
        if (v1_module == null) return;

        uint8[] v1_key = new uint8[32];
        Plugin.get_context().randomize(v1_key);
        uint8[] v1_hkdf = Plugin.get_context().derive_payload_secret(v1_key, 80);
        uint8[] v1_enc_key = v1_hkdf[0:32];
        uint8[] v1_auth_key = v1_hkdf[32:64];
        uint8[] v1_iv = v1_hkdf[64:80];
        // TODO: build from xml, proper rpad
        string v1_sce_content = @"<content xmlns='urn:xmpp:sce:0'><payload></payload><rpad>nope</rpad></content>";
        uint8[] v1_ciphertext = aes_encrypt(Cipher.AES_CBC_PKCS5, v1_enc_key, v1_iv, v1_sce_content.data);
        uint8[] v1_hmac = hmac(ChecksumType.SHA256, v1_auth_key, v1_sce_content.data);
        uint8[] v1_keymac = new uint8[v1_key.length + v1_hmac.length];
        Memory.copy(v1_keymac, v1_key, v1_key.length);
        Memory.copy((uint8*)v1_keymac + v1_key.length, v1_hmac, v1_hmac.length);

        MessageStanza message = new MessageStanza() { to = full_jid };
        Xep.ExplicitEncryption.add_encryption_tag_to_message(message, V1.NS_URI, "OMEMO");
        StanzaNode v1_header_node = null, v1_encrypted_node = null;
        v1_encrypted_node = new StanzaNode.build("encrypted", V1.NS_URI).add_self_xmlns()
                .put_node(v1_header_node = new StanzaNode.build("header", V1.NS_URI)
                    .put_attribute("sid", v1_module.store.local_registration_id.to_string()))
                .put_node(new StanzaNode.build("payload", V1.NS_URI)
                    .put_node(new StanzaNode.text(Base64.encode(v1_ciphertext))));
        Address address = new Address(full_jid.bare_jid.to_string(), device_id);
        try {
            append_v1_encrypted_key_node(v1_header_node, v1_keymac, address, v1_module.store);
            message.stanza.put_node(v1_encrypted_node);
            Xep.MessageProcessingHints.set_message_hint(message, Xep.MessageProcessingHints.HINT_NO_COPY);
            yield stream.write_async(message.stanza);
        } catch (Error e) {}
    }

    private async void send_empty_legacy_message(Account account, Jid full_jid, int32 device_id) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        Legacy.StreamModule legacy_module = stream.get_module(Legacy.StreamModule.IDENTITY);
        if (legacy_module == null) return;
        MessageStanza message = new MessageStanza() { to = full_jid };
        Xep.ExplicitEncryption.add_encryption_tag_to_message(message, Legacy.NS_URI, "OMEMO");
        StanzaNode legacy_header_node = null, legacy_encrypted_node = null;
        legacy_encrypted_node = new StanzaNode.build("encrypted", Legacy.NS_URI).add_self_xmlns()
                .put_node(legacy_header_node = new StanzaNode.build("header", Legacy.NS_URI)
                .put_attribute("sid", legacy_module.store.local_registration_id.to_string()));
        Address address = new Address(full_jid.bare_jid.to_string(), device_id);
        try {
            StanzaNode key_node = create_legacy_encrypted_key_node(new uint8[44], address, legacy_module.store);
            legacy_header_node.put_node(key_node);
            message.stanza.put_node(legacy_encrypted_node);
            yield stream.write_async(message.stanza);
        } catch (Error e) {}
    }

    public bool is_known_address(Account account, Jid jid) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return false;
        return db.identity_meta.with_address(identity_id, jid.to_string()).with(db.identity_meta.last_active, ">", 0).count() > 0;
    }

    public Gee.List<TrustedDevice> get_trusted_devices(Account account, Jid jid) {
        Gee.List<TrustedDevice> devices = new ArrayList<TrustedDevice>();
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return devices;
        foreach (Row device in db.identity_meta.get_trusted_devices(identity_id, jid.bare_jid.to_string())) {
            if(device[db.identity_meta.trust_level] != TrustLevel.UNKNOWN || device[db.identity_meta.identity_key_public_base64] == null)
                devices.add(new TrustedDevice() { device_id = device[db.identity_meta.device_id], version = ProtocolVersion.from_int(device[db.identity_meta.version]) });
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
            Store store = stream_interactor.module_manager.get_module(conversation.account, Legacy.StreamModule.IDENTITY).store;

            StanzaNode? legacy_encrypted = stanza.stanza.get_subnode("encrypted", Legacy.NS_URI);
            StanzaNode? v1_encrypted = stanza.stanza.get_subnode("encrypted", V1.NS_URI);
            if ((legacy_encrypted == null && v1_encrypted == null) || MessageFlag.get_flag(stanza) != null || stanza.from == null) return false;
            if (message.body == null && Xep.ExplicitEncryption.get_encryption_tag(stanza) == V1.NS_URI) {
                message.body = "[This message is OMEMO:1 encrypted]"; // TODO temporary
            }
            if (message.body == null && Xep.ExplicitEncryption.get_encryption_tag(stanza) == Legacy.NS_URI) {
                message.body = "[This message is OMEMO encrypted]"; // TODO temporary
            }
            if (!Plugin.ensure_context()) return false;
            int identity_id = db.identity.get_id(conversation.account.id);
            MessageFlag flag = new MessageFlag();
            stanza.add_flag(flag);

            int sid = -1;
            StanzaNode? v1_header = null;
            if (v1_encrypted != null) { v1_header = v1_encrypted.get_subnode("header"); }
            if (v1_header != null) { sid = v1_header.get_attribute_int("sid"); }
            StanzaNode? our_v1_node = null;
            if (v1_header != null && sid > 0) {
                foreach (StanzaNode keys_node in v1_header.get_subnodes("keys")) {
                    if (keys_node.get_attribute("jid") == conversation.account.bare_jid.to_string()) {
                        foreach (StanzaNode key_node in keys_node.get_subnodes("key")) {
                            debug("Is ours? %d =? %u", key_node.get_attribute_int("rid"), store.local_registration_id);
                            if (key_node.get_attribute_int("rid") == store.local_registration_id) {
                                our_v1_node = key_node;
                            }
                        }
                    }
                }
            }
            if (our_v1_node != null) {
                string? payload = v1_encrypted.get_deep_string_content("payload");
                string? key_node_content = our_v1_node.get_string_content();
                if (key_node_content != null) {
                    if (yield decrypt_v1_key_node(message, stanza, conversation, our_v1_node, identity_id, sid, payload)) {
                        return false;
                    }
                }
            }

            StanzaNode? legacy_header = null;
            if (legacy_encrypted != null) { legacy_header = legacy_encrypted.get_subnode("header"); }
            sid = -1;
            if (legacy_header != null) { sid = legacy_header.get_attribute_int("sid"); }

            var our_legacy_nodes = new ArrayList<StanzaNode>();
            if (legacy_header != null && sid > 0) {
                foreach (StanzaNode key_node in legacy_header.get_subnodes("key")) {
                    debug("Is ours? %d =? %u", key_node.get_attribute_int("rid"), store.local_registration_id);
                    if (key_node.get_attribute_int("rid") == store.local_registration_id) {
                        our_legacy_nodes.add(key_node);
                    }
                }
            }

            foreach (StanzaNode key_node in our_legacy_nodes) {
                string? payload = legacy_encrypted.get_deep_string_content("payload");
                if (key_node.get_string_content() == null) continue;
                string? iv_node = legacy_header.get_deep_string_content("iv");
                uint8[] iv = null;
                if (iv_node != null) { iv = Base64.decode((!)iv_node); }
                if (yield decrypt_legacy_key_node(message, stanza, conversation, key_node, identity_id, sid, payload, iv)) {
                    return false;
                }
            }

            if (our_legacy_nodes.size == 0 && our_v1_node == null) {
                db.identity_meta.update_last_message_undecryptable(identity_id, sid, message.time);
                trust_manager.bad_message_state_updated(conversation.account, message.from, sid);
            }

            debug("Received OMEMO encryped message that could not be decrypted.");
            return false;
        }

        private async bool decrypt_v1_key_node(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation, StanzaNode key_node, int identity_id, int sid, string? payload) {
            V1.StreamModule module = stream_interactor.module_manager.get_module(conversation.account, V1.StreamModule.IDENTITY);
            Store store = module.store;
            string? key_node_content = key_node.get_string_content();
            Gee.List<Jid> possible_jids = new ArrayList<Jid>();
            if (conversation.type_ == Conversation.Type.CHAT) {
                possible_jids.add(stanza.from.bare_jid);
            } else {
                Jid? real_jid = message.real_jid;
                if (real_jid != null) {
                    possible_jids.add(real_jid.bare_jid);
                } else if (key_node.get_attribute_bool("kex")) {
                    // pre key messages do store the identity key, so we can use that to find the real jid
                    PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message_omemo(Base64.decode((!)key_node_content), sid);
                    string identity_key = Base64.encode(msg.identity_key.serialize());
                    foreach (Row row in db.identity_meta.get_with_device_id(identity_id, sid).with(db.identity_meta.identity_key_public_base64, "=", identity_key)) {
                        try {
                            possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                        } catch (InvalidJidError e) {
                            warning("[V1] Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                    if (possible_jids.size != 1) {
                        return false;
                    }
                } else {
                    // If we don't know the device name (MUC history w/o MAM), test decryption with all keys with fitting device id
                    foreach (Row row in db.identity_meta.get_with_device_id(identity_id, sid)) {
                        try {
                            possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                        } catch (InvalidJidError e) {
                            warning("[V1] Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                }
            }
            uint8[] key;
            foreach (Jid possible_jid in possible_jids) {
                try {
                    Address address = new Address(possible_jid.to_string(), sid);
                    if (key_node.get_attribute_bool("kex")) {
                        var had_session = store.contains_session(address);
                        Row? device = db.identity_meta.get_device(identity_id, possible_jid.to_string(), sid);
                        PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message_omemo(Base64.decode((!)key_node_content), sid);
                        string identity_key = Base64.encode(msg.identity_key.serialize());
                        if (device != null && device[db.identity_meta.identity_key_public_base64] != null) {
                            if (device[db.identity_meta.identity_key_public_base64] != identity_key) {
                                critical("[V1] Tried to use a different identity key for a known device id.");
                                continue;
                            }
                        } else {
                            debug("Learn new device from incoming message from %s/%d", possible_jid.to_string(), sid);
                            bool blind_trust = db.trust.get_blind_trust(identity_id, possible_jid.to_string(), true);
                            if (db.identity_meta.insert_device_session(identity_id, possible_jid.to_string(), sid, identity_key, ProtocolVersion.V1, blind_trust ? TrustLevel.TRUSTED : TrustLevel.UNKNOWN) < 0) {
                                critical("[V1] Failed learning a device.");
                                continue;
                            }
                            XmppStream? stream = stream_interactor.get_stream(conversation.account);
                            if (device == null && stream != null) {
                                module.request_user_devicelist.begin(stream, possible_jid);
                            }
                        }
                        debug("[V1] Starting new session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                        SessionCipher cipher = store.create_session_cipher(address);
                        cipher.version = 4;
                        key = cipher.decrypt_pre_key_signal_message(msg);
                        if (!had_session) {
                            yield trust_manager.send_empty_v1_message(conversation.account, message.from.equals_bare(possible_jid) ? message.from : possible_jid, sid);
                        }
                    } else {
                        debug("[V1] Continuing session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                        SignalMessage msg = Plugin.get_context().deserialize_signal_message_omemo(Base64.decode((!)key_node_content));
                        SessionCipher cipher = store.create_session_cipher(address);
                        cipher.version = 4;
                        key = cipher.decrypt_signal_message(msg);
                        if (msg.counter == 53) {
                            // TODO: This is not precisely what should happen, but good enough for now
                            yield trust_manager.send_empty_v1_message(conversation.account, message.from.equals_bare(possible_jid) ? message.from : possible_jid, sid);
                        }
                    }
                    if (payload != null) {
                        if (key.length != 64) {
                            critical("[V1] Key length is invalid.");
                            continue;
                        }
                        uint8[] ciphertext = Base64.decode(payload);
                        uint8[] ikm = key[0:32];
                        uint8[] mac = key[32:64];
                        uint8[] hkdf = Plugin.get_context().derive_payload_secret(ikm, 80);
                        uint8[] enc_key = hkdf[0:32];
                        uint8[] auth_key = hkdf[32:64];
                        uint8[] iv = hkdf[64:80];
                        uint8[] decrypted = aes_decrypt(Cipher.AES_CBC_PKCS5, enc_key, iv, ciphertext);
                        uint8[] mac_cmp = hmac(ChecksumType.SHA256, auth_key, decrypted);
                        if (Memory.cmp(mac_cmp, mac, mac.length) != 0) {
                            critical("[V1] HMAC mismatches.");
                            continue;
                        }

                        // TODO: SCE
                        StanzaNode content = yield new StanzaReader.for_buffer(decrypted).read_stanza_node();

                        message.body = content.get_deep_string_content("payload", "jabber:client:body");
                        if (message.body == "reply empty") {
                            yield trust_manager.send_empty_v1_message(conversation.account, message.from.equals_bare(possible_jid) ? message.from : possible_jid, sid);
                        }
                        message_device_id_map[message] = address.device_id;
                        message.encryption = Encryption.OMEMO;
                    } else {
                        message.body = null;
                    }
                    MessageFlag.get_flag(stanza).decrypted = true;
                } catch (Error e) {
                    debug("[V1] Decrypting message from %s/%d failed: %s", possible_jid.to_string(), sid, e.message);
                    continue;
                }

                // If we figured out which real jid a message comes from due to decryption working, save it
                if (conversation.type_ == Conversation.Type.GROUPCHAT && message.real_jid == null) {
                    message.real_jid = possible_jid;
                }
                return true;
            }
            return false;
        }

        private async bool decrypt_legacy_key_node(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation, StanzaNode key_node, int identity_id, int sid, string? payload, uint8[] iv) {
            Legacy.StreamModule module = stream_interactor.module_manager.get_module(conversation.account, Legacy.StreamModule.IDENTITY);
            Store store = module.store;
            Gee.List<Jid> possible_jids = new ArrayList<Jid>();
            string? key_node_content = key_node.get_string_content();
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
                            warning("[Legacy] Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                    if (possible_jids.size != 1) {
                        return false;
                    }
                } else {
                    // If we don't know the device name (MUC history w/o MAM), test decryption with all keys with fitting device id
                    foreach (Row row in db.identity_meta.get_with_device_id(identity_id, sid)) {
                        try {
                            possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                        } catch (InvalidJidError e) {
                            warning("[Legacy] Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                }
            }

            if (possible_jids.size == 0) {
                debug("Received message from unknown entity with device id %d", sid);
            }

            uint8[] key;

            foreach (Jid possible_jid in possible_jids) {
                try {
                    Address address = new Address(possible_jid.to_string(), sid);
                    if (key_node.get_attribute_bool("prekey")) {
                        var had_session = store.contains_session(address);
                        Row? device = db.identity_meta.get_device(identity_id, possible_jid.to_string(), sid);
                        PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(Base64.decode((!)key_node_content));
                        string identity_key = Base64.encode(msg.identity_key.serialize());
                        if (device != null && device[db.identity_meta.identity_key_public_base64] != null) {
                            if (device[db.identity_meta.identity_key_public_base64] != identity_key) {
                                critical("[Legacy] Tried to use a different identity key for a known device id.");
                                continue;
                            }
                        } else {
                            debug("Learn new device from incoming message from %s/%d", possible_jid.to_string(), sid);
                            bool blind_trust = db.trust.get_blind_trust(identity_id, possible_jid.to_string(), true);
                            if (db.identity_meta.insert_device_session(identity_id, possible_jid.to_string(), sid, identity_key, ProtocolVersion.LEGACY, blind_trust ? TrustLevel.TRUSTED : TrustLevel.UNKNOWN) < 0) {
                                critical("[Legacy] Failed learning a device.");
                                continue;
                            }
                            XmppStream? stream = stream_interactor.get_stream(conversation.account);
                            if (device == null && stream != null) {
                                module.request_user_devicelist.begin(stream, possible_jid);
                            }
                        }
                        debug("[Legacy] Starting new session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                        SessionCipher cipher = store.create_session_cipher(address);
                        key = cipher.decrypt_pre_key_signal_message(msg);
                        if (!had_session) {
                            yield trust_manager.send_empty_legacy_message(conversation.account, message.from.equals_bare(possible_jid) ? message.from : possible_jid, sid);
                        }
                    } else {
                        debug("[Legacy] Continuing session for decryption with device from %s/%d", possible_jid.to_string(), sid);
                        SignalMessage msg = Plugin.get_context().deserialize_signal_message(Base64.decode((!)key_node_content));
                        SessionCipher cipher = store.create_session_cipher(address);
                        key = cipher.decrypt_signal_message(msg);
                    }

                    if (payload != null && iv != null) {
                        uint8[] ciphertext = Base64.decode(payload);
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
                    } else {
                        message.body = null;
                    }
                    MessageFlag.get_flag(stanza).decrypted = true;
                } catch (Error e) {
                    debug("[Legacy] Decrypting message from %s/%d failed: %s", possible_jid.to_string(), sid, e.message);
                    continue;
                }

                // If we figured out which real jid a message comes from due to decryption working, save it
                if (conversation.type_ == Conversation.Type.GROUPCHAT && message.real_jid == null) {
                    message.real_jid = possible_jid;
                }
                return true;
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
