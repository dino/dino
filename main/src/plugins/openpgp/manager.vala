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
    private ReceivedMessageListener received_message_listener = new ReceivedMessageListener();

    public static void start(StreamInteractor stream_interactor, Database db) {
        Manager m = new Manager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private Manager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(received_message_listener);
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
        Qlite.RowOption key_row = db.get_contact_key_row(search_jid);
        if (!key_row.is_present()) return null;
        string? key_id = key_row.get(db.contact_key_table.key);
        if (key_id != null) return key_id;
        string? sig = key_row.get(db.contact_key_table.sig);
        string? signed_data = key_row.get(db.contact_key_table.signed_data);
        if (sig == null || signed_data == null) return null;
        key_id = get_sign_key(sig, signed_data);
        if (key_id != null) {
            db.set_contact_key(search_jid, key_id);
        }
        return key_id;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Module.IDENTITY).received_jid_presence_signature.connect((stream, jid, sig, signed_data) => {
            on_jid_signature_received(account, jid, sig, signed_data);
        });
    }

    private void on_jid_signature_received(Account account, Jid jid, string sig, string signed_data) {
        Jid set_jid = stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid, account) ? jid : jid.bare_jid;
        db.set_contact_signature(set_jid, sig, signed_data);
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (MessageFlag.get_flag(stanza) != null && MessageFlag.get_flag(stanza).decrypted) {
                message.encryption = Encryption.PGP;
            }
            return false;
        }
    }
}

}
