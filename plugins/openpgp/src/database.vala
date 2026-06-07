using Qlite;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.OpenPgp {

public class Database : Qlite.Database {
    private const int VERSION = 1;

    public class AccountSetting : Table {
        public Column<int> account_id = new Column.Integer("account_id") { primary_key = true };
        public Column<string> key = new Column.Text("key") { not_null = true };
        public Column<string> signed_data = new Column.Text("signed_data") { min_version = 1 };
        public Column<string> sig = new Column.Text("sig") { min_version = 1 };

        internal AccountSetting(Database db) {
            base(db, "account_setting");
            init({account_id, key, signed_data, sig});
        }
    }

    public class ContactKey : Table {
        public Column<string> jid = new Column.Text("jid") { primary_key = true };
        public Column<string> key = new Column.Text("key");
        public Column<string> sig = new Column.Text("sig") { min_version = 1 };
        public Column<string> signed_data = new Column.Text("signed_data") { min_version = 1 };

        internal ContactKey(Database db) {
            base(db, "contact_key");
            init({jid, key, sig, signed_data});
        }

        internal void migrate_from_v0(Database db) {
            string column_list = "";
            foreach (Column c in columns) {
                if (c.min_version <= VERSION && c.max_version >= VERSION) {
                    if (column_list == "") {
                        column_list = c.name;
                    } else {
                        column_list += ", " + c.name;
                    }
                }
            }
            db.exec(@"ALTER TABLE $name RENAME TO _$(name)_1");
            create_table_at_version(VERSION);
            db.exec(@"INSERT INTO $name ($column_list) SELECT $column_list FROM _$(name)_1");
            db.exec(@"DROP TABLE _$(name)_1");
        }
    }

    public AccountSetting account_setting_table { get; private set; }
    public ContactKey contact_key_table { get; private set; }

    public Database(string filename) {
        base(filename, VERSION);
        this.account_setting_table = new AccountSetting(this);
        this.contact_key_table = new ContactKey(this);
        init({account_setting_table, contact_key_table});

        try {
            exec("PRAGMA journal_mode = WAL");
            exec("PRAGMA synchronous = NORMAL");
            exec("PRAGMA secure_delete = ON");
        } catch (Error e) {
            error("Failed to set OpenPGP database properties: %s", e.message);
        }
    }

    public void set_contact_signature(Jid jid, string sig, string signed_data) {
        contact_key_table.upsert()
                .value(contact_key_table.jid, jid.to_string(), true)
                .value(contact_key_table.sig, sig)
                .value(contact_key_table.signed_data, signed_data)
                .value_null(contact_key_table.key)
                .perform();
    }

    public void clear_contact_signature(Jid jid) {
        contact_key_table.upsert()
            .value(contact_key_table.jid, jid.to_string(), true)
            .value_null(contact_key_table.sig)
            .value_null(contact_key_table.signed_data)
            .perform();
    }

    public void set_contact_key(Jid jid, string key) {
        contact_key_table.upsert()
                .value(contact_key_table.jid, jid.to_string(), true)
                .value(contact_key_table.key, key)
                .perform();
    }

    public string? get_contact_key(Jid jid) {
        return get_contact_key_row(jid)[contact_key_table.key];
    }

    public RowOption get_contact_key_row(Jid jid) {
        return contact_key_table.select({contact_key_table.key})
                .with(contact_key_table.jid, "=", jid.to_string()).row();
    }

    public void set_account_key(Account account, string key) {
        account_setting_table.upsert()
                .value(account_setting_table.account_id, account.id, true)
                .value(account_setting_table.key, key)
                .value_null(account_setting_table.signed_data)
                .value_null(account_setting_table.sig)
                .perform();
    }

    public void set_account_signature(Account account, string signed_data, string sig) {
        account_setting_table.update()
                .with(account_setting_table.account_id, "=", account.id)
                .set(account_setting_table.signed_data, signed_data)
                .set(account_setting_table.sig, sig)
                .perform();
    }

    public string? get_account_signature(Account account, string signed_data) {
        return account_setting_table.select({account_setting_table.sig})
            .with(account_setting_table.account_id, "=", account.id)
            .with(account_setting_table.signed_data, "=", signed_data)[account_setting_table.sig];
    }

    public string? get_account_key(Account account) {
        return account_setting_table.select({account_setting_table.key})
            .with(account_setting_table.account_id, "=", account.id)[account_setting_table.key];
    }

    public override void migrate(long oldVersion) {
        if (oldVersion < 1) {
            contact_key_table.migrate_from_v0(this);
        }
    }
}

}
