using Gee;
using Xmpp;

namespace Dino.Entities {

public class Account : Object {

    public int id { get; set; }
    public string localpart { get { return bare_jid.localpart; } }
    public string domainpart { get { return bare_jid.domainpart; } }
    public string resourcepart { get; set; }
    public Jid bare_jid { get; private set; }
    public string? password { get; set; }
    public string display_name {
        owned get { return alias ?? bare_jid.to_string(); }
    }
    public string? alias { get; set; }
    public bool enabled { get; set; default = false; }
    public string? roster_version { get; set; }
    public DateTime mam_earliest_synced { get; set; default=new DateTime.from_unix_utc(0); }

    private Database? db;

    public Account(Jid bare_jid, string? resourcepart, string? password, string? alias) {
        this.id = -1;
        this.resourcepart = resourcepart ?? "dino." + Random.next_int().to_string("%x");
        this.bare_jid = bare_jid;
        this.password = password;
        this.alias = alias;
    }

    public Account.from_row(Database db, Qlite.Row row) {
        this.db = db;
        id = row[db.account.id];
        resourcepart = row[db.account.resourcepart];
        bare_jid = new Jid(row[db.account.bare_jid]);
        password = row[db.account.password];
        alias = row[db.account.alias];
        enabled = row[db.account.enabled];
        roster_version = row[db.account.roster_version];
        mam_earliest_synced = new DateTime.from_unix_utc(row[db.account.mam_earliest_synced]);

        notify.connect(on_update);
    }

    public void persist(Database db) {
        this.db = db;
        id = (int) db.account.insert()
                .value(db.account.bare_jid, bare_jid.to_string())
                .value(db.account.resourcepart, resourcepart)
                .value(db.account.password, password)
                .value(db.account.alias, alias)
                .value(db.account.enabled, enabled)
                .value(db.account.roster_version, roster_version)
                .value(db.account.mam_earliest_synced, (long)mam_earliest_synced.to_unix())
                .perform();

        notify.connect(on_update);
    }

    public void remove() {
        db.account.delete().with(db.account.bare_jid, "=", bare_jid.to_string()).perform();
        notify.disconnect(on_update);
        id = -1;
        db = null;
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
            case "password":
                update.set(db.account.password, password); break;
            case "alias":
                update.set(db.account.alias, alias); break;
            case "enabled":
                update.set(db.account.enabled, enabled); break;
            case "roster-version":
                update.set(db.account.roster_version, roster_version); break;
            case "mam-earliest-synced":
                update.set(db.account.mam_earliest_synced, (long)mam_earliest_synced.to_unix()); break;
        }
        update.perform();
    }
}

}
