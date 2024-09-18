using Dino.Entities;
using Qlite;
using Gee;
using Signal;
using Xmpp;

namespace Dino.Plugins.Omemo {

    public class OmemoDecryptor : Xep.Omemo.OmemoDecryptor {

        private Account account;
        private Store store;
        private Database db;
        private StreamInteractor stream_interactor;
        private TrustManager trust_manager;

        public override uint32 own_device_id { get { return store.local_registration_id; }}

        public OmemoDecryptor(Account account, StreamInteractor stream_interactor, TrustManager trust_manager, Database db, Store store) {
            this.account = account;
            this.stream_interactor = stream_interactor;
            this.trust_manager = trust_manager;
            this.db = db;
            this.store = store;
        }

        public bool decrypt_message(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            StanzaNode? encrypted_node = stanza.stanza.get_subnode("encrypted", NS_URI);
            if (encrypted_node == null || MessageFlag.get_flag(stanza) != null || stanza.from == null) return false;

            if (!Plugin.ensure_context()) return false;
            int identity_id = db.identity.get_id(conversation.account.id);

            MessageFlag flag = new MessageFlag();
            stanza.add_flag(flag);

            Xep.Omemo.ParsedData? data = parse_node(encrypted_node);
            if (data == null) return false;


            foreach (Bytes encr_key in data.our_potential_encrypted_keys.keys) {
                data.is_prekey = data.our_potential_encrypted_keys[encr_key];
                data.encrypted_key = encr_key.get_data();
                Gee.List<Jid> possible_jids = get_potential_message_jids(message, data, identity_id);
                if (possible_jids.size == 0) {
                    debug("Received message from unknown entity with device id %d", data.sid);
                }

                foreach (Jid possible_jid in possible_jids) {
                    try {
                        uint8[] key = decrypt_key(data, possible_jid);
                        if (data.ciphertext != null) {
                            string cleartext = arr_to_str(aes_decrypt(Cipher.AES_GCM_NOPADDING, key, data.iv, data.ciphertext));
                            message.body = cleartext;
                        }

                        // If we figured out which real jid a message comes from due to decryption working, save it
                        if (conversation.type_ == Conversation.Type.GROUPCHAT && message.real_jid == null) {
                            message.real_jid = possible_jid;
                        }

                        message.encryption = Encryption.OMEMO;

                        trust_manager.message_device_id_map[message] = data.sid;
                        return true;
                    } catch (Error e) {
                        debug("Decrypting message from %s/%d failed: %s", possible_jid.to_string(), data.sid, e.message);
                    }
                }
            }

            if (
                data.ciphertext != null && // Ratchet forwarding doesn't contain payload and might not include us, which is ok
                data.our_potential_encrypted_keys.size == 0 && // The message was not encrypted to us
                stream_interactor.module_manager.get_module(message.account, StreamModule.IDENTITY).store.local_registration_id != data.sid // Message from this device. Never encrypted to itself.
            ) {
                db.identity_meta.update_last_message_undecryptable(identity_id, data.sid, message.time);
                trust_manager.bad_message_state_updated(conversation.account, message.from, data.sid);
            }

            debug("Received OMEMO encryped message that could not be decrypted.");
            return false;
        }

