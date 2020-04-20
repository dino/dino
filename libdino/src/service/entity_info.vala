using Gee;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Xmpp.Xep.ServiceDiscovery;

namespace Dino {
public class EntityInfo : StreamInteractionModule, Object {
    public static ModuleIdentity<EntityInfo> IDENTITY = new ModuleIdentity<EntityInfo>("entity_info");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;
    private EntityCapabilitiesStorage entity_capabilities_storage;


    private HashMap<Jid, string> entity_caps_hashes = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        EntityInfo m = new EntityInfo(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private EntityInfo(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.entity_capabilities_storage = new EntityCapabilitiesStorage(db);

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect(initialize_modules);
    }

    public Identity? get_identity(Account account, Jid jid) {
        string? caps_hash = entity_caps_hashes[jid];
        if (caps_hash == null) return null;
        return entity_capabilities_storage.get_identities(caps_hash);
    }

    private void on_received_available_presence(Account account, Presence.Stanza presence) {
        bool is_gc = stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(presence.from.bare_jid, account);
        if (is_gc) return;

        string? caps_hash = EntityCapabilities.get_caps_hash(presence);
        if (caps_hash == null) return;

        db.entity.upsert()
                .value(db.entity.account_id, account.id, true)
                .value(db.entity.jid_id, db.get_jid_id(presence.from), true)
                .value(db.entity.resource, presence.from.resourcepart, true)
                .value(db.entity.last_seen, (long)(new DateTime.now_local()).to_unix())
                .value(db.entity.caps_hash, caps_hash)
                .perform();

        if (caps_hash != null) {
            entity_caps_hashes[presence.from] = caps_hash;
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_available.connect((stream, presence) => on_received_available_presence(account, presence));
    }

    private void initialize_modules(Account account, ArrayList<XmppStreamModule> modules) {
        modules.add(new Xep.EntityCapabilities.Module(entity_capabilities_storage));
    }
}
}
