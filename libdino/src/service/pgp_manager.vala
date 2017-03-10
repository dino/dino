using Gee;

using Dino.Entities;

namespace Dino {
    public class PgpManager : StreamInteractionModule, Object {
        public const string id = "pgp_manager";

        public const string MESSAGE_ENCRYPTED = "pgp";

        private StreamInteractor stream_interactor;
        private Database db;
        private HashMap<Jid, string> pgp_key_ids = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

        public static void start(StreamInteractor stream_interactor, Database db) {
            PgpManager m = new PgpManager(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        private PgpManager(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;

            stream_interactor.account_added.connect(on_account_added);
        }

        public string? get_key_id(Account account, Jid jid) {
            return db.get_pgp_key(jid);
        }

        public static PgpManager? get_instance(StreamInteractor stream_interactor) {
            return (PgpManager) stream_interactor.get_module(id);
        }

        internal string get_id() {
            return id;
        }

        private void on_account_added(Account account) {
            stream_interactor.module_manager.pgp_modules[account].received_jid_key_id.connect((stream, jid, key_id) => {
                on_jid_key_received(account, new Jid(jid), key_id);
            });
        }

        private void on_jid_key_received(Account account, Jid jid, string key_id) {
            if (!pgp_key_ids.has_key(jid) || pgp_key_ids[jid] != key_id) {
                if (!MucManager.get_instance(stream_interactor).is_groupchat_occupant(jid, account)) {
                    db.set_pgp_key(jid.bare_jid, key_id);
                }
            }
            pgp_key_ids[jid] = key_id;
        }
    }
}