        public Gee.List<Jid> get_potential_message_jids(Entities.Message message, Xmpp.Xep.Omemo.ParsedData data, int identity_id) {
            Gee.List<Jid> possible_jids = new ArrayList<Jid>();
            if (message.type_ == Message.Type.CHAT) {
                possible_jids.add(message.from.bare_jid);
            } else {
                if (message.real_jid != null) {
                    possible_jids.add(message.real_jid.bare_jid);
                } else if (data.is_prekey) {
                    // pre key messages do store the identity key, so we can use that to find the real jid
                    PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(data.encrypted_key);
                    string identity_key = Base64.encode(msg.identity_key.serialize());
                    foreach (Row row in db.identity_meta.get_with_device_id(identity_id, data.sid).with(db.identity_meta.identity_key_public_base64, "=", identity_key)) {
                        try {
                            possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                        } catch (InvalidJidError e) {
                            warning("Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                } else {
                    // If we don't know the device name (MUC history w/o MAM), test decryption with all keys with fitting device id
                    foreach (Row row in db.identity_meta.get_with_device_id(identity_id, data.sid)) {
                        try {
                            possible_jids.add(new Jid(row[db.identity_meta.address_name]));
                        } catch (InvalidJidError e) {
                            warning("Ignoring invalid jid from database: %s", e.message);
                        }
                    }
                }
            }
            return possible_jids;
        }

        public override uint8[] decrypt_key(Xmpp.Xep.Omemo.ParsedData data, Jid from_jid) throws GLib.Error {
            int sid = data.sid;
            uint8[] ciphertext = data.ciphertext;
            uint8[] encrypted_key = data.encrypted_key;

            Address address = new Address(from_jid.to_string(), sid);
            uint8[] key;

            if (data.is_prekey) {
                int identity_id = db.identity.get_id(account.id);
                PreKeySignalMessage msg = Plugin.get_context().deserialize_pre_key_signal_message(encrypted_key);
                string identity_key = Base64.encode(msg.identity_key.serialize());

                bool ok = update_db_for_prekey(identity_id, identity_key, from_jid, sid);
                if (!ok) throw new GLib.Error(-1, 0, "Failed updating db for prekey");

                debug("Starting new session for decryption with device from %s/%d", from_jid.to_string(), sid);
                SessionCipher cipher = store.create_session_cipher(address);
                key = cipher.decrypt_pre_key_signal_message(msg);
                // TODO: Finish session
            } else {
                debug("Continuing session for decryption with device from %s/%d", from_jid.to_string(), sid);
                SignalMessage msg = Plugin.get_context().deserialize_signal_message(encrypted_key);
                SessionCipher cipher = store.create_session_cipher(address);
                key = cipher.decrypt_signal_message(msg);
            }

            if (key.length >= 32) {
                int authtaglength = key.length - 16;
                uint8[] new_ciphertext = new uint8[ciphertext.length + authtaglength];
                uint8[] new_key = new uint8[16];
                Memory.copy(new_ciphertext, ciphertext, ciphertext.length);
                Memory.copy((uint8*)new_ciphertext + ciphertext.length, (uint8*)key + 16, authtaglength);
                Memory.copy(new_key, key, 16);
                data.ciphertext = new_ciphertext;
                key = new_key;
            }

            return key;
        }

        public override string decrypt(uint8[] ciphertext, uint8[] key, uint8[] iv) throws GLib.Error {
            return arr_to_str(aes_decrypt(Cipher.AES_GCM_NOPADDING, key, iv, ciphertext));
        }

        private bool update_db_for_prekey(int identity_id, string identity_key, Jid from_jid, int sid) {
            Row? device = db.identity_meta.get_device(identity_id, from_jid.to_string(), sid);
            if (device != null && device[db.identity_meta.identity_key_public_base64] != null) {
                if (device[db.identity_meta.identity_key_public_base64] != identity_key) {
                    critical("Tried to use a different identity key for a known device id.");
                    return false;
                }
            } else {
                debug("Learn new device from incoming message from %s/%d", from_jid.to_string(), sid);
                bool blind_trust = db.trust.get_blind_trust(identity_id, from_jid.to_string(), true);
                if (db.identity_meta.insert_device_session(identity_id, from_jid.to_string(), sid, identity_key, blind_trust ? TrustLevel.TRUSTED : TrustLevel.UNKNOWN) < 0) {
                    critical("Failed learning a device.");
                    return false;
                }

                XmppStream? stream = stream_interactor.get_stream(account);
                if (device == null && stream != null) {
                    stream.get_module(StreamModule.IDENTITY).request_user_devicelist.begin(stream, from_jid);
                }
            }
            return true;
        }

        private string arr_to_str(uint8[] arr) {
            // null-terminate the array
            uint8[] rarr = new uint8[arr.length+1];
            Memory.copy(rarr, arr, arr.length);
            return (string)rarr;
        }
    }

    public class DecryptMessageListener : MessageListener {
        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private HashMap<Account, OmemoDecryptor> decryptors;

        public DecryptMessageListener(HashMap<Account, OmemoDecryptor> decryptors) {
            this.decryptors = decryptors;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            decryptors[message.account].decrypt_message(message, stanza, conversation);
            return false;
        }
    }
}

