using Dino.Entities;
using Signal;
using Qlite;
using Xmpp;
using Gee;

namespace Dino.Plugins.Omemo {

public class Manager : StreamInteractionModule, Object {
    public const string id = "omemo_manager";

    private StreamInteractor stream_interactor;
    private Database db;
    private ArrayList<Entities.Message> to_send_after_devicelist = new ArrayList<Entities.Message>();
    private ArrayList<Entities.Message> to_send_after_session = new ArrayList<Entities.Message>();

    private Manager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.account_added.connect(on_account_added);
        MessageManager.get_instance(stream_interactor).pre_message_received.connect(on_pre_message_received);
        MessageManager.get_instance(stream_interactor).pre_message_send.connect(on_pre_message_send);
    }

    private void on_pre_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
        if (MessageFlag.get_flag(message_stanza) != null && MessageFlag.get_flag(message_stanza).decrypted) {
            message.encryption = Encryption.OMEMO;
        }
    }

    private void on_pre_message_send(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
        if (message.encryption == Encryption.OMEMO) {
            StreamModule module = stream_interactor.get_stream(conversation.account).get_module(StreamModule.IDENTITY);
            EncryptStatus status = module.encrypt(message_stanza, conversation.account.bare_jid.to_string());
            if (status.other_failure > 0 || (status.other_lost == status.other_devices && status.other_devices > 0)) {
                message.marked = Entities.Message.Marked.WONTSEND;
            } else if (status.other_unknown > 0 || status.own_devices == 0) {
                message.marked = Entities.Message.Marked.UNSENT;
            } else if (!status.encrypted) {
                message.marked = Entities.Message.Marked.WONTSEND;
            }

            if (status.other_unknown > 0) {
                bool cont = true;
                lock(to_send_after_session) {
                    foreach(Entities.Message msg in to_send_after_session) {
                        if (msg.counterpart.bare_jid.to_string() == message.counterpart.bare_jid.to_string()) cont = false;
                    }
                    to_send_after_session.add(message);
                }
                if (cont) module.start_sessions_with(stream_interactor.get_stream(conversation.account), message.counterpart.bare_jid.to_string());
            }
            if (status.own_unknown > 0) {
                module.start_sessions_with(stream_interactor.get_stream(conversation.account), conversation.account.bare_jid.to_string());
            }
            if (status.own_devices == 0) {
                lock (to_send_after_session) {
                    to_send_after_devicelist.add(message);
                }
            }
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).store_created.connect((store) => on_store_created(account, store));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).device_list_loaded.connect(() => on_device_list_loaded(account));
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).session_started.connect((jid, device_id) => on_session_started(account, jid));
    }

    private void on_session_started(Account account, string jid) {
        lock(to_send_after_session) {
            Iterator<Entities.Message> iter = to_send_after_session.iterator();
            while (iter.next()) {
                Entities.Message msg = iter.get();
                if (msg.account.bare_jid.to_string() == account.bare_jid.to_string() && msg.counterpart.bare_jid.to_string() == jid) {
                    Entities.Conversation conv = ConversationManager.get_instance(stream_interactor).get_conversation(msg.counterpart, account);
                    MessageManager.get_instance(stream_interactor).send_xmpp_message(msg, conv, true);
                    iter.remove();
                }
            }
        }
    }

    private void on_device_list_loaded(Account account) {
        lock(to_send_after_devicelist) {
            Iterator<Entities.Message> iter = to_send_after_devicelist.iterator();
            while (iter.next()) {
                Entities.Message msg = iter.get();
                if (msg.account.bare_jid.to_string() == account.bare_jid.to_string()) {
                    Entities.Conversation conv = ConversationManager.get_instance(stream_interactor).get_conversation(msg.counterpart, account);
                    MessageManager.get_instance(stream_interactor).send_xmpp_message(msg, conv, true);
                    iter.remove();
                }
            }
        }
    }

    private void on_store_created(Account account, Store store) {
        Qlite.Row? row = null;
        try {
            row = db.identity.row_with(db.identity.account_id, account.id).inner;
        } catch (Error e) {
            // Ignore error
        }
        int identity_id = -1;

        if (row == null) {
            // OMEMO not yet initialized, starting with empty base
            try {
                store.identity_key_store.local_registration_id = Random.int_range(1, int32.MAX);

                Signal.ECKeyPair key_pair = Plugin.context.generate_key_pair();
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
            store.identity_key_store.local_registration_id = row[db.identity.device_id];
            store.identity_key_store.identity_key_private = Base64.decode(row[db.identity.identity_key_private_base64]);
            store.identity_key_store.identity_key_public = Base64.decode(row[db.identity.identity_key_public_base64]);
            identity_id = row[db.identity.id];
        }

        if (identity_id >= 0) {
            store.signed_pre_key_store = new BackedSignedPreKeyStore(db, identity_id);
            store.pre_key_store = new BackedPreKeyStore(db, identity_id);
            store.session_store = new BackedSessionStore(db, identity_id);
        } else {
            print(@"WARN: OMEMO store for $(account.bare_jid) is not persisted");
        }
    }


    public bool can_encrypt(Entities.Conversation conversation) {
        return stream_interactor.get_stream(conversation.account).get_module(StreamModule.IDENTITY).is_known_address(conversation.counterpart.bare_jid.to_string());
    }

    internal string get_id() {
        return id;
    }

    public static void start(StreamInteractor stream_interactor, Database db) {
        Manager m = new Manager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public static Manager? get_instance(StreamInteractor stream_interactor) {
        return (Manager) stream_interactor.get_module(id);
    }
}

}