using Gee;
using Qlite;

using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class Database : Qlite.Database {
    private const int VERSION = 2;

    public class IdentityMetaTable : Table {
        public enum TrustLevel {
            VERIFIED,
            TRUSTED,
            UNTRUSTED,
            UNKNOWN;

            public string to_string() {
                int val = this;
                return val.to_string();
            }
        }

        //Default to provide backwards compatability
        public Column<int> identity_id = new Column.Integer("identity_id") { not_null = true, min_version = 2, default = "-1" };
        public Column<string> address_name = new Column.Text("address_name") { not_null = true };
        public Column<int> device_id = new Column.Integer("device_id") { not_null = true };
        public Column<string?> identity_key_public_base64 = new Column.Text("identity_key_public_base64");
        public Column<bool> trusted_identity = new Column.BoolInt("trusted_identity") { default = "0", max_version = 1 };
        public Column<int> trust_level = new Column.Integer("trust_level") { default = TrustLevel.UNKNOWN.to_string(), min_version = 2 };
        public Column<bool> now_active = new Column.BoolInt("now_active") { default = "1" };
        public Column<long> last_active = new Column.Long("last_active");

        internal IdentityMetaTable(Database db) {
            base(db, "identity_meta");
            init({identity_id, address_name, device_id, identity_key_public_base64, trusted_identity, trust_level, now_active, last_active});
            index("identity_meta_idx", {identity_id, address_name, device_id}, true);
            index("identity_meta_list_idx", {identity_id, address_name});
        }

        public QueryBuilder with_address(int identity_id, string address_name) {
            return select().with(this.identity_id, "=", identity_id).with(this.address_name, "=", address_name);
        }

        public void insert_device_list(int32 identity_id, string address_name, ArrayList<int32> devices) {
            update().with(this.address_name, "=", address_name).set(now_active, false).perform();
            foreach (int32 device_id in devices) {
                upsert()
                        .value(this.identity_id, identity_id, true)
                        .value(this.address_name, address_name, true)
                        .value(this.device_id, device_id, true)
                        .value(this.now_active, true)
                        .value(this.last_active, (long) new DateTime.now_utc().to_unix())
                        .perform();
            }
        }

        public int64 insert_device_bundle(int32 identity_id, string address_name, int device_id, Bundle bundle, TrustLevel trust) {
            if (bundle == null || bundle.identity_key == null) return -1;
            return upsert()
                    .value(this.identity_id, identity_id, true)
                    .value(this.address_name, address_name, true)
                    .value(this.device_id, device_id, true)
                    .value(this.identity_key_public_base64, Base64.encode(bundle.identity_key.serialize()))
                    .value(this.trust_level, trust).perform();
        }

        public QueryBuilder get_trusted_devices(int identity_id, string address_name) {
            return this.with_address(identity_id, address_name)
                .with(this.trust_level, "!=", TrustLevel.UNTRUSTED)
                .with(this.now_active, "=", true);
        }

        public QueryBuilder get_known_devices(int identity_id, string address_name) {
            return this.with_address(identity_id, address_name)
                .with(this.trust_level, "!=", TrustLevel.UNKNOWN)
                .without_null(this.identity_key_public_base64);
        }

        public QueryBuilder get_unknown_devices(int identity_id, string address_name) {
            return this.with_address(identity_id, address_name)
                .with_null(this.identity_key_public_base64);
        }

        public QueryBuilder get_new_devices(int identity_id, string address_name) {
            return this.with_address(identity_id, address_name)
                .with(this.trust_level, "=", TrustLevel.UNKNOWN)
                .without_null(this.identity_key_public_base64);
        }

        public Row? get_device(int identity_id, string address_name, int device_id) {
            return this.with_address(identity_id, address_name)
                .with(this.device_id, "=", device_id).single().row().inner;
        }
    }


    public class TrustTable : Table {
        public Column<int> identity_id = new Column.Integer("identity_id") { not_null = true };
        public Column<string> address_name = new Column.Text("address_name");
        public Column<bool> blind_trust = new Column.BoolInt("blind_trust") { default = "1" } ;

        internal TrustTable(Database db) {
            base(db, "trust");
            init({identity_id, address_name, blind_trust});
            index("trust_idx", {identity_id, address_name}, true);
        }

        public bool get_blind_trust(int32 identity_id, string address_name) {
            return this.select().with(this.identity_id, "=", identity_id)
                    .with(this.address_name, "=", address_name)
                    .with(this.blind_trust, "=", true).count() > 0;
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
    public TrustTable trust { get; private set; }
    public IdentityTable identity { get; private set; }
    public SignedPreKeyTable signed_pre_key { get; private set; }
    public PreKeyTable pre_key { get; private set; }
    public SessionTable session { get; private set; }

    public Database(string fileName) {
        base(fileName, VERSION);
        identity_meta = new IdentityMetaTable(this);
        trust = new TrustTable(this);
        identity = new IdentityTable(this);
        signed_pre_key = new SignedPreKeyTable(this);
        pre_key = new PreKeyTable(this);
        session = new SessionTable(this);
        init({identity_meta, trust, identity, signed_pre_key, pre_key, session});
        try {
            exec("PRAGMA synchronous=0");
        } catch (Error e) { }
    }

    public override void migrate(long oldVersion) {
        if(oldVersion == 1) {
            exec("DROP INDEX identity_meta_idx");
            exec("DROP INDEX identity_meta_list_idx");
            exec("CREATE UNIQUE INDEX identity_meta_idx ON identity_meta (identity_id, address_name, device_id)");
            exec("CREATE INDEX identity_meta_list_idx ON identity_meta (identity_id, address_name)");
        }
    }
}

}
