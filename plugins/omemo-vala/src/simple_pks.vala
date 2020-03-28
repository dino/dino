using Gee;

namespace Omemo {

public class SimplePreKeyStore : PreKeyStore {
    private Map<uint32, PreKeyStore.Key> pre_key_map = new HashMap<uint32, PreKeyStore.Key>();

    public override uint8[]? load_pre_key(uint32 pre_key_id) throws Error {
        if (contains_pre_key(pre_key_id)) {
            return pre_key_map[pre_key_id].record;
        }
        return null;
    }

    public override void store_pre_key(uint32 pre_key_id, uint8[] record) throws Error {
        PreKeyStore.Key key = new Key(pre_key_id, record);
        pre_key_map[pre_key_id] = key;
        pre_key_stored(key);
    }

    public override bool contains_pre_key(uint32 pre_key_id) throws Error {
        return pre_key_map.has_key(pre_key_id);
    }

    public override void delete_pre_key(uint32 pre_key_id) throws Error {
        PreKeyStore.Key key;
        if (pre_key_map.unset(pre_key_id, out key)) {
            pre_key_deleted(key);
        }
    }
}

}
