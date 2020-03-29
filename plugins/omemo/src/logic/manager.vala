using Dino.Entities;
using Omemo;
using Qlite;
using Xmpp;
using Gee;

namespace Dino.Plugins.Omemo {

public class Manager : StreamInteractionModule, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("omemo_manager");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;
    private TrustManager trust_manager;
    private Map<Entities.Message, MessageState> message_states = new HashMap<Entities.Message, MessageState>(Entities.Message.hash_func, Entities.Message.equals_func);

    private class MessageState {
        public Entities.Message msg { get; private set; }
        public EncryptState last_try { get; private set; }
        public int waiting_other_sessions { get; set; }
        public int waiting_own_sessions { get; set; }
        public bool waiting_own_devicelist { get; set; }
        public int waiting_other_devicelists { get; set; }
        public bool force_next_attempt { get; set; }
        public bool will_send_now { get; private set; }
        public bool active_send_attempt { get; set; }

        public MessageState(Entities.Message msg, EncryptState last_try) {
            update_from_encrypt_status(msg, last_try);
        }

        public void update_from_encrypt_status(Entities.Message msg, EncryptState new_try) {
            this.msg = msg;
            this.last_try = new_try;
            this.waiting_other_sessions = new_try.other_unknown;
            this.waiting_own_sessions = new_try.own_unknown;
            this.waiting_own_devicelist = !new_try.own_list;
            this.waiting_other_devicelists = new_try.other_waiting_lists;
            this.active_send_attempt = false;
            will_send_now = false;
            if (new_try.other_failure > 0 || (new_try.other_lost == new_try.other_devices && new_try.other_devices > 0)) {
                msg.marked = Entities.Message.Marked.WONTSEND;
            } else if (new_try.other_unknown > 0 || new_try.own_unknown > 0 || new_try.other_waiting_lists > 0 || !new_try.own_list || new_try.own_devices == 0) {
                msg.marked = Entities.Message.Marked.UNSENT;
            } else if (!new_try.encrypted) {
                msg.marked = Entities.Message.Marked.WONTSEND;
            } else {
                will_send_now = true;
            }
        }

        public bool should_retry_now() {
            return !waiting_own_devicelist && waiting_other_devicelists <= 0 && waiting_other_sessions <= 0 && waiting_own_sessions <= 0 && !active_send_attempt;
        }

        public string to_string() {
            return @"MessageState (msg=$(msg.stanza_id), send=$will_send_now, $last_try)";
        }
    }

