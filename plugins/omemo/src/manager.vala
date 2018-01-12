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
    private Map<Entities.Message, MessageState> message_states = new HashMap<Entities.Message, MessageState>(Entities.Message.hash_func, Entities.Message.equals_func);

    private class MessageState {
        public Entities.Message msg { get; private set; }
        public EncryptState last_try { get; private set; }
        public int waiting_other_sessions { get; set; }
        public int waiting_own_sessions { get; set; }
        public bool waiting_own_devicelist { get; set; }
        public bool waiting_other_devicelist { get; set; }
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
            this.waiting_other_devicelist = !new_try.own_list;
            this.active_send_attempt = false;
            will_send_now = false;
            if (new_try.other_failure > 0 || (new_try.other_lost == new_try.other_devices && new_try.other_devices > 0)) {
                msg.marked = Entities.Message.Marked.WONTSEND;
            } else if (new_try.other_unknown > 0 || new_try.own_devices == 0) {
                msg.marked = Entities.Message.Marked.UNSENT;
            } else if (!new_try.encrypted) {
                msg.marked = Entities.Message.Marked.WONTSEND;
            } else {
                will_send_now = true;
            }
        }

        public bool should_retry_now() {
            return !waiting_own_devicelist && !waiting_other_devicelist && waiting_other_sessions <= 0 && waiting_own_sessions <= 0 && !active_send_attempt;
        }

        public string to_string() {
            return @"MessageState (waiting=(others=$waiting_other_sessions, own=$waiting_own_sessions, other_list=$waiting_other_devicelist, own_list=$waiting_own_devicelist))";
        }
    }

    private Manager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_received.connect(on_pre_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_send.connect(on_pre_message_send);
    }

    private void on_pre_message_received(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        MessageFlag? flag = MessageFlag.get_flag(message_stanza);
        if (flag != null && ((!)flag).decrypted) {
            message.encryption = Encryption.OMEMO;
        }
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
            EncryptState enc_state = module.encrypt(message_stanza, conversation.account.bare_jid);
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

            if (!state.will_send_now) {
                if (message.marked == Entities.Message.Marked.WONTSEND) {
                    if (Plugin.DEBUG) print(@"OMEMO: message was not sent: $state\n");
                } else {
                    if (Plugin.DEBUG) print(@"OMEMO: message will be delayed: $state\n");

                    if (state.waiting_own_sessions > 0) {
                        module.start_sessions_with((!)stream, conversation.account.bare_jid);
                    }
                    if (state.waiting_other_sessions > 0 && message.counterpart != null) {
                        module.start_sessions_with((!)stream, ((!)message.counterpart).bare_jid);
                    }
                    if (state.waiting_other_devicelist && message.counterpart != null) {
                        module.request_user_devicelist((!)stream, ((!)message.counterpart).bare_jid);
                    }
                }
            }
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).store_created.connect((store) => on_store_created(account, store));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).device_list_loaded.connect((jid) => on_device_list_loaded(account, jid));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).bundle_fetched.connect((jid, device_id, bundle) => on_bundle_fetched(account, jid, device_id, bundle));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).session_started.connect((jid, device_id) => on_session_started(account, jid, false));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).session_start_failed.connect((jid, device_id) => on_session_started(account, jid, true));
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).request_user_devicelist(stream, account.bare_jid);
    }

    private void on_session_started(Account account, Jid jid, bool failed) {
        if (Plugin.DEBUG) print(@"OMEMO: session start between $(account.bare_jid) and $jid $(failed ? "failed" : "successful")\n");
        HashSet<Entities.Message> send_now = new HashSet<Entities.Message>();
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {
                if (!msg.account.equals(account)) continue;
                MessageState state = message_states[msg];
                if (account.bare_jid.equals(jid)) {
                    state.waiting_own_sessions--;
                } else if (msg.counterpart != null && msg.counterpart.equals_bare(jid)) {
                    state.waiting_other_sessions--;
                }
                if (state.should_retry_now()) {
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

    private void on_device_list_loaded(Account account, Jid jid) {
        if (Plugin.DEBUG) print(@"OMEMO: received device list for $(account.bare_jid) from $jid\n");
        HashSet<Entities.Message> send_now = new HashSet<Entities.Message>();
        lock (message_states) {
            foreach (Entities.Message msg in message_states.keys) {
                if (!msg.account.equals(account)) continue;
                MessageState state = message_states[msg];
                if (account.bare_jid.equals(jid)) {
                    state.waiting_own_devicelist = false;
                } else if (msg.counterpart != null && msg.counterpart.equals_bare(jid)) {
                    state.waiting_other_devicelist = false;
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

        // Update meta database
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) {
            return;
        }
        StreamModule? module = ((!)stream).get_module(StreamModule.IDENTITY);
        if (module == null) {
            return;
        }
        ArrayList<int32> device_list = module.get_device_list(jid);
        db.identity_meta.insert_device_list(jid.bare_jid.to_string(), device_list);
        int inc = 0;
        foreach (Row row in db.identity_meta.with_address(jid.bare_jid.to_string()).with_null(db.identity_meta.identity_key_public_base64)) {
            module.fetch_bundle(stream, Jid.parse(row[db.identity_meta.address_name]), row[db.identity_meta.device_id]);
            inc++;
        }
        if (inc > 0) {
            if (Plugin.DEBUG) print(@"OMEMO: new bundles $inc/$(device_list.size) for $jid\n");
        }
    }

    public void on_bundle_fetched(Account account, Jid jid, int32 device_id, Bundle bundle) {
        db.identity_meta.insert_device_bundle(jid.bare_jid.to_string(), device_id, bundle);
    }

    private void on_store_created(Account account, Store store) {
        Qlite.Row? row = db.identity.row_with(db.identity.account_id, account.id).inner;
        int identity_id = -1;

        if (row == null) {
            // OMEMO not yet initialized, starting with empty base
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
    }


    public bool can_encrypt(Entities.Conversation conversation) {
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;
        StreamModule? module = ((!)stream).get_module(StreamModule.IDENTITY);
        if (module == null) return false;
        return ((!)module).is_known_address(conversation.counterpart.bare_jid);
    }

    public static void start(StreamInteractor stream_interactor, Database db) {
        Manager m = new Manager(stream_interactor, db);
        stream_interactor.add_module(m);
    }
}

}
