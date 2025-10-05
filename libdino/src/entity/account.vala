using Gee;
using Xmpp;

namespace Dino.Entities {

public class Account : Object, Sasl.PasswordProvider {

    public int id { get; set; }
    public string localpart { get { return full_jid.localpart; } }
    public string domainpart { get { return full_jid.domainpart; } }
    public string resourcepart {
        get { return full_jid.resourcepart; }
        private set { full_jid.resourcepart = value; }
    }
    public Jid bare_jid { owned get { return full_jid.bare_jid; } }
    public Jid full_jid { get; private set; }
    public string display_name {
        owned get { return (alias != null && alias.length > 0) ? alias.dup() : bare_jid.to_string(); }
    }
    public string? alias { get; set; }
    public bool enabled { get; set; default = false; }
    public string? roster_version { get; set; }

    private Database? db;
    private string? cleartext_password { get; set; } // stores the password loaded from the config, if any
#if WITH_SECRET
    private SecretManager secret_manager;
#endif

    public Account(Jid bare_jid, string? password = null) {
        this.id = -1;
        try {
            this.full_jid = bare_jid.with_resource(get_random_resource());
        } catch (InvalidJidError e) {
            error("Auto-generated resource was invalid (%s)", e.message);
        }
        this.cleartext_password = password;

#if WITH_SECRET
        this.secret_manager = new SecretManager(bare_jid);
#endif
    }

    public Account.from_row(Database db, Qlite.Row row) throws InvalidJidError {
        this.db = db;
        id = row[db.account.id];
        full_jid = new Jid(row[db.account.bare_jid]).with_resource(row[db.account.resourcepart]);
        cleartext_password = row[db.account.password];
        alias = row[db.account.alias];
        enabled = row[db.account.enabled];
        roster_version = row[db.account.roster_version];

#if WITH_SECRET
        secret_manager = new SecretManager(bare_jid);
#endif

        notify.connect(on_update);
    }

    public void persist(Database db) {
        if (id > 0) return;

        this.db = db;
        id = (int) db.account.insert()
                .value(db.account.bare_jid, bare_jid.to_string())
                .value(db.account.resourcepart, resourcepart)
                .value(db.account.password, cleartext_password)
                .value(db.account.alias, alias)
                .value(db.account.enabled, enabled)
                .value(db.account.roster_version, roster_version)
                .perform();

        notify.connect(on_update);
    }

    public async string? get_password() {
#if WITH_SECRET
        if (this.cleartext_password == null) {
            // We have to look it up in the secret service
            return yield secret_manager.get_password();
        }

        // We have a clear-text password.  Try to put it into the keyring.
        var password = this.cleartext_password;
        if (yield secret_manager.set_password(password)) {
            // Success.  Clear the clear-text PW from this entity.
            this.cleartext_password = null;
            this.on_cleartext_password_changed();
        }
        // Either way, return the password.
        return password;
#else
        return this.cleartext_password;
#endif
    }

    public async void set_password(string password) {
#if WITH_SECRET
        if (yield secret_manager.set_password(password)) {
            // Success.  Don't keep anything locally.
            this.cleartext_password = null;
            this.on_cleartext_password_changed();
            return;
        }
#endif
        this.cleartext_password = password;
        this.on_cleartext_password_changed();
    }

    public void remove() {
        db.account.delete().with(db.account.bare_jid, "=", bare_jid.to_string()).perform();
        notify.disconnect(on_update);
        id = -1;
        db = null;
    }

    public void set_random_resource() {
        this.resourcepart = get_random_resource();
    }

    private static string get_random_resource() {
        return "dino." + Random.next_int().to_string("%x");
    }

    public bool equals(Account acc) {
        return equals_func(this, acc);
    }

    public static bool equals_func(Account acc1, Account acc2) {
        return acc1.bare_jid.to_string() == acc2.bare_jid.to_string();
    }

    public static uint hash_func(Account acc) {
        return acc.bare_jid.to_string().hash();
    }

    private void on_update(Object o, ParamSpec sp) {
        var update = db.account.update().with(db.account.id, "=", id);
        switch (sp.name) {
            case "bare-jid":
                update.set(db.account.bare_jid, bare_jid.to_string()); break;
            case "resourcepart":
                update.set(db.account.resourcepart, resourcepart); break;
            case "alias":
                update.set(db.account.alias, alias); break;
            case "enabled":
                update.set(db.account.enabled, enabled); break;
            case "roster-version":
                update.set(db.account.roster_version, roster_version); break;
        }
        update.perform();
    }

    private void on_cleartext_password_changed() {
        if (db != null) {
            db.account.update()
                .with(db.account.id, "=", id)
                .set(db.account.password, cleartext_password)
                .perform();
        }
    }
}

}
