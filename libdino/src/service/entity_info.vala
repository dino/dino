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
    private Dino.Entities.Settings settings;

    private HashMap<Jid, string> entity_caps_hashes = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashMap<string, Gee.List<string>> entity_features = new HashMap<string, Gee.List<string>>();
    private HashMap<Jid, Gee.List<string>> jid_features = new HashMap<Jid, Gee.List<string>>(Jid.hash_func, Jid.equals_func);
    private HashMap<string, Gee.Set<Identity>> entity_identity = new HashMap<string, Gee.Set<Identity>>();
    private HashMap<Jid, Gee.Set<Identity>> jid_identity = new HashMap<Jid, Gee.Set<Identity>>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, int> jid_utc_offset_minutes = new HashMap<Jid, int>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, int> jid_utc_offset_cache_timeout = new HashMap<Jid, int>(Jid.hash_func, Jid.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db, Dino.Entities.Settings settings) {
        EntityInfo m = new EntityInfo(stream_interactor, db, settings);
        stream_interactor.add_module(m);
        WeakRef m_weak = WeakRef(m);
        ulong handler_id = settings.notify["share-time"].connect(() => {
            EntityInfo? entity_info = m_weak.get() as EntityInfo;
            if (entity_info != null) {
                entity_info.jid_utc_offset_minutes.clear();
                entity_info.jid_utc_offset_cache_timeout.clear();
            }
        });
        m.weak_ref(() => settings.disconnect(handler_id));
    }

    private EntityInfo(StreamInteractor stream_interactor, Database db, Dino.Entities.Settings settings) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.entity_capabilities_storage = new EntityCapabilitiesStorage(db);
        this.settings = settings;

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

    public async int get_utc_offset_minutes_for_full_jid(Account account, Jid full_jid) {
        if (!settings.share_time) return int.MIN;
        if (!yield has_feature(account, full_jid, EntityTime.NS_URI)) return int.MIN;
        int monotonic_time_minutes = (int) (get_monotonic_time() / 1000000l);
        if (jid_utc_offset_minutes.has_key(full_jid)) {
            if (jid_utc_offset_cache_timeout[full_jid] > monotonic_time_minutes) {
                return jid_utc_offset_minutes.get(full_jid);
            } else {
                jid_utc_offset_minutes.unset(full_jid);
                jid_utc_offset_cache_timeout.unset(full_jid);
            }
        }
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null) return int.MIN;
        DateTime? time = yield stream.get_module(EntityTime.Module.IDENTITY).query_time(stream, full_jid);
        int utc_offset = time == null ? int.MIN : (int) (time.get_utc_offset() / TimeSpan.MINUTE);
        jid_utc_offset_minutes.set(full_jid, utc_offset);
        jid_utc_offset_cache_timeout.set(full_jid, monotonic_time_minutes + 3 * 60 * 60);
        return utc_offset;
    }

    public async int get_utc_offset_minutes_for_bare_jid(Account account, Jid bare_jid) {
        if (stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, bare_jid) == null) return int.MIN;
        int utc_offset_minutes = int.MIN;
        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(bare_jid, account);
        if (full_jids != null) {
            foreach (Jid full_jid in full_jids) {
                int jid_utc_offset_minutes = yield get_utc_offset_minutes_for_full_jid(account, full_jid);
                if (utc_offset_minutes == int.MIN) {
                    utc_offset_minutes = jid_utc_offset_minutes;
                } else if (jid_utc_offset_minutes != int.MIN && utc_offset_minutes != jid_utc_offset_minutes) {
                    // Return early, time zones don't match
                    return int.MIN;
                }
            }
        }
        return utc_offset_minutes;
    }

    public async bool has_feature(Account account, Jid jid, string feature) {
        int has_feature_cached = has_feature_cached_int(account, jid, feature);
        if (has_feature_cached != -1) {
            return has_feature_cached == 1;
        }

        ServiceDiscovery.InfoResult? info_result = yield get_info_result(account, jid, entity_caps_hashes[jid]);
        if (info_result == null) return false;

        return info_result.features.contains(feature);
    }

    public bool has_feature_offline(Account account, Jid jid, string feature) {
        int ret = has_feature_cached_int(account, jid, feature);
        if (ret == -1) {
            return db.entity.select()
                    .with(db.entity.account_id, "=", account.id)
                    .with(db.entity.jid_id, "=", db.get_jid_id(jid))
                    .with(db.entity.resource, "=", jid.resourcepart ?? "")
                    .join_with(db.entity_feature, db.entity.caps_hash, db.entity_feature.entity)
                    .with(db.entity_feature.feature, "=", feature)
                    .count() > 0;
        }
        return ret == 1;
    }

    public bool has_feature_cached(Account account, Jid jid, string feature) {
        return has_feature_cached_int(account, jid, feature) == 1;
    }

    private int has_feature_cached_int(Account account, Jid jid, string feature) {
        if (jid_features.has_key(jid)) {
            return jid_features[jid].contains(feature) ? 1 : 0;
        }

        string? hash = entity_caps_hashes[jid];
        if (hash != null) {
            Gee.List<string>? features = get_stored_features(hash);
            if (features != null) {
                return features.contains(feature) ? 1 : 0;
            }
        }
        return -1;
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

        var computed_hash = EntityCapabilities.Module.compute_hash_for_info_result(info_result);

        if (hash == null || computed_hash == hash) {
            db.entity.upsert()
                .value(db.entity.account_id, account.id, true)
                .value(db.entity.jid_id, db.get_jid_id(jid), true)
                .value(db.entity.resource, jid.resourcepart ?? "", true)
                .value(db.entity.last_seen, (long)(new DateTime.now_local()).to_unix())
                .value(db.entity.caps_hash, computed_hash)
                .perform();

            store_features(computed_hash, info_result.features);
            store_identities(computed_hash, info_result.identities);
        } else {
            warning("Claimed entity caps hash from %s doesn't match computed one", jid.to_string());
        }
        jid_features[jid] = info_result.features;
        jid_identity[jid] = info_result.identities;

        return info_result;
    }

    private void on_account_added(Account account) {
        var cache = new CapsCacheImpl(account, this);
        stream_interactor.module_manager.get_module(account, ServiceDiscovery.Module.IDENTITY).cache = cache;

        stream_interactor.module_manager.get_module(account, Presence.Module.IDENTITY).received_available.connect((stream, presence) => on_received_available_presence(account, presence));
    }

    private void initialize_modules(Account account, ArrayList<XmppStreamModule> modules) {
        modules.add(new Xep.EntityCapabilities.Module(entity_capabilities_storage));
        var entity_time_module = modules.first_match((it) => it is EntityTime.Module) as EntityTime.Module;
        if (entity_time_module != null) {
            settings.bind_property("share-time", entity_time_module, "enabled", BindingFlags.SYNC_CREATE);
        }
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