    private Manager(StreamInteractor stream_interactor, Database db, TrustManager trust_manager) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.trust_manager = trust_manager;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_send.connect(on_pre_message_send);
        stream_interactor.get_module(RosterManager.IDENTITY).mutual_subscription.connect(on_mutual_subscription);
    }

    public void clear_device_list(Account account) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return;

        stream.get_module(Legacy.StreamModule.IDENTITY).clear_device_list(stream);
        stream.get_module(V1.StreamModule.IDENTITY).clear_device_list(stream);
    }

    private Gee.List<Jid> get_occupants(Jid jid, Account account){
        Gee.List<Jid> occupants = new ArrayList<Jid>(Jid.equals_bare_func);
        if(!stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(jid, account)){
            occupants.add(jid);
        }
        Gee.List<Jid>? occupant_jids = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(jid, account);
        if(occupant_jids == null) {
            return occupants;
        }
        foreach (Jid occupant in occupant_jids) {
            if(!occupant.equals(account.bare_jid)){
                occupants.add(occupant.bare_jid);
            }
        }
        return occupants;
    }

    private void on_pre_message_send(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (message.encryption == Encryption.OMEMO) {
            XmppStream? stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) {
                message.marked = Entities.Message.Marked.UNSENT;
                return;
            }
            Legacy.StreamModule? legacy_module = ((!)stream).get_module(Legacy.StreamModule.IDENTITY);
            V1.StreamModule? v1_module = ((!)stream).get_module(V1.StreamModule.IDENTITY);
            if (legacy_module == null && v1_module == null) {
                message.marked = Entities.Message.Marked.UNSENT;
                return;
            }

            //Get a list of everyone for whom the message should be encrypted
            Gee.List<Jid> recipients;
            if (message_stanza.type_ == MessageStanza.TYPE_GROUPCHAT) {
                recipients = get_occupants((!)message.to.bare_jid, conversation.account);
                if (recipients.size == 0) {
                    message.marked = Entities.Message.Marked.WONTSEND;
                    return;
                }
            } else {
                recipients = new ArrayList<Jid>(Jid.equals_bare_func);
                recipients.add(message_stanza.to);
            }

            //Attempt to encrypt the message
            EncryptState enc_state = trust_manager.encrypt(message_stanza, conversation.account.bare_jid, recipients, stream, conversation.account);
            MessageState state;
            lock (message_states) {
                if (message_states.has_key(message)) {
                    state = message_states.get(message);
                    state.update_from_encrypt_status(message, enc_state);
                    if (state.will_send_now) {
                        debug("sending message delayed: %s", state.to_string());
                    }
                } else {
                    state = new MessageState(message, enc_state);
                    message_states[message] = state;
                }
                if (state.will_send_now) {
                    message_states.unset(message);
                }
            }

            //Encryption failed - need to fetch more information
            if (!state.will_send_now) {
                if (message.marked == Entities.Message.Marked.WONTSEND) {
                    debug("retracting message %s", state.to_string());
                    message_states.unset(message);
                } else {
                    debug("delaying message %s", state.to_string());

                    if (state.waiting_own_sessions > 0) {
                        var devices = trust_manager.get_trusted_devices(conversation.account, conversation.account.bare_jid);
                        var list = devices.filter((d) => d.version == ProtocolVersion.LEGACY).fold<ArrayList<int32>>((d, list) => { list.add(d.device_id); return list; }, new ArrayList<int32>());
                        legacy_module.fetch_bundles((!)stream, conversation.account.bare_jid, list);
                        list = devices.filter((d) => d.version == ProtocolVersion.LEGACY).fold<ArrayList<int32>>((d, list) => { list.add(d.device_id); return list; }, new ArrayList<int32>());
                        v1_module.fetch_bundles((!)stream, conversation.account.bare_jid, list);
                    }
                    if (state.waiting_other_sessions > 0 && message.counterpart != null) {
                        foreach(Jid jid in get_occupants(((!)message.counterpart).bare_jid, conversation.account)) {
                            var devices = trust_manager.get_trusted_devices(conversation.account, jid);
                            var list = devices.filter((d) => d.version == ProtocolVersion.LEGACY).fold<ArrayList<int32>>((d, list) => { list.add(d.device_id); return list; }, new ArrayList<int32>());
                            legacy_module.fetch_bundles((!)stream, jid, list);
                            list = devices.filter((d) => d.version == ProtocolVersion.V1).fold<ArrayList<int32>>((d, list) => { list.add(d.device_id); return list; }, new ArrayList<int32>());
                            v1_module.fetch_bundles((!)stream, jid, list);
                        }
                    }
                    if (state.waiting_other_devicelists > 0 && message.counterpart != null) {
                        foreach(Jid jid in get_occupants(((!)message.counterpart).bare_jid, conversation.account)) {
                            legacy_module.request_user_devicelist.begin((!)stream, jid);
                            v1_module.request_user_devicelist.begin((!)stream, jid);
                        }
                    }
                }
            }
        }
    }

    private void on_mutual_subscription(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if(stream == null) return;

        stream_interactor.module_manager.get_module(account, Legacy.StreamModule.IDENTITY).request_user_devicelist.begin((!)stream, jid);
        stream_interactor.module_manager.get_module(account, V1.StreamModule.IDENTITY).request_user_devicelist.begin((!)stream, jid);
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        Legacy.StreamModule legacy_module = stream_interactor.module_manager.get_module(account, Legacy.StreamModule.IDENTITY);
        if (legacy_module != null) {
            legacy_module.request_user_devicelist.begin(stream, account.bare_jid);
            legacy_module.device_list_loaded.connect((jid, devices) => on_legacy_device_list_loaded(account, jid, devices));
            legacy_module.bundle_fetched.connect((jid, device_id, bundle) => on_bundle_fetched(account, jid, device_id, bundle));
            legacy_module.bundle_fetch_failed.connect((jid) => continue_message_sending(account, jid));
        }
        V1.StreamModule v1_module = stream_interactor.module_manager.get_module(account, V1.StreamModule.IDENTITY);
        if (v1_module != null) {
            v1_module.request_user_devicelist.begin(stream, account.bare_jid);
            v1_module.device_list_loaded.connect((jid, devices) => on_v1_device_list_loaded(account, jid, devices));
            v1_module.bundle_fetched.connect((jid, device_id, bundle) => on_bundle_fetched(account, jid, device_id, bundle));
            v1_module.bundle_fetch_failed.connect((jid) => continue_message_sending(account, jid));
        }
        initialize_store.begin(account);
    }

    private void on_legacy_device_list_loaded(Account account, Jid jid, ArrayList<int32> device_list) {
        debug("[Legacy] received device list for %s from %s", account.bare_jid.to_string(), jid.to_string());

        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return;
        }
        Legacy.StreamModule? module = ((!)stream).get_module(Legacy.StreamModule.IDENTITY);
        if (module == null) {
            return;
        }

        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;

        //Update meta database
        db.identity_meta.insert_legacy_device_list(identity_id, jid.bare_jid.to_string(), device_list);

        //Fetch the bundle for each new device
        int inc = 0;
        foreach (Row row in db.identity_meta.get_unknown_devices(identity_id, jid.bare_jid.to_string())) {
            try {
                module.fetch_bundle(stream, new Jid(row[db.identity_meta.address_name]), row[db.identity_meta.device_id], false);
                inc++;
            } catch (InvalidJidError e) {
                warning("Ignoring device with invalid Jid: %s", e.message);
            }
        }
        if (inc > 0) {
            debug("new bundles %i/%i for %s", inc, device_list.size, jid.to_string());
        }

        on_after_devicelist_laoded(account, jid, identity_id);
    }

    private void on_v1_device_list_loaded(Account account, Jid jid, ArrayList<V1.DeviceListItem> device_list) {
        debug("[V1] received device list for %s from %s", account.bare_jid.to_string(), jid.to_string());

        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return;
        }
        V1.StreamModule? module = ((!)stream).get_module(V1.StreamModule.IDENTITY);
        if (module == null) {
            return;
        }

        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;

        //Update meta database
        db.identity_meta.insert_v1_device_list(identity_id, jid.bare_jid.to_string(), device_list);

        //Fetch the bundle for each new device
        int inc = 0;
        foreach (Row row in db.identity_meta.get_unknown_devices(identity_id, jid.bare_jid.to_string())) {
            try {
                module.fetch_bundle(stream, new Jid(row[db.identity_meta.address_name]), row[db.identity_meta.device_id], false);
                inc++;
            } catch (InvalidJidError e) {
                warning("Ignoring device with invalid Jid: %s", e.message);
            }
        }
        if (inc > 0) {
            debug("new bundles %i/%i for %s", inc, device_list.size, jid.to_string());
        }

        on_after_devicelist_laoded(account, jid, identity_id);
    }

    private void on_after_devicelist_laoded(Account account, Jid jid, int identity_id) {
        //Create an entry for the jid in the account table if one does not exist already
        if (db.trust.select().with(db.trust.identity_id, "=", identity_id).with(db.trust.address_name, "=", jid.bare_jid.to_string()).count() == 0) {
            db.trust.insert().value(db.trust.identity_id, identity_id).value(db.trust.address_name, jid.bare_jid.to_string()).value(db.trust.blind_trust, true).perform();
        }

        //Get all messages that needed the devicelist and determine if we can now send them
        HashSet<Entities.Message> send_now = new HashSet<Entities.Message>();
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {
                if (!msg.account.equals(account)) continue;
                Gee.List<Jid> occupants = get_occupants(msg.counterpart.bare_jid, account);
                MessageState state = message_states[msg];
                if (account.bare_jid.equals(jid)) {
                    state.waiting_own_devicelist = false;
                } else if (msg.counterpart != null && occupants.contains(jid)) {
                    state.waiting_other_devicelists--;
                }
                if (state.should_retry_now()) {
                    send_now.add(msg);
                    state.active_send_attempt = true;
                }
            }
        }
        foreach (Entities.Message msg in send_now) {
            if (msg.counterpart == null) continue;
            Entities.Conversation? conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(((!)msg.counterpart), account);
            if (conv == null) continue;
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(msg, (!)conv, true);
        }
    }

    private void on_bundle_fetched(Account account, Jid jid, int32 device_id, Bundle bundle) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;

        bool blind_trust = db.trust.get_blind_trust(identity_id, jid.bare_jid.to_string(), true);

        //If we don't blindly trust new devices and we haven't seen this key before then don't trust it
        bool untrust = !(blind_trust || db.identity_meta.with_address(identity_id, jid.bare_jid.to_string())
                .with(db.identity_meta.device_id, "=", device_id)
                .with(db.identity_meta.identity_key_public_base64, "=", Base64.encode(bundle.identity_key.serialize()))
                .single().row().is_present());

        //Get trust information from the database if the device id is known
        Row device = db.identity_meta.get_device(identity_id, jid.bare_jid.to_string(), device_id);
        TrustLevel trusted = TrustLevel.UNKNOWN;
        if (device != null) {
            trusted = (TrustLevel) device[db.identity_meta.trust_level];
        }

        if(untrust) {
            trusted = TrustLevel.UNKNOWN;
        } else if (blind_trust && trusted == TrustLevel.UNKNOWN) {
            trusted = TrustLevel.TRUSTED;
        }

        //Update the database with the appropriate trust information
        db.identity_meta.insert_device_bundle(identity_id, jid.bare_jid.to_string(), device_id, bundle, trusted);

        if (should_start_session(account, jid)) {
            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream != null) {
                BaseStreamModule? module = get_module_from_stream(stream, bundle.version);
                if (module != null) {
                    module.start_session(stream, jid, device_id, bundle);
                }
            }
        }
        continue_message_sending(account, jid);
    }

    private BaseStreamModule? get_module_from_stream(XmppStream stream, ProtocolVersion version) {
        switch (version) {
            case ProtocolVersion.LEGACY: return stream.get_module(Legacy.StreamModule.IDENTITY);
            case ProtocolVersion.V1: return stream.get_module(V1.StreamModule.IDENTITY);
        }
        return null;
    }

    private bool should_start_session(Account account, Jid jid) {
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {
                if (!msg.account.equals(account)) continue;
                Gee.List<Jid> occupants = get_occupants(msg.counterpart.bare_jid, account);
                if (account.bare_jid.equals(jid) || (msg.counterpart != null && (msg.counterpart.equals_bare(jid) || occupants.contains(jid)))) {
                    return true;
                }
            }
        }
        return false;
    }

    private void continue_message_sending(Account account, Jid jid) {
        //Get all messages waiting and determine if they can now be sent
        HashSet<Entities.Message> send_now = new HashSet<Entities.Message>();
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {
                if (!msg.account.equals(account)) continue;
                Gee.List<Jid> occupants = get_occupants(msg.counterpart.bare_jid, account);

                MessageState state = message_states[msg];

                if (account.bare_jid.equals(jid)) {
                    state.waiting_own_sessions--;
                } else if (msg.counterpart != null && (msg.counterpart.equals_bare(jid) || occupants.contains(jid))) {
                    state.waiting_other_sessions--;
                }
                if (state.should_retry_now()){
                    send_now.add(msg);
                    state.active_send_attempt = true;
                }
            }
        }
        foreach (Entities.Message msg in send_now) {
            if (msg.counterpart == null) continue;
            Entities.Conversation? conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation((!)msg.counterpart, account);
            if (conv == null) continue;
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(msg, (!)conv, true);
        }
    }

    private async void initialize_store(Account account) {
        // If the account is not yet persisted, wait for that and then continue - without identity.account_id the entry isn't worth much.
        if (account.id == -1) {
            account.notify["id"].connect(() => initialize_store.callback());
            yield;
        }
        Store store = null;
        Legacy.StreamModule? legacy_module = stream_interactor.module_manager.get_module(account, Legacy.StreamModule.IDENTITY);
        V1.StreamModule? v1_module = stream_interactor.module_manager.get_module(account, V1.StreamModule.IDENTITY);
        if (legacy_module != null) {
            store = legacy_module.store;
        }
        if (v1_module != null) {
            if (store != null) {
                v1_module.store = store;
            } else {
                store = v1_module.store;
            }
        }
        if (store == null) return;
        Qlite.Row? row = db.identity.row_with(db.identity.account_id, account.id).inner;
        int identity_id = -1;
        bool publish_identity = false;

        if (row == null) {
            // OMEMO not yet initialized, starting with empty base
            publish_identity = true;
            try {
                store.identity_key_store.local_registration_id = Random.int_range(1, int32.MAX);

                ECKeyPair key_pair = Plugin.get_context().generate_key_pair();
                store.identity_key_store.identity_key_private = new Bytes(key_pair.private.serialize());
                store.identity_key_store.identity_key_public = new Bytes(key_pair.public.serialize());

                identity_id = (int) db.identity.insert().or("REPLACE")
                        .value(db.identity.account_id, account.id)
                        .value(db.identity.device_id, (int) store.local_registration_id)
                        .value(db.identity.identity_key_private_base64, Base64.encode(store.identity_key_store.identity_key_private.get_data()))
                        .value(db.identity.identity_key_public_base64, Base64.encode(store.identity_key_store.identity_key_public.get_data()))
                        .perform();
            } catch (Error e) {
                // Ignore error
            }
        } else {
            store.identity_key_store.local_registration_id = ((!)row)[db.identity.device_id];
            store.identity_key_store.identity_key_private = new Bytes(Base64.decode(((!)row)[db.identity.identity_key_private_base64]));
            store.identity_key_store.identity_key_public = new Bytes(Base64.decode(((!)row)[db.identity.identity_key_public_base64]));
            identity_id = ((!)row)[db.identity.id];
        }

        if (identity_id >= 0) {
            store.signed_pre_key_store = new BackedSignedPreKeyStore(db, identity_id);
            store.pre_key_store = new BackedPreKeyStore(db, identity_id);
            store.session_store = new BackedSessionStore(db, identity_id);
        } else {
            warning("store for %s is not persisted!", account.bare_jid.to_string());
        }

        // Generated new device ID, ensure this gets added to the devicelist
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            if (legacy_module != null) {
                legacy_module.request_user_devicelist.begin((!)stream, account.bare_jid);
            }
            if (v1_module != null) {
                v1_module.request_user_devicelist.begin((!)stream, account.bare_jid);
            }
        }
    }

    public async bool ensure_get_keys_for_conversation(Conversation conversation) {
        if (stream_interactor.get_module(MucManager.IDENTITY).is_private_room(conversation.account, conversation.counterpart)) {
            foreach (Jid offline_member in stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account)) {
                bool ok = yield ensure_get_keys_for_jid(conversation.account, offline_member);
                if (!ok) {
                    return false;
                }
            }
            return true;
        }

        return yield ensure_get_keys_for_jid(conversation.account, conversation.counterpart.bare_jid);
    }

    public async bool ensure_get_keys_for_jid(Account account, Jid jid) {
        if (trust_manager.is_known_address(account, jid)) return true;
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            var legacy_module = stream_interactor.module_manager.get_module(account, Legacy.StreamModule.IDENTITY);
            if (legacy_module != null) {
                if ((yield legacy_module.request_user_devicelist(stream, jid)).size > 0) return true;
            }
            var v1_module = stream_interactor.module_manager.get_module(account, V1.StreamModule.IDENTITY);
            if (legacy_module != null) {
                if ((yield v1_module.request_user_devicelist(stream, jid)).size > 0) return true;
            }
            return false;
        }
        return true; // TODO wait for stream?
    }

    public static void start(StreamInteractor stream_interactor, Database db, TrustManager trust_manager) {
        Manager m = new Manager(stream_interactor, db, trust_manager);
        stream_interactor.add_module(m);
    }
}

}
