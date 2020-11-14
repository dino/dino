using Gee;

public class WeakMap<K, V> : Gee.AbstractMap<K, V> {

    private HashMap<K, weak V> hash_map;
    private HashMap<K, WeakNotifyWrapper> notify_map;

    public WeakMap(owned HashDataFunc<K>? key_hash_func = null, owned EqualDataFunc<K>? key_equal_func = null, owned EqualDataFunc<V>? value_equal_func = null) {
        if (!typeof(V).is_object()) {
            error("WeakMap only takes values that are Objects");
        }

        hash_map = new HashMap<K, weak V>(key_hash_func, key_equal_func, value_equal_func);
        notify_map = new HashMap<K, WeakNotifyWrapper>(key_hash_func, key_equal_func, value_equal_func);
    }

    public override void clear() {
        foreach (K key in notify_map.keys) {
            Object o = (Object) hash_map[key];
            o.weak_unref(notify_map[key].func);
        }
        hash_map.clear();
        notify_map.clear();
    }

    public override V @get(K key) {
        if (!hash_map.has_key(key)) return null;

        var v = hash_map[key];

        return (owned) v;
    }

    public override bool has(K key, V value) {
        assert_not_reached();
    }

    public override bool has_key(K key) {
        return hash_map.has_key(key);
    }

    public override Gee.MapIterator<K,V> map_iterator() {
        assert_not_reached();
    }

    public override void @set(K key, V value) {
        assert(value != null);

        unset(key);

        Object v_obj = (Object) value;
        var notify_wrap = new WeakNotifyWrapper((obj) => {
            hash_map.unset(key);
            notify_map.unset(key);
        });
        notify_map[key] = notify_wrap;
        v_obj.weak_ref(notify_wrap.func);

        hash_map[key] = value;
    }

    public override bool unset(K key, out V value = null) {
        if (!hash_map.has_key(key)) return false;

        Object v_obj = (Object) hash_map[key];
        v_obj.weak_unref(notify_map[key].func);
        notify_map.unset(key);
        return hash_map.unset(key);
    }
    public override Gee.Set<Gee.Map.Entry<K,V>> entries { owned get; }

    [CCode (notify = false)]
    public Gee.EqualDataFunc<K> key_equal_func {
        get { return hash_map.key_equal_func; }
    }

    [CCode (notify = false)]
    public Gee.HashDataFunc<K> key_hash_func {
        get { return hash_map.key_hash_func; }
    }

    public override Gee.Set<K> keys {
        owned get { return hash_map.keys; }
    }

    public override bool read_only { get { assert_not_reached(); } }

    public override int size { get { return hash_map.size; } }

    [CCode (notify = false)]
    public Gee.EqualDataFunc<V> value_equal_func {
        get { return hash_map.value_equal_func; }
    }

    public override Gee.Collection<V> values {
        owned get {
            assert_not_reached();
        }
    }

    public override void dispose() {
        foreach (K key in notify_map.keys) {
            Object o = (Object) hash_map[key];
            o.weak_unref(notify_map[key].func);
        }
    }
}

internal class WeakNotifyWrapper {
    public WeakNotify func;

    public WeakNotifyWrapper(owned WeakNotify func) {
        this.func = (owned) func;
    }
}