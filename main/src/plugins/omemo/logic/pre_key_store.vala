using Dino.Crypto.Omemo;
using Dino.Qlite;
using Omemo;

namespace Dino.Plugins.Omemo {

private class BackedPreKeyStore : PreKeyStore {
    private Database db;
    private int identity_id;

    public BackedPreKeyStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
    }

    public override uint8[]? load_pre_key(uint32 pre_key_id) throws Crypto.Error {
        RowOption row = db.pre_key.select({db.pre_key.record_base64})
                .with(db.pre_key.identity_id, "=", identity_id)
                .with(db.pre_key.pre_key_id, "=", (int) pre_key_id)
                .single().row();
        if (!row.is_present()) return null;
        return Base64.decode(row[db.pre_key.record_base64]);
    }

    public override void store_pre_key(uint32 pre_key_id, uint8[] record) throws Crypto.Error {
        db.pre_key.upsert()
                .value(db.pre_key.identity_id, identity_id, true)
                .value(db.pre_key.pre_key_id, (int) pre_key_id, true)
                .value(db.pre_key.record_base64, Base64.encode(record))
                .perform();
    }

    public override bool contains_pre_key(uint32 pre_key_id) throws Crypto.Error {
        return db.pre_key.select({db.pre_key.pre_key_id})
                .with(db.pre_key.identity_id, "=", identity_id)
                .with(db.pre_key.pre_key_id, "=", (int) pre_key_id)
                .count() > 0;
    }

    public override void delete_pre_key(uint32 pre_key_id) throws Crypto.Error {
        db.pre_key.delete()
                .with(db.pre_key.identity_id, "=", identity_id)
                .with(db.pre_key.pre_key_id, "=", (int) pre_key_id)
                .perform();
    }
}

}
