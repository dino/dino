using Gee;
using Xmpp;

namespace Dino.Entities {

public class Account : Object {

    public int id { get; set; }
    public string localpart { get { return bare_jid.localpart; } }
    public string domainpart { get { return bare_jid.domainpart; } }
    public string resourcepart {
        get { return full_jid.resourcepart; }
        private set { full_jid = full_jid.with_resource(value); }
    }
    public Jid bare_jid { owned get { return full_jid.bare_jid; } }
    [Version (deprecated = true)]
    public Jid full_jid { get; private set; }
    public string? password { get; set; }

    private string? _oauth_token;
    public string? oauth_token {
        get { return _oauth_token; }
        set { _oauth_token = value; store_oauth_setting("oauth-access-token", value); notify_property("oauth-token"); }
    }
    private string? _oauth_refresh_token;
    public string? oauth_refresh_token {
        get { return _oauth_refresh_token; }
        set { _oauth_refresh_token = value; store_oauth_setting("oauth-refresh-token", value); notify_property("oauth-refresh-token"); }
    }
    private string? _oauth_issuer;
    public string? oauth_issuer {
        get { return _oauth_issuer; }
        set { _oauth_issuer = value; store_oauth_setting("oauth-issuer", value); notify_property("oauth-issuer"); }
    }
    private string? _oauth_token_endpoint;
    public string? oauth_token_endpoint {
        get { return _oauth_token_endpoint; }
        set { _oauth_token_endpoint = value; store_oauth_setting("oauth-token-endpoint", value); notify_property("oauth-token-endpoint"); }
    }
    private string? _oauth_client_id;
    public string? oauth_client_id {
        get { return _oauth_client_id; }
        set { _oauth_client_id = value; store_oauth_setting("oauth-client-id", value); notify_property("oauth-client-id"); }
    }
    private string? _oauth_client_secret;
    public string? oauth_client_secret {
        get { return _oauth_client_secret; }
        set { _oauth_client_secret = value; store_oauth_setting("oauth-client-secret", value); notify_property("oauth-client-secret"); }
    }
    private int64 _oauth_expires_at;
    public int64 oauth_expires_at {
        get { return _oauth_expires_at; }
        set { _oauth_expires_at = value; store_oauth_setting("oauth-expires-at", value.to_string()); notify_property("oauth-expires-at"); }
    }
    public bool oauth { get { return _oauth_token != null && _oauth_token.length > 0; } }

    public string display_name {
        owned get { return (alias != null && alias.length > 0) ? alias.dup() : bare_jid.to_string(); }
    }
    public string? alias { get; set; }
    public bool enabled { get; set; default = false; }
    public string? roster_version { get; set; }
    public string? user_agent_id { get; set; }

    private Database? db;

    public Account(Jid bare_jid, string password) {
        this.id = -1;
        try {
            this.full_jid = bare_jid.with_resource(get_random_resource());
        } catch (InvalidJidError e) {
            error("Auto-generated resource was invalid (%s)", e.message);
        }
        this.password = password;
        this.user_agent_id = random_uuid();
    }

    public Account.from_row(Database db, Qlite.Row row) throws InvalidJidError {
        this.db = db;
        id = row[db.account.id];
        full_jid = Jid.from_string(row[db.account.bare_jid]).with_resource(row[db.account.resourcepart]);
        password = row[db.account.password];
        alias = row[db.account.alias];
        enabled = row[db.account.enabled];
        roster_version = row[db.account.roster_version];
        user_agent_id = row[db.account.user_agent_id];

        load_oauth_settings();

        notify.connect(on_update);

        // Add user agent id if missing
        if (user_agent_id == null) user_agent_id = random_uuid();
    }

    public void persist(Database db) {
        if (id > 0) return;

        this.db = db;
        id = (int) db.account.insert()
                .value(db.account.bare_jid, bare_jid.to_string())
                .value(db.account.resourcepart, resourcepart)
                .value(db.account.password, password)
                .value(db.account.alias, alias)
                .value(db.account.enabled, enabled)
                .value(db.account.roster_version, roster_version)
                .perform();

        persist_oauth_settings();

        notify.connect(on_update);
    }

    public void remove() {
        db.account_settings.delete().with(db.account_settings.account_id, "=", id).perform();
        db.account.delete().with(db.account.bare_jid, "=", bare_jid.to_string()).perform();
        notify.disconnect(on_update);
        id = -1;
        db = null;
    }

    private void load_oauth_settings() {
        _oauth_token = db.account_settings.get_value(id, "oauth-access-token");
        _oauth_refresh_token = db.account_settings.get_value(id, "oauth-refresh-token");
        _oauth_issuer = db.account_settings.get_value(id, "oauth-issuer");
        _oauth_token_endpoint = db.account_settings.get_value(id, "oauth-token-endpoint");
        _oauth_client_id = db.account_settings.get_value(id, "oauth-client-id");
        _oauth_client_secret = db.account_settings.get_value(id, "oauth-client-secret");
        string? expires_at = db.account_settings.get_value(id, "oauth-expires-at");
        _oauth_expires_at = expires_at != null ? int64.parse(expires_at) : 0;
    }

    private void persist_oauth_settings() {
        store_oauth_setting("oauth-access-token", _oauth_token);
        store_oauth_setting("oauth-refresh-token", _oauth_refresh_token);
        store_oauth_setting("oauth-issuer", _oauth_issuer);
        store_oauth_setting("oauth-token-endpoint", _oauth_token_endpoint);
        store_oauth_setting("oauth-client-id", _oauth_client_id);
        store_oauth_setting("oauth-client-secret", _oauth_client_secret);
        if (_oauth_expires_at > 0) store_oauth_setting("oauth-expires-at", _oauth_expires_at.to_string());
    }

    private void store_oauth_setting(string key, string? value) {
        if (db == null || id <= 0) return;
        if (value == null) {
            db.account_settings.delete()
                    .with(db.account_settings.account_id, "=", id)
                    .with(db.account_settings.key, "=", key)
                    .perform();
        } else {
            db.account_settings.upsert()
                    .value(db.account_settings.key, key, true)
                    .value(db.account_settings.account_id, id, true)
                    .value(db.account_settings.value, value)
                    .perform();
        }
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
        return acc1.bare_jid.equals(acc2.bare_jid);
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
            case "user-agent-id":
                update.set(db.account.user_agent_id, user_agent_id); break;
        }
        update.perform();
    }
}

}
