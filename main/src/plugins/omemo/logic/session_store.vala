using Dino.Crypto.Omemo;
using Dino.Qlite;
using Omemo;

namespace Dino.Plugins.Omemo {

private class BackedSessionStore : SessionStore {
    private Database db;
    private int identity_id;

    public BackedSessionStore(Database db, int identity_id) {
        this.db = db;
        this.identity_id = identity_id;
    }

    public override uint8[]? load_session(Address address) throws Crypto.Error {
        RowOption row = db.session.select({db.session.record_base64})
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", address.name)
                .with(db.session.device_id, "=", address.device_id)
                .single().row();
        if (!row.is_present()) return null;
        return Base64.decode(row[db.session.record_base64]);
    }

    public override IntList get_sub_device_sessions(string name) throws Crypto.Error {
        IntList res = new IntList();
        foreach (Row row in db.session.select({db.session.device_id})
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", name)) {
            res.add(row[db.session.device_id]);
        }
        return res;
    }

    public override void store_session(Address address, uint8[] record) throws Crypto.Error {
        db.session.upsert()
                .value(db.session.identity_id, identity_id, true)
                .value(db.session.address_name, address.name, true)
                .value(db.session.device_id, address.device_id, true)
                .value(db.session.record_base64, Base64.encode(record))
                .perform();
    }

    public override bool contains_session(Address address) throws Crypto.Error {
        return db.session.select({db.session.device_id})
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", address.name)
                .with(db.session.device_id, "=", address.device_id)
                .count() > 0;
    }

    public override void delete_session(Address address) throws Crypto.Error {
        db.session.delete()
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", address.name)
                .with(db.session.device_id, "=", address.device_id)
                .perform();
    }

    public override void delete_all_sessions(string name) throws Crypto.Error {
        db.session.delete()
                .with(db.session.identity_id, "=", identity_id)
                .with(db.session.address_name, "=", name)
                .perform();
    }
}

}
