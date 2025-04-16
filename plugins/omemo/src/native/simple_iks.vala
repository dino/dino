using Gee;

namespace Omemo {

public class SimpleIdentityKeyStore : IdentityKeyStore {
    public override Bytes identity_key_private { get; set; }
    public override Bytes identity_key_public { get; set; }
    public override uint32 local_registration_id { get; set; }
    private Map<string, Map<int, IdentityKeyStore.TrustedIdentity>> trusted_identities = new HashMap<string, Map<int, IdentityKeyStore.TrustedIdentity>>();

    public override void save_identity(Address address, uint8[] key) throws Error {
        string name = address.name;
        if (trusted_identities.has_key(name)) {
            if (trusted_identities[name].has_key(address.device_id)) {
                trusted_identities[name][address.device_id].key = key;
                trusted_identity_updated(trusted_identities[name][address.device_id]);
            } else {
                trusted_identities[name][address.device_id] = new TrustedIdentity.by_address(address, key);
                trusted_identity_added(trusted_identities[name][address.device_id]);
            }
        } else {
            trusted_identities[name] = new HashMap<int, IdentityKeyStore.TrustedIdentity>();
            trusted_identities[name][address.device_id] = new TrustedIdentity.by_address(address, key);
            trusted_identity_added(trusted_identities[name][address.device_id]);
        }
    }

    public override bool is_trusted_identity(Address address, uint8[] key) throws Error {
        if (!trusted_identities.has_key(address.name)) return true;
        if (!trusted_identities[address.name].has_key(address.device_id)) return true;
        uint8[] other_key = trusted_identities[address.name][address.device_id].key;
        if (other_key.length != key.length) return false;
        for (int i = 0; i < key.length; i++) {
            if (other_key[i] != key[i]) return false;
        }
        return true;
    }
}

}
