using Xmpp;
using Gee;
using Qlite;

using Dino.Entities;

namespace Dino {

    public class OccupantIdStore : StreamInteractionModule, Object {
        public static ModuleIdentity<OccupantIdStore> IDENTITY = new ModuleIdentity<OccupantIdStore>("occupant_id_cache");
        public string id { get { return IDENTITY.id; } }

        private Database db;

        // (Account, MUC JID, occupant id) -> occupant db id
        private HashMap<Account, HashMap<Jid, HashMap<string, int>>> occupant_db_ids = new HashMap<Account, HashMap<Jid, HashMap<string, int>>>(Account.hash_func, Account.equals_func);
        private HashMap<int, string> occupant_nicks = new HashMap<int, string>();

        public static void start(StreamInteractor stream_interactor, Database db) {
            OccupantIdStore m = new OccupantIdStore(db);
            stream_interactor.add_module(m);
        }

        private OccupantIdStore(Database db) {
            this.db = db;
        }

        public int get_occupant_db_id(Account account, string occupant_id, Jid muc_jid) {
            if (!occupant_db_ids.has_key(account) || !occupant_db_ids[account].has_key(muc_jid) || !occupant_db_ids[account][muc_jid].has_key(occupant_id)) {
                warning("Requested unknown occupant db id");
                return -1;
            }

            return occupant_db_ids[account][muc_jid][occupant_id];
        }

        public int cache_occupant_id(Account account, string occupant_id, Jid occupant_jid) {
            string last_nick = occupant_jid.resourcepart;
            Jid muc_jid = occupant_jid.bare_jid;

            if (occupant_db_ids.has_key(account) && occupant_db_ids[account].has_key(muc_jid) && occupant_db_ids[account][muc_jid].has_key(occupant_id)) {
                int occupant_db_id = occupant_db_ids[account][muc_jid][occupant_id];
                if (occupant_nicks[occupant_db_id] == last_nick) {
                    return occupant_db_id;
                }
            }

            if (!occupant_db_ids.has_key(account)) occupant_db_ids[account] = new HashMap<Jid, HashMap<string, int>>(Jid.hash_bare_func, Jid.equals_bare_func);
            if (!occupant_db_ids[account].has_key(muc_jid)) occupant_db_ids[account][muc_jid] = new HashMap<string, int>();

            int muc_jid_id = db.get_jid_id(muc_jid);

            RowOption row = db.occupantid.select()
                .with(db.occupantid.account_id, "=", account.id)
                .with(db.occupantid.jid_id, "=", muc_jid_id)
                .with(db.occupantid.occupant_id, "=", occupant_id)
                .single().row();

            int occupant_db_id = -1;
            if (row.is_present()) {
                occupant_db_id = row[db.occupantid.id];

                if (row[db.occupantid.last_nick] != last_nick) {
                    db.occupantid.upsert()
                            .value(db.occupantid.account_id, account.id, true)
                            .value(db.occupantid.jid_id, muc_jid_id, true)
                            .value(db.occupantid.occupant_id, occupant_id, true)
                        .value(db.occupantid.last_nick, last_nick, false)
                        .perform();
                }
            } else {
                occupant_db_id = (int)db.occupantid.upsert()
                    .value(db.occupantid.account_id, account.id, true)
                    .value(db.occupantid.jid_id, muc_jid_id, true)
                    .value(db.occupantid.occupant_id, occupant_id, true)
                    .value(db.occupantid.last_nick, muc_jid.resourcepart, false)
                    .perform();
            }

            occupant_db_ids[account][muc_jid][occupant_id] = occupant_db_id;
            occupant_nicks[occupant_db_id] = last_nick;

            return occupant_db_id;
        }


    }
}