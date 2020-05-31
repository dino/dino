using Gee;

namespace Xmpp {

public string random_uuid() {
    uint32 b1 = Random.next_int();
    uint16 b2 = (uint16)Random.next_int();
    uint16 b3 = (uint16)(Random.next_int() | 0x4000u) & ~0xb000u;
    uint16 b4 = (uint16)(Random.next_int() | 0x8000u) & ~0x4000u;
    uint16 b5_1 = (uint16)Random.next_int();
    uint32 b5_2 = Random.next_int();
    return "%08x-%04x-%04x-%04x-%04x%08x".printf(b1, b2, b3, b4, b5_1, b5_2);
}

public string random_seq() {
    int random_number = Random.int_range(0,9000);
    return random_number.to_string();
}

public abstract class StanzaListener<T> : OrderedListener {

    public abstract async bool run(XmppStream stream, T stanza);
}

public class StanzaListenerHolder<T> : ListenerHolder {

    public async bool run(XmppStream stream, T stanza) {

        // listeners can change e.g. when switching to another stream
        ArrayList<OrderedListener> listeners_copy = new ArrayList<OrderedListener>();
        listeners_copy.add_all(listeners);

        foreach (OrderedListener ol in listeners_copy) {
            StanzaListener<T> l = ol as StanzaListener<T>;
            bool stop = yield l.run(stream, stanza);
            if (stop) return true;
        }
        return false;
    }
}

public abstract class OrderedListener : Object {
    public abstract string action_group { get; }
    public abstract string[] after_actions { get; }
}

public abstract class ListenerHolder : Object {
    protected ArrayList<OrderedListener> listeners = new ArrayList<OrderedListener>();

    public new void connect(OrderedListener listener) {
        listeners.add(listener);
        resort_list();
    }

    public new void disconnect(OrderedListener listener) {
        listeners.remove(listener);
        resort_list();
    }

    private bool set_contains_action(Gee.List<OrderedListener> s, string[] actions) {
        foreach(OrderedListener l in s) {
            if (l.action_group in actions) {
                return true;
            }
        }
        return false;
    }

    private void resort_list() {
        ArrayList<OrderedListener> new_list = new ArrayList<OrderedListener>();
        ArrayList<OrderedListener> remaining = new ArrayList<OrderedListener>();
        remaining.add_all(listeners);
        while (remaining.size > 0) {
            bool changed = false;
            Gee.Iterator<OrderedListener> iter = remaining.iterator();
            while (iter.has_next()) {
                iter.next();
                OrderedListener l = iter.get();
                if (!set_contains_action(remaining, l.after_actions)) {
                    new_list.add(l);
                    iter.remove();
                    changed = true;
                }
            }
            if (!changed) error("Can't sort listeners");
        }
        listeners = new_list;
    }
}

}
