using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

private class BackedSessionStore : SimpleSessionStore {
    private Database db;
    private int identity_id;

    public BackedSessionStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
        init();
    }

    private void init() {
        try {
            foreach (Row row in db.session.select().with(db.session.identity_id, "=", identity_id)) {
                Address addr = new Address(row[db.session.address_name], row[db.session.device_id]);
                store_session(addr, Base64.decode(row[db.session.record_base64]));
                addr.device_id = 0;
            }
        } catch (Error e) {
            print("Error while initializing session store: %s", e.message);
        }

        session_stored.connect(on_session_stored);
        session_removed.connect(on_session_deleted);
    }

    public void on_session_stored(SessionStore.Session session) {
        db.session.insert().or("REPLACE")
                .value(db.session.identity_id, identity_id)
                .value(db.session.address_name, session.name)
                .value(db.session.device_id, session.device_id)
                .value(db.session.record_base64, Base64.encode(session.record))
                .perform();
    }

    public void on_session_deleted(SessionStore.Session session) {
        db.session.delete()
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", session.name)
                .with(db.session.device_id, "=", session.device_id)
                .perform();
    }
}

}
