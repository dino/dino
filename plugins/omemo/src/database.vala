using Gee;
using Qlite;

using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class Database : Qlite.Database {
    private const int VERSION = 1;

    public class IdentityMetaTable : Table {
        public Column<string> address_name = new Column.Text("address_name") { not_null = true };
        public Column<int> device_id = new Column.Integer("device_id") { not_null = true };
        public Column<string?> identity_key_public_base64 = new Column.Text("identity_key_public_base64");
        public Column<bool> trusted_identity = new Column.BoolInt("trusted_identity") { default = "0" };
        public Column<bool> now_active = new Column.BoolInt("now_active") { default = "1" };
        public Column<long> last_active = new Column.Long("last_active");

        internal IdentityMetaTable(Database db) {
            base(db, "identity_meta");
            init({address_name, device_id, identity_key_public_base64, trusted_identity, now_active, last_active});
            index("identity_meta_idx", {address_name, device_id}, true);
            index("identity_meta_list_idx", {address_name});
        }

        public QueryBuilder with_address(string address_name) throws DatabaseError {
            return select().with(this.address_name, "=", address_name);
        }

        public void insert_device_list(string address_name, ArrayList<int32> devices) throws DatabaseError {
            update().with(this.address_name, "=", address_name).set(now_active, false).perform();
            foreach (int32 device_id in devices) {
                upsert()
                        .value(this.address_name, address_name, true)
                        .value(this.device_id, device_id, true)
                        .value(this.now_active, true)
                        .value(this.last_active, (long) new DateTime.now_utc().to_unix())
                        .perform();
            }
        }

        public int64 insert_device_bundle(string address_name, int device_id, Bundle bundle) throws DatabaseError {
            if (bundle == null || bundle.identity_key == null) return -1;
            return upsert()
                    .value(this.address_name, address_name, true)
                    .value(this.device_id, device_id, true)
                    .value(this.identity_key_public_base64, Base64.encode(bundle.identity_key.serialize()))
                    .perform();
        }
    }

    public class IdentityTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { unique = true, not_null = true };
        public Column<int> device_id = new Column.Integer("device_id") { not_null = true };
        public Column<string> identity_key_private_base64 = new Column.NonNullText("identity_key_private_base64");
        public Column<string> identity_key_public_base64 = new Column.NonNullText("identity_key_public_base64");

        internal IdentityTable(Database db) {
            base(db, "identity");
            init({id, account_id, device_id, identity_key_private_base64, identity_key_public_base64});
        }
    }

    public class SignedPreKeyTable : Table {
        public Column<int> identity_id = new Column.Integer("identity_id") { not_null = true };
        public Column<int> signed_pre_key_id = new Column.Integer("signed_pre_key_id") { not_null = true };
        public Column<string> record_base64 = new Column.NonNullText("record_base64");

        internal SignedPreKeyTable(Database db) {
            base(db, "signed_pre_key");
            init({identity_id, signed_pre_key_id, record_base64});
            unique({identity_id, signed_pre_key_id});
            index("signed_pre_key_idx", {identity_id, signed_pre_key_id}, true);
        }
    }

    public class PreKeyTable : Table {
        public Column<int> identity_id = new Column.Integer("identity_id") { not_null = true };
        public Column<int> pre_key_id = new Column.Integer("pre_key_id") { not_null = true };
        public Column<string> record_base64 = new Column.NonNullText("record_base64");

        internal PreKeyTable(Database db) {
            base(db, "pre_key");
            init({identity_id, pre_key_id, record_base64});
            unique({identity_id, pre_key_id});
            index("pre_key_idx", {identity_id, pre_key_id}, true);
        }
    }

    public class SessionTable : Table {
        public Column<int> identity_id = new Column.Integer("identity_id") { not_null = true };
        public Column<string> address_name = new Column.NonNullText("name");
        public Column<int> device_id = new Column.Integer("device_id") { not_null = true };
        public Column<string> record_base64 = new Column.NonNullText("record_base64");

        internal SessionTable(Database db) {
            base(db, "session");
            init({identity_id, address_name, device_id, record_base64});
            unique({identity_id, address_name, device_id});
            index("session_idx", {identity_id, address_name, device_id}, true);
        }
    }

    public IdentityMetaTable identity_meta { get; private set; }
    public IdentityTable identity { get; private set; }
    public SignedPreKeyTable signed_pre_key { get; private set; }
    public PreKeyTable pre_key { get; private set; }
    public SessionTable session { get; private set; }

    public Database(string fileName) throws DatabaseError {
        base(fileName, VERSION);
        identity_meta = new IdentityMetaTable(this);
        identity = new IdentityTable(this);
        signed_pre_key = new SignedPreKeyTable(this);
        pre_key = new PreKeyTable(this);
        session = new SessionTable(this);
        init({identity_meta, identity, signed_pre_key, pre_key, session});
        exec("PRAGMA synchronous=0");
    }

    public override void migrate(long oldVersion) {
        // new table columns are added, outdated columns are still present
    }
}

}