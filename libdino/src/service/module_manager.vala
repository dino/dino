using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class ModuleManager {
    private HashMap<Account, ArrayList<XmppStreamModule>> module_map = new HashMap<Account, ArrayList<XmppStreamModule>>();

    private EntityCapabilitiesStorage entity_capabilities_storage;

    public signal void initialize_account_modules(Account account, ArrayList<XmppStreamModule> modules);

    public ModuleManager(Database db) {
        entity_capabilities_storage = new EntityCapabilitiesStorage(db);
    }

    public T? get_module<T>(Account account, Xmpp.ModuleIdentity<T> identity) {
        if (identity == null) return null;
        lock (module_map) {
            if (!module_map.has_key(account)) {
                initialize(account);
            }
            var res = module_map[account].filter((module) => identity.matches(module));
            if (res != null && res.next()) {
                return identity.cast(res.get());
            }
        }
        return null;
    }

    public ArrayList<XmppStreamModule> get_modules(Account account, string? resource = null) {
        ArrayList<XmppStreamModule> modules = new ArrayList<XmppStreamModule>();

        lock (module_map) {
            if (!module_map.has_key(account)) initialize(account);
            foreach (XmppStreamModule module in module_map[account]) modules.add(module);
        }

        foreach (XmppStreamModule module in module_map[account]) {
            if (module.get_id() == Bind.Module.IDENTITY.id) {
                (module as Bind.Module).requested_resource = resource ?? account.resourcepart;
            } else if (module.get_id() == PlainSasl.Module.IDENTITY.id) {
                (module as PlainSasl.Module).password = account.password;
            }
        }
        return modules;
    }

    public void initialize(Account account) {
        lock(module_map) {
            module_map[account] = new ArrayList<XmppStreamModule>();
            module_map[account].add(new Iq.Module());
            module_map[account].add(new Tls.Module());
            module_map[account].add(new Xep.SrvRecordsTls.Module());
            module_map[account].add(new PlainSasl.Module(account.bare_jid.to_string(), account.password));
            module_map[account].add(new Xep.StreamManagement.Module());
            module_map[account].add(new Bind.Module(account.resourcepart));
            module_map[account].add(new Session.Module());
            module_map[account].add(new Roster.Module());
            module_map[account].add(new Xep.ServiceDiscovery.Module.with_identity("client", "pc"));
            module_map[account].add(new Xep.PrivateXmlStorage.Module());
            module_map[account].add(new Xep.Bookmarks.Module());
            module_map[account].add(new Presence.Module());
            module_map[account].add(new Xmpp.MessageModule());
            module_map[account].add(new Xep.MessageArchiveManagement.Module());
            module_map[account].add(new Xep.MessageCarbons.Module());
            module_map[account].add(new Xep.Muc.Module());
            module_map[account].add(new Xep.Pubsub.Module());
            module_map[account].add(new Xep.EntityCapabilities.Module(entity_capabilities_storage));
            module_map[account].add(new Xep.MessageDeliveryReceipts.Module());
            module_map[account].add(new Xep.BlockingCommand.Module());
            module_map[account].add(new Xep.ChatStateNotifications.Module());
            module_map[account].add(new Xep.ChatMarkers.Module());
            module_map[account].add(new Xep.Ping.Module());
            module_map[account].add(new Xep.DelayedDelivery.Module());
            module_map[account].add(new StreamError.Module());
            initialize_account_modules(account, module_map[account]);
        }
    }
}

}
