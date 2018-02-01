using Gee;
using Xmpp;
using Xmpp;
using Xmpp.Xep;
using Signal;

namespace Dino.Plugins.Omemo {

private const string NS_URI = "eu.siacs.conversations.axolotl";
private const string NODE_DEVICELIST = NS_URI + ".devicelist";
private const string NODE_BUNDLES = NS_URI + ".bundles";
private const string NODE_VERIFICATION = NS_URI + ".verification";

private const int NUM_KEYS_TO_PUBLISH = 100;

public class StreamModule : XmppStreamModule {
    public static Xmpp.ModuleIdentity<StreamModule> IDENTITY = new Xmpp.ModuleIdentity<StreamModule>(NS_URI, "omemo_module");

    private Store store;
    private ConcurrentSet<string> active_bundle_requests = new ConcurrentSet<string>();
    private ConcurrentSet<Jid> active_devicelist_requests = new ConcurrentSet<Jid>();
    private Map<Jid, ArrayList<int32>> device_lists = new HashMap<Jid, ArrayList<int32>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private Map<Jid, ArrayList<int32>> ignored_devices = new HashMap<Jid, ArrayList<int32>>(Jid.hash_bare_func, Jid.equals_bare_func);
    private ReceivedPipelineListener received_pipeline_listener;

    public signal void store_created(Store store);
    public signal void device_list_loaded(Jid jid);
    public signal void bundle_fetched(Jid jid, int device_id, Bundle bundle);
    public signal void session_started(Jid jid, int device_id);
    public signal void session_start_failed(Jid jid, int device_id);

    public EncryptState encrypt(MessageStanza message, Jid self_jid) {
        EncryptState status = new EncryptState();
        if (!Plugin.ensure_context()) return status;
        if (message.to == null) return status;
        try {
            if (!device_lists.has_key(self_jid)) return status;
            status.own_list = true;
            status.own_devices = device_lists.get(self_jid).size;
            if (!device_lists.has_key(message.to)) return status;
            status.other_list = true;
            status.other_devices = device_lists.get(message.to).size;
            if (status.own_devices == 0 || status.other_devices == 0) return status;

            uint8[] key = new uint8[16];
            Plugin.get_context().randomize(key);
            uint8[] iv = new uint8[16];
            Plugin.get_context().randomize(iv);

            uint8[] ciphertext = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, message.body.data);

            StanzaNode header;
            StanzaNode encrypted = new StanzaNode.build("encrypted", NS_URI).add_self_xmlns()
                    .put_node(header = new StanzaNode.build("header", NS_URI)
                        .put_attribute("sid", store.local_registration_id.to_string())
                        .put_node(new StanzaNode.build("iv", NS_URI)
                            .put_node(new StanzaNode.text(Base64.encode(iv)))))
                    .put_node(new StanzaNode.build("payload", NS_URI)
                        .put_node(new StanzaNode.text(Base64.encode(ciphertext))));

            Address address = new Address(message.to.bare_jid.to_string(), 0);
            foreach(int32 device_id in device_lists[message.to]) {
                if (is_ignored_device(message.to, device_id)) {
                    status.other_lost++;
                    continue;
                }
                try {
                    address.device_id = (int) device_id;
                    StanzaNode key_node = create_encrypted_key(key, address);
                    header.put_node(key_node);
                    status.other_success++;
                } catch (Error e) {
                    if (e.code == ErrorCode.UNKNOWN) status.other_unknown++;
                    else status.other_failure++;
                }
            }
            address.name = self_jid.bare_jid.to_string();
            foreach(int32 device_id in device_lists[self_jid]) {
                if (is_ignored_device(self_jid, device_id)) {
                    status.own_lost++;
                    continue;
                }
                if (device_id != store.local_registration_id) {
                    address.device_id = (int) device_id;
                    try {
                        StanzaNode key_node = create_encrypted_key(key, address);
                        header.put_node(key_node);
                        status.own_success++;
                    } catch (Error e) {
                        if (e.code == ErrorCode.UNKNOWN) status.own_unknown++;
                        else status.own_failure++;
                    }
                }
            }

            message.stanza.put_node(encrypted);
            message.body = "[This message is OMEMO encrypted]";
            status.encrypted = true;
        } catch (Error e) {
            if (Plugin.DEBUG) print(@"OMEMO: Signal error while encrypting message: $(e.message)\n");
        }
        return status;
    }

