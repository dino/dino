using Qlite;
using Signal;

namespace Dino.Plugins.Omemo {

private class BackedSignedPreKeyStore : SimpleSignedPreKeyStore {
    private Database db;
    private int identity_id;

    public BackedSignedPreKeyStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
        init();
    }

    private void init() {
        try {
            foreach (Row row in db.signed_pre_key.select().with(db.signed_pre_key.identity_id, "=", identity_id)) {
                store_signed_pre_key(row[db.signed_pre_key.signed_pre_key_id], Base64.decode(row[db.signed_pre_key.record_base64]));
            }
        } catch (Error e) {
            print("Error while initializing signed pre key store: %s", e.message);
        }

        signed_pre_key_stored.connect(on_signed_pre_key_stored);
        signed_pre_key_deleted.connect(on_signed_pre_key_deleted);
    }

    public void on_signed_pre_key_stored(SignedPreKeyStore.Key key) {
        db.signed_pre_key.upsert()
                .value(db.signed_pre_key.identity_id, identity_id, true)
                .value(db.signed_pre_key.signed_pre_key_id, (int) key.key_id, true)
                .value(db.signed_pre_key.record_base64, Base64.encode(key.record))
                .perform();
    }

    public void on_signed_pre_key_deleted(SignedPreKeyStore.Key key) {
        db.signed_pre_key.delete()
                .with(db.signed_pre_key.identity_id, "=", identity_id)
                .with(db.signed_pre_key.signed_pre_key_id, "=", (int) key.key_id)
                .perform();
    }
}

}
