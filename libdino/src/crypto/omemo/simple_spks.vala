using Gee;
using Omemo;

namespace Dino.Crypto.Omemo {

public class SimpleSignedPreKeyStore : SignedPreKeyStore {
    public signal void signed_pre_key_stored(Key key);
    public signal void signed_pre_key_deleted(Key key);

    private Map<uint32, Key> pre_key_map = new HashMap<uint32, Key>();

    public override uint8[]? load_signed_pre_key(uint32 pre_key_id) throws Error {
        if (contains_signed_pre_key(pre_key_id)) {
            return pre_key_map[pre_key_id].record;
        }
        return null;
    }

    public override void store_signed_pre_key(uint32 pre_key_id, uint8[] record) throws Error {
        Key key = new Key(pre_key_id, record);
        pre_key_map[pre_key_id] = key;
        signed_pre_key_stored(key);
    }

    public override bool contains_signed_pre_key(uint32 pre_key_id) throws Error {
        return pre_key_map.has_key(pre_key_id);
    }

    public override void delete_signed_pre_key(uint32 pre_key_id) throws Error {
        Key key;
        if (pre_key_map.unset(pre_key_id, out key)) {
            signed_pre_key_deleted(key);
        }
    }

    public class Key {
        public uint32 key_id { get; private set; }
        public uint8[] record { get; private set; }

        public Key(uint32 key_id, uint8[] record) {
            this.key_id = key_id;
            this.record = record;
        }
    }
}

}