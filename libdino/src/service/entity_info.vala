using Gee;
using Dino.Entities;
using Qlite;
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
    private HashMap<string, Gee.List<string>> entity_features = new HashMap<string, Gee.List<string>>();
    private HashMap<Jid, Gee.List<string>> jid_features = new HashMap<Jid, Gee.List<string>>(Jid.hash_func, Jid.equals_func);
    private HashMap<string, Gee.Set<Identity>> entity_identity = new HashMap<string, Gee.Set<Identity>>();
    private HashMap<Jid, Gee.Set<Identity>> jid_identity = new HashMap<Jid, Gee.Set<Identity>>(Jid.hash_func, Jid.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        EntityInfo m = new EntityInfo(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private EntityInfo(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.entity_capabilities_storage = new EntityCapabilitiesStorage(db);

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.connection_manager.stream_opened.connect((account, stream) => {
            stream.received_features_node.connect(() => {
                string? hash = EntityCapabilities.get_server_caps_hash(stream);
                if (hash != null) {
                    entity_caps_hashes[account.bare_jid.domain_jid] = hash;
                }
            });
        });
        stream_interactor.module_manager.initialize_account_modules.connect(initialize_modules);

        remove_old_entities();
        Timeout.add_seconds(60 * 60, () => { remove_old_entities(); return true; });
    }

    public async Gee.Set<Identity>? get_identities(Account account, Jid jid) {
        if (jid_identity.has_key(jid)) {
            return jid_identity[jid];
        }

        string? hash = entity_caps_hashes[jid];
        if (hash != null) {
            Gee.Set<Identity>? identities = get_stored_identities(hash);
            if (identities != null) return identities;
        }

        ServiceDiscovery.InfoResult? info_result = yield get_info_result(account, jid, hash);
        if (info_result != null) {
            return info_result.identities;
        }

        return null;
    }

    public async Identity? get_identity(Account account, Jid jid) {
        Gee.Set<ServiceDiscovery.Identity>? identities = yield get_identities(account, jid);
        if (identities == null) return null;

        foreach (var identity in identities) {
            if (identity.category == Identity.CATEGORY_CLIENT) {
                return identity;
            }
        }

        return null;
    }

    public async bool has_feature(Account account, Jid jid, string feature) {
        if (jid_features.has_key(jid)) {
            return jid_features[jid].contains(feature);
        }

        string? hash = entity_caps_hashes[jid];
        if (hash != null) {
            Gee.List<string>? features = get_stored_features(hash);
            if (features != null) {
                return features.contains(feature);
            }
        }

        ServiceDiscovery.InfoResult? info_result = yield get_info_result(account, jid, hash);
        if (info_result == null) return false;

        return info_result.features.contains(feature);
    }

    private void on_received_available_presence(Account account, Presence.Stanza presence) {
        bool is_gc = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(presence.from.bare_jid, account);
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

    private void remove_old_entities() {
        long timestamp = (long)(new DateTime.now_local().add_days(-14)).to_unix();
        db.entity.delete().with(db.entity.last_seen, "<", timestamp).perform();
    }

    private void store_features(string entity, Gee.List<string> features) {
        if (entity_features.has_key(entity)) return;

        foreach (string feature in features) {
            db.entity_feature.insert()
                    .value(db.entity_feature.entity, entity)
                    .value(db.entity_feature.feature, feature)
                    .perform();
        }
        entity_features[entity] = features;
    }

    private void store_identities(string entity, Gee.Set<Identity> identities) {
        foreach (Identity identity in identities) {
            db.entity_identity.insert()
                    .value(db.entity_identity.entity, entity)
                    .value(db.entity_identity.category, identity.category)
                    .value(db.entity_identity.type, identity.type_)
                    .value(db.entity_identity.entity_name, identity.name)
                    .perform();
        }
        entity_identity[entity] = identities;
    }

    private Gee.List<string>? get_stored_features(string entity) {
        Gee.List<string>? features = entity_features[entity];
        if (features != null) {
            return features;
        }

        features = new ArrayList<string>();
        foreach (Row row in db.entity_feature.select({db.entity_feature.feature}).with(db.entity_feature.entity, "=", entity)) {
            features.add(row[db.entity_feature.feature]);
        }

        if (features.size == 0) {
            return null;
        }
        entity_features[entity] = features;
        return features;
    }

    private Gee.Set<Identity>? get_stored_identities(string entity) {
        Gee.Set<Identity>? identities = entity_identity[entity];
        if (identities != null) {
            return identities;
        }

        identities = new HashSet<Identity>(Identity.hash_func, Identity.equals_func);
        var qry = db.entity_identity.select().with(db.entity_identity.entity, "=", entity);
        foreach (Row row in qry) {
            var identity = new Identity(row[db.entity_identity.category], row[db.entity_identity.type], row[db.entity_identity.entity_name]);
            identities.add(identity);
        }

        if (identities.size == 0) {
            return null;
        }
        entity_identity[entity] = identities;
        return identities;
    }

    private async ServiceDiscovery.InfoResult? get_info_result(Account account, Jid jid, string? hash = null) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return null;

        ServiceDiscovery.InfoResult? info_result = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, jid);
        if (info_result == null) return null;

        if (hash != null && EntityCapabilities.Module.compute_hash_for_info_result(info_result) == hash) {
            store_features(hash, info_result.features);
            store_identities(hash, info_result.identities);
        } else {
            jid_features[jid] = info_result.features;
            jid_identity[jid] = info_result.identities;
        }

        return info_result;
    }

    private void on_account_added(Account account) {
        var cache = new CapsCacheImpl(account, this);
        stream_interactor.module_manager.get_module(account, ServiceDiscovery.Module.IDENTITY).cache = cache;

        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_available.connect((stream, presence) => on_received_available_presence(account, presence));
    }

    private void initialize_modules(Account account, ArrayList<XmppStreamModule> modules) {
        modules.add(new Xep.EntityCapabilities.Module(entity_capabilities_storage));
    }
}

public class CapsCacheImpl : CapsCache, Object {

    private Account account;
    private EntityInfo entity_info;

    public CapsCacheImpl(Account account, EntityInfo entity_info) {
        this.account = account;
        this.entity_info = entity_info;
    }

    public async bool has_entity_feature(Jid jid, string feature) {
        return yield entity_info.has_feature(account, jid, feature);
    }

    public async Gee.Set<Identity> get_entity_identities(Jid jid) {
        return yield entity_info.get_identities(account, jid);
    }
}
}
