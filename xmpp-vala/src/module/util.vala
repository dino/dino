using Gee;

namespace Xmpp {
    public string get_bare_jid(string jid) {
        return jid.split("/")[0];
    }

    public bool is_bare_jid(string jid) {
        return !jid.contains("/");
    }

    public string? get_resource_part(string jid) {
        return jid.split("/")[1];
    }

    public string random_uuid() {
        uint32 b1 = Random.next_int();
        uint16 b2 = (uint16)Random.next_int();
        uint16 b3 = (uint16)(Random.next_int() | 0x4000u) & ~0xb000u;
        uint16 b4 = (uint16)(Random.next_int() | 0x8000u) & ~0x4000u;
        uint16 b5_1 = (uint16)Random.next_int();
        uint32 b5_2 = Random.next_int();
        return "%08x-%04x-%04x-%04x-%04x%08x".printf(b1, b2, b3, b4, b5_1, b5_2);
    }

public abstract class StanzaListener<T> : Object {
    public abstract string action_group { get; }
    public abstract string[] after_actions { get; }
    public abstract async void run(Core.XmppStream stream, T stanza);
}

public class StanzaListenerHolder<T> : Object {
    private ArrayList<StanzaListener<T>> listeners = new ArrayList<StanzaListener<T>>();

    public new void connect(StanzaListener<T> listener) {
        listeners.add(listener);
        resort_list();
    }

    public new void disconnect(StanzaListener<T> listener) {
        listeners.remove(listener);
        resort_list();
    }

    public async void run(Core.XmppStream stream, T stanza) {
        foreach (StanzaListener<T> l in listeners) {
            yield l.run(stream, stanza);
        }
    }

    private Gee.List<StanzaListener<T>> set_minus(Gee.List<StanzaListener<T>> main_set, Gee.List<StanzaListener<T>> minus) {
        Gee.List<StanzaListener<T>> res = new ArrayList<StanzaListener<T>>();
        foreach (StanzaListener<T> l in main_set) {
            if (!minus.contains(l)) {
                res.add(l);
            }
        }
        return res;
    }

    private bool set_contains_action(Gee.List<StanzaListener<T>> s, string[] actions) {
        foreach(StanzaListener<T> l in s) {
            if (l.action_group in actions) {
                return true;
            }
        }
        return false;
    }

    private void resort_list() {
        ArrayList<StanzaListener<T>> new_list = new ArrayList<StanzaListener<T>>();
        while (listeners.size > new_list.size) {
            bool changed = false;
            foreach (StanzaListener<T> l in listeners) {
                Gee.List<StanzaListener<T>> remaining = set_minus(listeners, new_list);
                if (!set_contains_action(remaining, l.after_actions)) {
                    new_list.add(l);
                    changed = true;
                }
            }
            if (!changed) warning("Can't sort listeners");
        }
        listeners = new_list;
    }
}

}
