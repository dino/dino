using Gee;
using Xmpp;

using Xmpp;
using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class Manager : StreamInteractionModule, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("pgp_manager");
    public string id { get { return IDENTITY.id; } }

    public const string MESSAGE_ENCRYPTED = "pgp";

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Jid, string> pgp_key_ids = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        Manager m = new Manager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private Manager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_received.connect(on_pre_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).pre_message_send.connect(check_encypt);
    }

    public GPG.Key[] get_key_fprs(Conversation conversation) throws Error {
        Gee.List<string> keys = new Gee.ArrayList<string>();
        keys.add(db.get_account_key(conversation.account));
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Gee.List<Jid> muc_jids = new Gee.ArrayList<Jid>();
            Gee.List<Jid>? occupants = stream_interactor.get_module(MucManager.IDENTITY).get_occupants(conversation.counterpart, conversation.account);
            if (occupants != null) muc_jids.add_all(occupants);
            Gee.List<Jid>? offline_members = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account);
            if (occupants != null) muc_jids.add_all(offline_members);

            foreach (Jid jid in muc_jids) {
                string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, jid);
                if (key_id != null && GPGHelper.get_keylist(key_id).size > 0 && !keys.contains(key_id)) {
                    keys.add(key_id);
                }
            }
        } else {
            string? key_id = get_key_id(conversation.account, conversation.counterpart);
            if (key_id != null) {
                keys.add(key_id);
            }
        }
        GPG.Key[] gpgkeys = new GPG.Key[keys.size];
        for (int i = 0; i < keys.size; i++) {
            try {
                GPG.Key key = GPGHelper.get_public_key(keys[i]);
                if (key != null) gpgkeys[i] = key;
            } catch (Error e)  {}
        }

        return gpgkeys;
    }

    private void on_pre_message_received(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (MessageFlag.get_flag(message_stanza) != null && MessageFlag.get_flag(message_stanza).decrypted) {
            message.encryption = Encryption.PGP;
        }
    }

    private void check_encypt(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        try {
            if (message.encryption == Encryption.PGP) {
                GPG.Key[] keys = get_key_fprs(conversation);
                XmppStream? stream = stream_interactor.get_stream(conversation.account);
                if (stream != null) {
                    bool encrypted = stream.get_module(Module.IDENTITY).encrypt(message_stanza, keys);
                    if (!encrypted) message.marked = Entities.Message.Marked.WONTSEND;
                }
            }
        } catch (Error e) {
            message.marked = Entities.Message.Marked.WONTSEND;
        }
    }

    public string? get_key_id(Account account, Jid jid) {
        Jid search_jid = stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid, account) ? jid : jid.bare_jid;
        return db.get_contact_key(search_jid);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Module.IDENTITY).received_jid_key_id.connect((stream, jid, key_id) => {
            on_jid_key_received(account, jid, key_id);
        });
    }

    private void on_jid_key_received(Account account, Jid jid, string key_id) {
        lock (pgp_key_ids) {
            if (!pgp_key_ids.has_key(jid) || pgp_key_ids[jid] != key_id) {
                Jid set_jid = stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid, account) ? jid : jid.bare_jid;
                db.set_contact_key(set_jid, key_id);
            }
            pgp_key_ids[jid] = key_id;
        }
    }
}

}
