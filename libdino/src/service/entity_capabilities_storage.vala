using Gee;

using Xmpp;

namespace Dino {

public class EntityCapabilitiesStorage : Xep.EntityCapabilities.Storage, Object {

    private Database db;

    public EntityCapabilitiesStorage(Database db) {
        this.db = db;
    }

    public void store_features(string entity, Gee.List<string> features) {
        db.add_entity_features(entity, features);
    }

    public Gee.List<string> get_features(string entitiy) {
        return db.get_entity_features(entitiy);
    }
}
}
