using Dino.Entities;
using Signal;
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
    private ReceivedMessageListener received_message_listener = new ReceivedMessageListener();

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
            this.msg = msg;
            this.last_try = last_try;
            update_from_encrypt_status(last_try);
        }

        public void update_from_encrypt_status(EncryptState new_try) {
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
            return @"MessageState (waiting=(others=$waiting_other_sessions, own=$waiting_own_sessions, other_lists=$waiting_other_devicelists, own_list=$waiting_own_devicelist))";
        }
    }

    private Manager(StreamInteractor stream_interactor, Database db, TrustManager trust_manager) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.trust_manager = trust_manager;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_send.connect(on_pre_message_send);
        stream_interactor.get_module(RosterManager.IDENTITY).mutual_subscription.connect(on_mutual_subscription);
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            MessageFlag? flag = MessageFlag.get_flag(stanza);
            if (flag != null && ((!)flag).decrypted) {
                message.encryption = Encryption.OMEMO;
            }
            return false;
        }
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
            StreamModule? module_ = ((!)stream).get_module(StreamModule.IDENTITY);
            if (module_ == null) {
                message.marked = Entities.Message.Marked.UNSENT;
                return;
            }
            StreamModule module = (!)module_;

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
                    state.update_from_encrypt_status(enc_state);
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
                    if (Plugin.DEBUG) print(@"OMEMO: message was not sent: $state\n");
                    message_states.unset(message);
                } else {
                    if (Plugin.DEBUG) print(@"OMEMO: message will be delayed: $state\n");

                    if (state.waiting_own_sessions > 0) {
                        module.fetch_bundles((!)stream, conversation.account.bare_jid, trust_manager.get_trusted_devices(conversation.account, conversation.account.bare_jid));
                    }
                    if (state.waiting_other_sessions > 0 && message.counterpart != null) {
                        foreach(Jid jid in get_occupants(((!)message.counterpart).bare_jid, conversation.account)) {
                            module.fetch_bundles((!)stream, jid, trust_manager.get_trusted_devices(conversation.account, jid));
                        }
                    }
                    if (state.waiting_other_devicelists > 0 && message.counterpart != null) {
                        foreach(Jid jid in get_occupants(((!)message.counterpart).bare_jid, conversation.account)) {
                            module.request_user_devicelist((!)stream, jid);
                        }
                    }
                }
            }
        }
    }

    private void on_mutual_subscription(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if(stream == null) return;

        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).request_user_devicelist((!)stream, jid);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).store_created.connect((store) => on_store_created(account, store));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).device_list_loaded.connect((jid, devices) => on_device_list_loaded(account, jid, devices));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).bundle_fetched.connect((jid, device_id, bundle) => on_bundle_fetched(account, jid, device_id, bundle));
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).request_user_devicelist(stream, account.bare_jid);
    }

    private void on_device_list_loaded(Account account, Jid jid, ArrayList<int32> device_list) {
        if (Plugin.DEBUG) print(@"OMEMO: received device list for $(account.bare_jid) from $jid\n");

        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return;
        }
        StreamModule? module = ((!)stream).get_module(StreamModule.IDENTITY);
        if (module == null) {
            return;
        }

        //Update meta database
        db.identity_meta.insert_device_list(account.id, jid.bare_jid.to_string(), device_list);

        //Fetch the bundle for each new device
        int inc = 0;
        foreach (Row row in db.identity_meta.get_unknown_devices(account.id, jid.bare_jid.to_string())) {
            module.fetch_bundle(stream, Jid.parse(row[db.identity_meta.address_name]), row[db.identity_meta.device_id]);
            inc++;
        }
        if (inc > 0) {
            if (Plugin.DEBUG) print(@"OMEMO: new bundles $inc/$(device_list.size) for $jid\n");
        }

        //Create an entry for the jid in the account table if one does not exist already
        if (db.trust.select().with(db.trust.identity_id, "=", account.id).with(db.trust.address_name, "=", jid.bare_jid.to_string()).count() == 0) {
            db.trust.insert().value(db.trust.identity_id, account.id).value(db.trust.address_name, jid.bare_jid.to_string()).value(db.trust.blind_trust, true).perform();
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

    public void on_bundle_fetched(Account account, Jid jid, int32 device_id, Bundle bundle) {
        bool blind_trust = db.trust.get_blind_trust(account.id, jid.bare_jid.to_string());

        //If we don't blindly trust new devices and we haven't seen this key before then don't trust it
        bool untrust = !(blind_trust || db.identity_meta.with_address(account.id, jid.bare_jid.to_string())
                .with(db.identity_meta.device_id, "=", device_id)
                .with(db.identity_meta.identity_key_public_base64, "=", Base64.encode(bundle.identity_key.serialize()))
                .single().row().is_present());

        //Get trust information from the database if the device id is known
        Row device = db.identity_meta.get_device(account.id, jid.bare_jid.to_string(), device_id);
        Database.IdentityMetaTable.TrustLevel trusted = Database.IdentityMetaTable.TrustLevel.UNKNOWN;
        if (device != null) {
            trusted = (Database.IdentityMetaTable.TrustLevel) device[db.identity_meta.trust_level];
        }

        if(untrust) {
            trusted = Database.IdentityMetaTable.TrustLevel.UNKNOWN;
        } else if (blind_trust && trusted == Database.IdentityMetaTable.TrustLevel.UNKNOWN) {
            trusted = Database.IdentityMetaTable.TrustLevel.TRUSTED;
        }

        //Update the database with the appropriate trust information
        db.identity_meta.insert_device_bundle(account.id, jid.bare_jid.to_string(), device_id, bundle, trusted);

        XmppStream? stream = stream_interactor.get_stream(account);
        if(stream == null) return;
        StreamModule? module = ((!)stream).get_module(StreamModule.IDENTITY);
        if(module == null) return;

        //Get all messages waiting on the bundle and determine if they can now be sent
        HashSet<Entities.Message> send_now = new HashSet<Entities.Message>();
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {

                bool session_created = true;
                if (!msg.account.equals(account)) continue;
                Gee.List<Jid> occupants = get_occupants(msg.counterpart.bare_jid, account);

                MessageState state = message_states[msg];

                if (trusted == Database.IdentityMetaTable.TrustLevel.TRUSTED || trusted == Database.IdentityMetaTable.TrustLevel.VERIFIED) {
                    if(account.bare_jid.equals(jid) || (msg.counterpart != null && (msg.counterpart.equals_bare(jid) || occupants.contains(jid)))) {
                        session_created = module.start_session(stream, jid, device_id, bundle);
                    }
                }
                if (account.bare_jid.equals(jid) && session_created) {
                    state.waiting_own_sessions--;
                } else if (msg.counterpart != null && (msg.counterpart.equals_bare(jid) || occupants.contains(jid)) && session_created) {
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

    private void on_store_created(Account account, Store store) {
        Qlite.Row? row = db.identity.row_with(db.identity.account_id, account.id).inner;
        int identity_id = -1;
        bool publish_identity = false;

        if (row == null) {
            // OMEMO not yet initialized, starting with empty base
            publish_identity = true;
            try {
                store.identity_key_store.local_registration_id = Random.int_range(1, int32.MAX);

                Signal.ECKeyPair key_pair = Plugin.get_context().generate_key_pair();
                store.identity_key_store.identity_key_private = key_pair.private.serialize();
                store.identity_key_store.identity_key_public = key_pair.public.serialize();

                identity_id = (int) db.identity.insert().or("REPLACE")
                        .value(db.identity.account_id, account.id)
                        .value(db.identity.device_id, (int) store.local_registration_id)
                        .value(db.identity.identity_key_private_base64, Base64.encode(store.identity_key_store.identity_key_private))
                        .value(db.identity.identity_key_public_base64, Base64.encode(store.identity_key_store.identity_key_public))
                        .perform();
            } catch (Error e) {
                // Ignore error
            }
        } else {
            store.identity_key_store.local_registration_id = ((!)row)[db.identity.device_id];
            store.identity_key_store.identity_key_private = Base64.decode(((!)row)[db.identity.identity_key_private_base64]);
            store.identity_key_store.identity_key_public = Base64.decode(((!)row)[db.identity.identity_key_public_base64]);
            identity_id = ((!)row)[db.identity.id];
        }

        if (identity_id >= 0) {
            store.signed_pre_key_store = new BackedSignedPreKeyStore(db, identity_id);
            store.pre_key_store = new BackedPreKeyStore(db, identity_id);
            store.session_store = new BackedSessionStore(db, identity_id);
        } else {
            print(@"OMEMO: store for $(account.bare_jid) is not persisted!");
        }

        // Generated new device ID, ensure this gets added to the devicelist
        if (publish_identity) {
            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return;
            StreamModule? module = ((!)stream).get_module(StreamModule.IDENTITY);
            if(module == null) return;
            module.request_user_devicelist(stream, account.bare_jid);
        }
    }


    public bool can_encrypt(Entities.Conversation conversation) {
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;
        if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)){
            Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
            if (flag == null) return false;
            if (flag.has_room_feature(conversation.counterpart, Xep.Muc.Feature.NON_ANONYMOUS) && flag.has_room_feature(conversation.counterpart, Xep.Muc.Feature.MEMBERS_ONLY)) {
                foreach(Jid jid in stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account)) {
                    if (!trust_manager.is_known_address(conversation.account, jid.bare_jid)) {
                        return false;
                    }
                }
                return true;
            } else {
                return false;
            }
        }
        return trust_manager.is_known_address(conversation.account, conversation.counterpart.bare_jid);
    }

    public static void start(StreamInteractor stream_interactor, Database db, TrustManager trust_manager) {
        Manager m = new Manager(stream_interactor, db, trust_manager);
        stream_interactor.add_module(m);
    }
}

}
