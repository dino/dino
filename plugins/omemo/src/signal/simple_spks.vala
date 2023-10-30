using Gee;

namespace Signal {

public class SimpleSignedPreKeyStore : SignedPreKeyStore {
    private Map<uint32, SignedPreKeyStore.Key> pre_key_map = new HashMap<uint32, SignedPreKeyStore.Key>();

    public override uint8[]? load_signed_pre_key(uint32 pre_key_id) throws Error {
        if (contains_signed_pre_key(pre_key_id)) {
            return pre_key_map[pre_key_id].record;
        }
        return null;
    }

    public override void store_signed_pre_key(uint32 pre_key_id, uint8[] record) throws Error {
        SignedPreKeyStore.Key key = new Key(pre_key_id, record);
        pre_key_map[pre_key_id] = key;
        signed_pre_key_stored(key);
    }

    public override bool contains_signed_pre_key(uint32 pre_key_id) throws Error {
        return pre_key_map.has_key(pre_key_id);
    }

    public override void delete_signed_pre_key(uint32 pre_key_id) throws Error {
        SignedPreKeyStore.Key key;
        if (pre_key_map.unset(pre_key_id, out key)) {
            signed_pre_key_deleted(key);
        }
    }
}

}