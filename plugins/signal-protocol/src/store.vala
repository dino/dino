namespace Signal {

public abstract class IdentityKeyStore : Object {
    public abstract uint8[] identity_key_private { get; set; }
    public abstract uint8[] identity_key_public { get; set; }
    public abstract uint32 local_registration_id { get; set; }

    public signal void trusted_identity_added(TrustedIdentity id);
    public signal void trusted_identity_updated(TrustedIdentity id);

    public abstract void save_identity(Address address, uint8[] key) throws Error ;

    public abstract bool is_trusted_identity(Address address, uint8[] key) throws Error ;

    public class TrustedIdentity {
        public uint8[] key { get; set; }
        public string name { get; private set; }
        public int device_id { get; private set; }

        public TrustedIdentity(string name, int device_id, uint8[] key) {
            this.key = key;
            this.name = name;
            this.device_id = device_id;
        }

        public TrustedIdentity.by_address(Address address, uint8[] key) {
            this(address.name, address.device_id, key);
        }
    }
}

public abstract class SessionStore : Object {

    public signal void session_stored(Session session);
    public signal void session_removed(Session session);
    public abstract uint8[]? load_session(Address address) throws Error ;

    public abstract IntList get_sub_device_sessions(string name) throws Error ;

    public abstract void store_session(Address address, uint8[] record) throws Error ;

    public abstract bool contains_session(Address address) throws Error ;

    public abstract void delete_session(Address address) throws Error ;

    public abstract void delete_all_sessions(string name) throws Error ;

    public class Session {
        public string name;
        public int device_id;
        public uint8[] record;
    }
}

public abstract class PreKeyStore : Object {

    public signal void pre_key_stored(Key key);
    public signal void pre_key_deleted(Key key);

    public abstract uint8[]? load_pre_key(uint32 pre_key_id) throws Error ;

    public abstract void store_pre_key(uint32 pre_key_id, uint8[] record) throws Error ;

    public abstract bool contains_pre_key(uint32 pre_key_id) throws Error ;

    public abstract void delete_pre_key(uint32 pre_key_id) throws Error ;

    public class Key {
        public uint32 key_id { get; private set; }
        public uint8[] record { get; private set; }

        public Key(uint32 key_id, uint8[] record) {
            this.key_id = key_id;
            this.record = record;
        }
    }
}

public abstract class SignedPreKeyStore : Object {

    public signal void signed_pre_key_stored(Key key);
    public signal void signed_pre_key_deleted(Key key);

    public abstract uint8[]? load_signed_pre_key(uint32 pre_key_id) throws Error ;

    public abstract void store_signed_pre_key(uint32 pre_key_id, uint8[] record) throws Error ;

    public abstract bool contains_signed_pre_key(uint32 pre_key_id) throws Error ;

    public abstract void delete_signed_pre_key(uint32 pre_key_id) throws Error ;

    public class Key {
        public uint32 key_id { get; private set; }
        public uint8[] record { get; private set; }

        public Key(uint32 key_id, uint8[] record) {
            this.key_id = key_id;
            this.record = record;
        }
    }
}

public class Store : Object {
    public Context context { get; private set; }
    public IdentityKeyStore identity_key_store { get; set; default = new SimpleIdentityKeyStore(); }
    public SessionStore session_store { get; set; default = new SimpleSessionStore(); }
    public PreKeyStore pre_key_store { get; set; default = new SimplePreKeyStore(); }
    public SignedPreKeyStore signed_pre_key_store { get; set; default = new SimpleSignedPreKeyStore(); }
    public uint32 local_registration_id { get { return identity_key_store.local_registration_id; } }
    internal NativeStoreContext native_context {get { return native_store_context_; }}
    private NativeStoreContext native_store_context_;

    static int iks_get_identity_key_pair(out Buffer public_data, out Buffer private_data, void* user_data) {
        Store store = (Store) user_data;
        public_data = new Buffer.from(store.identity_key_store.identity_key_public);
        private_data = new Buffer.from(store.identity_key_store.identity_key_private);
        return 0;
    }

    static int iks_get_local_registration_id(void* user_data, out uint32 registration_id) {
        Store store = (Store) user_data;
        registration_id = store.identity_key_store.local_registration_id;
        return 0;
    }

    static int iks_save_identity(Address address, uint8[] key, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.identity_key_store.save_identity(address, key);
            return 0;
        });
    }

    static int iks_is_trusted_identity(Address address, uint8[] key, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            return store.identity_key_store.is_trusted_identity(address, key) ? 1 : 0;
        });
    }

    static int iks_destroy_func(void* user_data) {
        return 0;
    }

    static int ss_load_session_func(out Buffer? record, out Buffer? user_record, Address address, void* user_data) {
        Store store = (Store) user_data;
        uint8[]? res = null;
        try {
            res = store.session_store.load_session(address);
        } catch (Error e) {
            record = null;
            return e.code;
        }
        if (res == null) {
            record = null;
            return 0;
        }
        record = new Buffer.from((!)res);
        user_record = null; // No support for user_record
        if (record == null) return ErrorCode.NOMEM;
        return 1;
    }

    static int ss_get_sub_device_sessions_func(out IntList? sessions, char[] name, void* user_data) {
        Store store = (Store) user_data;
        try {
            sessions = store.session_store.get_sub_device_sessions(carr_to_string(name));
        } catch (Error e) {
            sessions = null;
            return e.code;
        }
        return 0;
    }

    static int ss_store_session_func(Address address, uint8[] record, uint8[] user_record, void* user_data) {
        // Ignoring user_record
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.session_store.store_session(address, record);
            return 0;
        });
    }

    static int ss_contains_session_func(Address address, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            return store.session_store.contains_session(address) ? 1 : 0;
        });
    }

    static int ss_delete_session_func(Address address, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.session_store.delete_session(address);
            return 0;
        });
    }

    static int ss_delete_all_sessions_func(char[] name, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.session_store.delete_all_sessions(carr_to_string(name));
            return 0;
        });
    }

    static int ss_destroy_func(void* user_data) {
        return 0;
    }

    static int pks_load_pre_key(out Buffer? record, uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        uint8[]? res = null;
        try {
            res = store.pre_key_store.load_pre_key(pre_key_id);
        } catch (Error e) {
            record = null;
            return e.code;
        }
        if (res == null) {
            record = new Buffer(0);
            return 0;
        }
        record = new Buffer.from((!)res);
        if (record == null) return ErrorCode.NOMEM;
        return 1;
    }

    static int pks_store_pre_key(uint32 pre_key_id, uint8[] record, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.pre_key_store.store_pre_key(pre_key_id, record);
            return 0;
        });
    }

    static int pks_contains_pre_key(uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            return store.pre_key_store.contains_pre_key(pre_key_id) ? 1 : 0;
        });
    }

    static int pks_remove_pre_key(uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.pre_key_store.delete_pre_key(pre_key_id);
            return 0;
        });
    }

    static int pks_destroy_func(void* user_data) {
        return 0;
    }

    static int spks_load_signed_pre_key(out Buffer? record, uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        uint8[]? res = null;
        try {
            res = store.signed_pre_key_store.load_signed_pre_key(pre_key_id);
        } catch (Error e) {
            record = null;
            return e.code;
        }
        if (res == null) {
            record = new Buffer(0);
            return 0;
        }
        record = new Buffer.from((!)res);
        if (record == null) return ErrorCode.NOMEM;
        return 1;
    }

    static int spks_store_signed_pre_key(uint32 pre_key_id, uint8[] record, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.signed_pre_key_store.store_signed_pre_key(pre_key_id, record);
            return 0;
        });
    }

    static int spks_contains_signed_pre_key(uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            return store.signed_pre_key_store.contains_signed_pre_key(pre_key_id) ? 1 : 0;
        });
    }

    static int spks_remove_signed_pre_key(uint32 pre_key_id, void* user_data) {
        Store store = (Store) user_data;
        return catch_to_code(() => {
            store.signed_pre_key_store.delete_signed_pre_key(pre_key_id);
            return 0;
        });
    }

    static int spks_destroy_func(void* user_data) {
        return 0;
    }

    internal Store(Context context) {
        this.context = context;
        NativeStoreContext.create(out native_store_context_, context.native_context);

        NativeIdentityKeyStore iks = NativeIdentityKeyStore() {
            get_identity_key_pair = iks_get_identity_key_pair,
            get_local_registration_id = iks_get_local_registration_id,
            save_identity = iks_save_identity,
            is_trusted_identity = iks_is_trusted_identity,
            destroy_func = iks_destroy_func,
            user_data = this
        };
        native_context.set_identity_key_store(iks);

        NativeSessionStore ss = NativeSessionStore() {
            load_session_func = ss_load_session_func,
            get_sub_device_sessions_func = ss_get_sub_device_sessions_func,
            store_session_func = ss_store_session_func,
            contains_session_func = ss_contains_session_func,
            delete_session_func = ss_delete_session_func,
            delete_all_sessions_func = ss_delete_all_sessions_func,
            destroy_func = ss_destroy_func,
            user_data = this
        };
        native_context.set_session_store(ss);

        NativePreKeyStore pks = NativePreKeyStore() {
            load_pre_key = pks_load_pre_key,
            store_pre_key = pks_store_pre_key,
            contains_pre_key = pks_contains_pre_key,
            remove_pre_key = pks_remove_pre_key,
            destroy_func = pks_destroy_func,
            user_data = this
        };
        native_context.set_pre_key_store(pks);

        NativeSignedPreKeyStore spks = NativeSignedPreKeyStore() {
            load_signed_pre_key = spks_load_signed_pre_key,
            store_signed_pre_key = spks_store_signed_pre_key,
            contains_signed_pre_key = spks_contains_signed_pre_key,
            remove_signed_pre_key = spks_remove_signed_pre_key,
            destroy_func = spks_destroy_func,
            user_data = this
        };
        native_context.set_signed_pre_key_store(spks);
    }

    public SessionBuilder create_session_builder(Address other) throws Error {
        SessionBuilder builder;
        throw_by_code(session_builder_create(out builder, native_context, other, context.native_context), "Error creating session builder");
        return builder;
    }

    public SessionCipher create_session_cipher(Address other) throws Error {
        SessionCipher cipher;
        throw_by_code(session_cipher_create(out cipher, native_context, other, context.native_context));
        return cipher;
    }

    public IdentityKeyPair identity_key_pair {
        owned get {
            IdentityKeyPair pair;
            Protocol.Identity.get_key_pair(native_context, out pair);
            return pair;
        }
    }

    public bool is_trusted_identity(Address address, ECPublicKey key) throws Error {
        return throw_by_code(Protocol.Identity.is_trusted_identity(native_context, address, key)) == 1;
    }

    public void save_identity(Address address, ECPublicKey key) throws Error {
        throw_by_code(Protocol.Identity.save_identity(native_context, address, key));
    }

    public bool contains_session(Address other) throws Error {
        return throw_by_code(Protocol.Session.contains_session(native_context, other)) == 1;
    }

    public void delete_session(Address address) throws Error {
        throw_by_code(Protocol.Session.delete_session(native_context, address));
    }

    public SessionRecord load_session(Address other) throws Error {
        SessionRecord record;
        throw_by_code(Protocol.Session.load_session(native_context, out record, other));
        return record;
    }

    public bool contains_pre_key(uint32 pre_key_id) throws Error {
        return throw_by_code(Protocol.PreKey.contains_key(native_context, pre_key_id)) == 1;
    }

    public void store_pre_key(PreKeyRecord record) throws Error {
        throw_by_code(Protocol.PreKey.store_key(native_context, record));
    }

    public PreKeyRecord load_pre_key(uint32 pre_key_id) throws Error {
        PreKeyRecord res;
        throw_by_code(Protocol.PreKey.load_key(native_context, out res, pre_key_id));
        return res;
    }

    public bool contains_signed_pre_key(uint32 pre_key_id) throws Error {
        return throw_by_code(Protocol.SignedPreKey.contains_key(native_context, pre_key_id)) == 1;
    }

    public void store_signed_pre_key(SignedPreKeyRecord record) throws Error {
        throw_by_code(Protocol.SignedPreKey.store_key(native_context, record));
    }

    public SignedPreKeyRecord load_signed_pre_key(uint32 pre_key_id) throws Error {
        SignedPreKeyRecord res;
        throw_by_code(Protocol.SignedPreKey.load_key(native_context, out res, pre_key_id));
        return res;
    }
}

}
