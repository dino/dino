using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

private class BackedPreKeyStore : SimplePreKeyStore {
    private Database db;
    private int identity_id;

    public BackedPreKeyStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
        init();
    }

    private void init() {
        try {
            foreach (Row row in db.pre_key.select().with(db.pre_key.identity_id, "=", identity_id)) {
                store_pre_key(row[db.pre_key.pre_key_id], Base64.decode(row[db.pre_key.record_base64]));
            }
        } catch (Error e) {
            warning("Error while initializing pre key store: %s", e.message);
        }

        pre_key_stored.connect(on_pre_key_stored);
        pre_key_deleted.connect(on_pre_key_deleted);
    }

    public void on_pre_key_stored(PreKeyStore.Key key) {
        db.pre_key.insert().or("REPLACE")
                .value(db.pre_key.identity_id, identity_id)
                .value(db.pre_key.pre_key_id, (int) key.key_id)
                .value(db.pre_key.record_base64, Base64.encode(key.record))
                .perform();
    }

    public void on_pre_key_deleted(PreKeyStore.Key key) {
        db.pre_key.delete()
                .with(db.pre_key.identity_id, "=", identity_id)
                .with(db.pre_key.pre_key_id, "=", (int) key.key_id)
                .perform();
    }
}

}
