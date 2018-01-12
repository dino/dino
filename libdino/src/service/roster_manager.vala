using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class RosterManager : StreamInteractionModule, Object {
    public static ModuleIdentity<RosterManager> IDENTITY = new ModuleIdentity<RosterManager>("roster_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void removed_roster_item(Account account, Jid jid, Roster.Item roster_item);
    public signal void updated_roster_item(Account account, Jid jid, Roster.Item roster_item);

    private StreamInteractor stream_interactor;
    private Database db;
    private Gee.Map<Account, RosterStoreImpl> roster_stores = new HashMap<Account, RosterStoreImpl>(Account.hash_func, Account.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        RosterManager m = new RosterManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public RosterManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect((account, modules) => {
            if (!roster_stores.has_key(account)) roster_stores[account] = new RosterStoreImpl(account, db);
            modules.add(new Roster.VersioningModule(roster_stores[account]));
        });
    }

    public Collection<Roster.Item> get_roster(Account account) {
        return roster_stores[account].get_roster();
    }

    public Roster.Item? get_roster_item(Account account, Jid jid) {
        return roster_stores[account].get_item(jid);
    }

    public void remove_jid(Account account, Jid jid) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Roster.Module.IDENTITY).remove_jid(stream, jid.bare_jid);
    }

    public void add_jid(Account account, Jid jid, string? handle) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Roster.Module.IDENTITY).add_jid(stream, jid.bare_jid, handle);
    }

    public void set_jid_handle(Account account, Jid jid, string? handle) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) stream.get_module(Xmpp.Roster.Module.IDENTITY).set_jid_handle(stream, jid.bare_jid, handle);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).received_roster.connect( (stream, roster) => {
            foreach (Roster.Item roster_item in roster) {
                on_roster_item_updated(account, roster_item);
            }
        });
        stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).item_removed.connect( (stream, roster_item) => {
            removed_roster_item(account, roster_item.jid, roster_item);
        });
        stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).item_updated.connect( (stream, roster_item) => {
            on_roster_item_updated(account, roster_item);
        });
    }

    private void on_roster_item_updated(Account account, Roster.Item roster_item) {
        updated_roster_item(account, roster_item.jid, roster_item);
    }
}

public class RosterStoreImpl : Roster.Storage, Object {
    private Account account;
    private Database db;

    private HashMap<Jid, Roster.Item> items = new HashMap<Jid, Roster.Item>(Jid.hash_bare_func, Jid.equals_bare_func);

    public class RosterStoreImpl(Account account, Database db) {
        this.account = account;
        this.db = db;

        foreach (Qlite.Row row in db.roster.select().with(db.roster.account_id, "=", account.id)) {
            Roster.Item item = new Roster.Item();
            item.jid = Jid.parse(row[db.roster.jid]);
            item.name = row[db.roster.handle];
            item.subscription = row[db.roster.subscription];
            items[item.jid] = item;
        }
    }

    public string? get_roster_version() {
        return account.roster_version;
    }

    public Collection<Roster.Item> get_roster() {
        return items.values;
    }

    public Roster.Item? get_item(Jid jid) {
        return items.has_key(jid) ? items[jid] : null;
    }

    public void set_roster_version(string version) {
        account.roster_version = version;
    }

    public void set_roster(Collection<Roster.Item> items) {
        db.roster.delete().with(db.roster.account_id, "=", account.id).perform();
        foreach (Roster.Item item in items) {
            set_item(item);
        }
    }

    public void set_item(Roster.Item item) {
        items[item.jid] = item;
        db.roster.insert().or("REPLACE")
            .value(db.roster.account_id, account.id)
            .value(db.roster.jid, item.jid.to_string())
            .value(db.roster.handle, item.name)
            .value(db.roster.subscription, item.subscription)
            .perform();
    }

    public void remove_item(Roster.Item item) {
        items.unset(item.jid);
        db.roster.delete()
            .with(db.roster.account_id, "=", account.id)
            .with(db.roster.jid, "=", item.jid.to_string()).perform();
    }
}

}
