using Gee;
using Qlite;
using Xmpp;
using Xmpp.Xep.ServiceDiscovery;

namespace Dino {

public class EntityCapabilitiesStorage : Xep.EntityCapabilities.Storage, Object {

    private Database db;
    private HashMap<string, Gee.List<string>> features_cache = new HashMap<string, Gee.List<string>>();
    private HashMap<string, Identity> identity_cache = new HashMap<string, Identity>();

    public EntityCapabilitiesStorage(Database db) {
        this.db = db;
    }

    public void store_features(string entity, Gee.List<string> features) {
        if (features_cache.contains(entity)) return;

        foreach (string feature in features) {
            db.entity_feature.insert()
                    .value(db.entity_feature.entity, entity)
                    .value(db.entity_feature.feature, feature)
                    .perform();
        }
    }

    public void store_identities(string entity, Gee.Set<Identity> identities) {
        foreach (Identity identity in identities) {
            if (identity.category == Identity.CATEGORY_CLIENT) {
                db.entity_identity.insert()
                        .value(db.entity_identity.entity, entity)
                        .value(db.entity_identity.category, identity.category)
                        .value(db.entity_identity.type, identity.type_)
                        .value(db.entity_identity.entity_name, identity.name)
                        .perform();
                return;
            }
        }
    }

    public Gee.List<string> get_features(string entity) {
        Gee.List<string>? features = features_cache[entity];
        if (features != null) {
            return features;
        }

        features = new ArrayList<string>();
        foreach (Row row in db.entity_feature.select({db.entity_feature.feature}).with(db.entity_feature.entity, "=", entity)) {
            features.add(row[db.entity_feature.feature]);
        }
        features_cache[entity] = features;
        return features;
    }

    public Identity? get_identities(string entity) {
        Identity? identity = identity_cache[entity];
        if (identity != null) {
            return identity;
        }

        RowOption row = db.entity_identity.select().with(db.entity_identity.entity, "=", entity).single().row();
        if (row.is_present()) {
            identity = new Identity(row[db.entity_identity.category], row[db.entity_identity.type], row[db.entity_identity.entity_name]);
        }
        identity_cache[entity] = identity;
        return identity;
    }
}
}