    private StanzaNode create_encrypted_key(uint8[] key, Address address) throws GLib.Error {
        SessionCipher cipher = store.create_session_cipher(address);
        CiphertextMessage device_key = cipher.encrypt(key);
        StanzaNode key_node = new StanzaNode.build("key", NS_URI)
            .put_attribute("rid", address.device_id.to_string())
            .put_node(new StanzaNode.text(Base64.encode(device_key.serialized)));
        if (device_key.type == CiphertextType.PREKEY) key_node.put_attribute("prekey", "true");
        return key_node;
    }

    public override void attach(XmppStream stream) {
        if (!Plugin.ensure_context()) return;

        this.store = Plugin.get_context().create_store();
        store_created(store);
        received_pipeline_listener = new ReceivedPipelineListener(store);
        stream.get_module(MessageModule.IDENTITY).received_pipeline.connect(received_pipeline_listener);
        stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NODE_DEVICELIST, (stream, jid, id, node) => on_devicelist(stream, jid, id, node));
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.disconnect(received_pipeline_listener);
    }

    public void request_user_devicelist(XmppStream stream, Jid jid) {
        if (active_devicelist_requests.add(jid)) {
            if (Plugin.DEBUG) print(@"OMEMO: requesting device list for $jid\n");
            stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid, NODE_DEVICELIST, (stream, jid, id, node) => on_devicelist(stream, jid, id, node));
        }
    }

    public void on_devicelist(XmppStream stream, Jid jid, string? id, StanzaNode? node_) {
        StanzaNode node = node_ ?? new StanzaNode.build("list", NS_URI).add_self_xmlns();
        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
        if (my_jid == null) return;
        if (jid.equals_bare(my_jid) && store.local_registration_id != 0) {
            bool am_on_devicelist = false;
            foreach (StanzaNode device_node in node.get_subnodes("device")) {
                int device_id = device_node.get_attribute_int("id");
                if (store.local_registration_id == device_id) {
                    am_on_devicelist = true;
                }
            }
            if (!am_on_devicelist) {
                if (Plugin.DEBUG) print(@"OMEMO: Not on device list, adding id\n");
                node.put_node(new StanzaNode.build("device", NS_URI).put_attribute("id", store.local_registration_id.to_string()));
                stream.get_module(Pubsub.Module.IDENTITY).publish(stream, jid, NODE_DEVICELIST, NODE_DEVICELIST, id, node);
            } else {
                publish_bundles_if_needed(stream, jid);
            }
        }
        lock(device_lists) {
            device_lists[jid] = new ArrayList<int32>();
            foreach (StanzaNode device_node in node.get_subnodes("device")) {
                device_lists[jid].add(device_node.get_attribute_int("id"));
            }
        }
        active_devicelist_requests.remove(jid);
        device_list_loaded(jid);
    }

    public void start_sessions_with(XmppStream stream, Jid jid) {
        if (!device_lists.has_key(jid)) {
            return;
        }
        Address address = new Address(jid.bare_jid.to_string(), 0);
        foreach(int32 device_id in device_lists[jid]) {
            if (!is_ignored_device(jid, device_id)) {
                address.device_id = device_id;
                try {
                    if (!store.contains_session(address)) {
                        start_session_with(stream, jid, device_id);
                    }
                } catch (Error e) {
                    // Ignore
                }
            }
        }
        address.device_id = 0;
    }

    public void start_session_with(XmppStream stream, Jid jid, int device_id) {
        if (active_bundle_requests.add(jid.bare_jid.to_string() + @":$device_id")) {
            if (Plugin.DEBUG) print(@"OMEMO: Asking for bundle from $(jid.bare_jid.to_string()):$device_id\n");
            stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid.bare_jid, @"$NODE_BUNDLES:$device_id", (stream, jid, id, node) => {
                on_other_bundle_result(stream, jid, device_id, id, node);
            });
        }
    }

    public void fetch_bundle(XmppStream stream, Jid jid, int device_id) {
        if (active_bundle_requests.add(jid.bare_jid.to_string() + @":$device_id")) {
            if (Plugin.DEBUG) print(@"OMEMO: Asking for bundle from $(jid.bare_jid.to_string()):$device_id\n");
            stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid.bare_jid, @"$NODE_BUNDLES:$device_id", (stream, jid, id, node) => {
                bundle_fetched(jid, device_id, new Bundle(node));
            });
        }
    }

    public ArrayList<int32> get_device_list(Jid jid) {
        if (is_known_address(jid)) {
            return device_lists[jid];
        } else {
            return new ArrayList<int32>();
        }
    }

    public bool is_known_address(Jid jid) {
        return device_lists.has_key(jid);
    }

    public void ignore_device(Jid jid, int32 device_id) {
        if (device_id <= 0) return;
        lock (ignored_devices) {
            if (!ignored_devices.has_key(jid)) {
                ignored_devices[jid] = new ArrayList<int32>();
            }
            ignored_devices[jid].add(device_id);
        }
        session_start_failed(jid, device_id);
    }

    public bool is_ignored_device(Jid jid, int32 device_id) {
        if (device_id <= 0) return true;
        lock (ignored_devices) {
            return ignored_devices.has_key(jid) && ignored_devices[jid].contains(device_id);
        }
    }

    private void on_other_bundle_result(XmppStream stream, Jid jid, int device_id, string? id, StanzaNode? node) {
        bool fail = false;
        if (node == null) {
            // Device not registered, shouldn't exist
            fail = true;
        } else {
            Bundle bundle = new Bundle(node);
            bundle_fetched(jid, device_id, bundle);
            int32 signed_pre_key_id = bundle.signed_pre_key_id;
            ECPublicKey? signed_pre_key = bundle.signed_pre_key;
            uint8[] signed_pre_key_signature = bundle.signed_pre_key_signature;
            ECPublicKey? identity_key = bundle.identity_key;

            ArrayList<Bundle.PreKey> pre_keys = bundle.pre_keys;
            if (signed_pre_key_id < 0 || signed_pre_key == null || identity_key == null || pre_keys.size == 0) {
                fail = true;
            } else {
                int pre_key_idx = Random.int_range(0, pre_keys.size);
                int32 pre_key_id = pre_keys[pre_key_idx].key_id;
                ECPublicKey? pre_key = pre_keys[pre_key_idx].key;
                if (pre_key_id < 0 || pre_key == null) {
                    fail = true;
                } else {
                    Address address = new Address(jid.bare_jid.to_string(), device_id);
                    try {
                        if (store.contains_session(address)) {
                            return;
                        }
                        SessionBuilder builder = store.create_session_builder(address);
                        builder.process_pre_key_bundle(create_pre_key_bundle(device_id, device_id, pre_key_id, pre_key, signed_pre_key_id, signed_pre_key, signed_pre_key_signature, identity_key));
                        stream.get_module(IDENTITY).session_started(jid, device_id);
                    } catch (Error e) {
                        fail = true;
                    }
                    address.device_id = 0; // TODO: Hack to have address obj live longer
                }
            }
        }
        if (fail) {
            stream.get_module(IDENTITY).ignore_device(jid, device_id);
        }
        stream.get_module(IDENTITY).active_bundle_requests.remove(jid.bare_jid.to_string() + @":$device_id");
    }

    public void publish_bundles_if_needed(XmppStream stream, Jid jid) {
        if (active_bundle_requests.add(jid.bare_jid.to_string() + @":$(store.local_registration_id)")) {
            stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid, @"$NODE_BUNDLES:$(store.local_registration_id)", on_self_bundle_result);
        }
    }

    private void on_self_bundle_result(XmppStream stream, Jid jid, string? id, StanzaNode? node) {
        if (!Plugin.ensure_context()) return;
        Map<int, ECPublicKey> keys = new HashMap<int, ECPublicKey>();
        ECPublicKey? identity_key = null;
        int32 signed_pre_key_id = -1;
        ECPublicKey? signed_pre_key = null;
        SignedPreKeyRecord? signed_pre_key_record = null;
        bool changed = false;
        if (node == null) {
            identity_key = store.identity_key_pair.public;
            changed = true;
        } else {
            Bundle bundle = new Bundle(node);
            foreach (Bundle.PreKey prekey in bundle.pre_keys) {
                ECPublicKey? key = prekey.key;
                if (key != null) {
                    keys[prekey.key_id] = (!)key;
                }
            }
            identity_key = bundle.identity_key;
            signed_pre_key_id = bundle.signed_pre_key_id;;
            signed_pre_key = bundle.signed_pre_key;
        }

        try {
            // Validate IdentityKey
            if (identity_key == null || store.identity_key_pair.public.compare((!)identity_key) != 0) {
                changed = true;
            }
            IdentityKeyPair identity_key_pair = store.identity_key_pair;

            // Validate signedPreKeyRecord + ID
            if (signed_pre_key == null || signed_pre_key_id == -1 || !store.contains_signed_pre_key(signed_pre_key_id) || store.load_signed_pre_key(signed_pre_key_id).key_pair.public.compare((!)signed_pre_key) != 0) {
                signed_pre_key_id = Random.int_range(1, int32.MAX); // TODO: No random, use ordered number
                signed_pre_key_record = Plugin.get_context().generate_signed_pre_key(identity_key_pair, signed_pre_key_id);
                store.store_signed_pre_key((!)signed_pre_key_record);
                changed = true;
            } else {
                signed_pre_key_record = store.load_signed_pre_key(signed_pre_key_id);
            }

            // Validate PreKeys
            Set<PreKeyRecord> pre_key_records = new HashSet<PreKeyRecord>();
            foreach (var entry in keys.entries) {
                if (store.contains_pre_key(entry.key)) {
                    PreKeyRecord record = store.load_pre_key(entry.key);
                    if (record.key_pair.public.compare(entry.value) == 0) {
                        pre_key_records.add(record);
                    }
                }
            }
            int new_keys = NUM_KEYS_TO_PUBLISH - pre_key_records.size;
            if (new_keys > 0) {
                int32 next_id = Random.int_range(1, int32.MAX); // TODO: No random, use ordered number
                Set<PreKeyRecord> new_records = Plugin.get_context().generate_pre_keys((uint)next_id, (uint)new_keys);
                pre_key_records.add_all(new_records);
                foreach (PreKeyRecord record in new_records) {
                    store.store_pre_key(record);
                }
                changed = true;
            }

            if (changed) {
                publish_bundles(stream, (!)signed_pre_key_record, identity_key_pair, pre_key_records, (int32) store.local_registration_id);
            }
        } catch (Error e) {
            if (Plugin.DEBUG) print(@"Unexpected error while publishing bundle: $(e.message)\n");
        }
        stream.get_module(IDENTITY).active_bundle_requests.remove(jid.bare_jid.to_string() + @":$(store.local_registration_id)");
    }

    public static void publish_bundles(XmppStream stream, SignedPreKeyRecord signed_pre_key_record, IdentityKeyPair identity_key_pair, Set<PreKeyRecord> pre_key_records, int32 device_id) throws Error {
        ECKeyPair tmp;
        StanzaNode bundle = new StanzaNode.build("bundle", NS_URI)
                .add_self_xmlns()
                .put_node(new StanzaNode.build("signedPreKeyPublic", NS_URI)
                    .put_attribute("signedPreKeyId", signed_pre_key_record.id.to_string())
                    .put_node(new StanzaNode.text(Base64.encode((tmp = signed_pre_key_record.key_pair).public.serialize()))))
                .put_node(new StanzaNode.build("signedPreKeySignature", NS_URI)
                    .put_node(new StanzaNode.text(Base64.encode(signed_pre_key_record.signature))))
                .put_node(new StanzaNode.build("identityKey", NS_URI)
                    .put_node(new StanzaNode.text(Base64.encode(identity_key_pair.public.serialize()))));
        StanzaNode prekeys = new StanzaNode.build("prekeys", NS_URI);
        foreach (PreKeyRecord pre_key_record in pre_key_records) {
            prekeys.put_node(new StanzaNode.build("preKeyPublic", NS_URI)
                    .put_attribute("preKeyId", pre_key_record.id.to_string())
                    .put_node(new StanzaNode.text(Base64.encode(pre_key_record.key_pair.public.serialize()))));
        }
        bundle.put_node(prekeys);

        stream.get_module(Pubsub.Module.IDENTITY).publish(stream, null, @"$NODE_BUNDLES:$device_id", @"$NODE_BUNDLES:$device_id", "1", bundle);
    }

    public override string get_ns() {
        return NS_URI;
    }

    public override string get_id() {
        return IDENTITY.id;
    }
}


public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {"EXTRACT_MESSAGE_2"};

    public override string action_group { get { return "ENCRYPT_BODY"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    private Store store;

    public ReceivedPipelineListener(Store store) {
        this.store = store;
    }

    public override async bool run(XmppStream stream, MessageStanza message) {
        StanzaNode? _encrypted = message.stanza.get_subnode("encrypted", NS_URI);
        if (_encrypted == null || MessageFlag.get_flag(message) != null || message.from == null) return false;
        StanzaNode encrypted = (!)_encrypted;
        if (!Plugin.ensure_context()) return false;
        MessageFlag flag = new MessageFlag();
        message.add_flag(flag);
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
                    Address address = new Address(message.from.bare_jid.to_string(), header.get_attribute_int("sid"));
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
