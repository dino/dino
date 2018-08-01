using Qlite;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.OpenPgp {

public class Database : Qlite.Database {
    private const int VERSION = 0;

    public class AccountSetting : Table {
        public Column<int> account_id = new Column.Integer("account_id") { primary_key = true };
        public Column<string> key = new Column.Text("key") { not_null = true };

        internal AccountSetting(Database db) {
            base(db, "account_setting");
            init({account_id, key});
        }
    }

    public class ContactKey : Table {
        public Column<string> jid = new Column.Text("jid") { primary_key = true };
        public Column<string> key = new Column.Text("key") { not_null = true };

        internal ContactKey(Database db) {
            base(db, "contact_key");
            init({jid, key});
        }
    }

    public AccountSetting account_setting_table { get; private set; }
    public ContactKey contact_key_table { get; private set; }

    public Database(string filename) {
        base(filename, VERSION);
        this.account_setting_table = new AccountSetting(this);
        this.contact_key_table = new ContactKey(this);
        init({account_setting_table, contact_key_table});
    }

    public void set_contact_key(Jid jid, string key) {
        contact_key_table.insert().or("REPLACE")
                .value(contact_key_table.jid, jid.to_string())
                .value(contact_key_table.key, key)
                .perform();
    }

    public string? get_contact_key(Jid jid) {
        return contact_key_table.select({contact_key_table.key})
            .with(contact_key_table.jid, "=", jid.to_string())[contact_key_table.key];
    }

    public void set_account_key(Account account, string key) {
        account_setting_table.insert().or("REPLACE")
                .value(account_setting_table.account_id, account.id)
                .value(account_setting_table.key, key)
                .perform();
    }

    public string? get_account_key(Account account) {
        return account_setting_table.select({account_setting_table.key})
            .with(account_setting_table.account_id, "=", account.id)[account_setting_table.key];
    }

    public override void migrate(long oldVersion) { }
}

}
