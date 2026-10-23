using Dino.Crypto.Omemo;
using Dino.Qlite;
using Omemo;

namespace Dino.Plugins.Omemo {

private class BackedSignedPreKeyStore : SignedPreKeyStore {
    private Database db;
    private int identity_id;

    public BackedSignedPreKeyStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
    }

    public override uint8[]? load_signed_pre_key(uint32 pre_key_id) throws Crypto.Error {
        RowOption row = db.signed_pre_key.select({db.signed_pre_key.record_base64})
                .with(db.signed_pre_key.identity_id, "=", identity_id)
                .with(db.signed_pre_key.signed_pre_key_id, "=", (int) pre_key_id)
                .single().row();
        if (!row.is_present()) return null;
        return Base64.decode(row[db.signed_pre_key.record_base64]);
    }

    public override void store_signed_pre_key(uint32 pre_key_id, uint8[] record) throws Crypto.Error {
        db.signed_pre_key.upsert()
                .value(db.signed_pre_key.identity_id, identity_id, true)
                .value(db.signed_pre_key.signed_pre_key_id, (int) pre_key_id, true)
                .value(db.signed_pre_key.record_base64, Base64.encode(record))
                .perform();
    }

    public override bool contains_signed_pre_key(uint32 pre_key_id) throws Crypto.Error {
        return db.signed_pre_key.select({db.signed_pre_key.signed_pre_key_id})
                .with(db.signed_pre_key.identity_id, "=", identity_id)
                .with(db.signed_pre_key.signed_pre_key_id, "=", (int) pre_key_id)
                .count() > 0;
    }

    public override void delete_signed_pre_key(uint32 pre_key_id) throws Crypto.Error {
        db.signed_pre_key.delete()
                .with(db.signed_pre_key.identity_id, "=", identity_id)
                .with(db.signed_pre_key.signed_pre_key_id, "=", (int) pre_key_id)
                .perform();
    }
}

}
