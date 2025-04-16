using Gee;

namespace Omemo {

public class SimpleSessionStore : SessionStore {

    private Map<string, ArrayList<SessionStore.Session>> session_map = new HashMap<string, ArrayList<SessionStore.Session>>();

    public override uint8[]? load_session(Address address) throws Error {
        if (session_map.has_key(address.name)) {
            foreach (SessionStore.Session session in session_map[address.name]) {
                if (session.device_id == address.device_id) return session.record;
            }
        }
        return null;
    }

    public override IntList get_sub_device_sessions(string name) throws Error {
        IntList res = new IntList();
        if (session_map.has_key(name)) {
            foreach (SessionStore.Session session in session_map[name]) {
                res.add(session.device_id);
            }
        }
        return res;
    }

    public override void store_session(Address address, uint8[] record) throws Error {
        if (contains_session(address)) {
            delete_session(address);
        }
        if (!session_map.has_key(address.name)) {
            session_map[address.name] = new ArrayList<SessionStore.Session>();
        }
        SessionStore.Session session = new Session() { name = address.name, device_id = address.device_id, record = record };
        session_map[address.name].add(session);
        session_stored(session);
    }

    public override bool contains_session(Address address) throws Error {
        if (!session_map.has_key(address.name)) return false;
        foreach (SessionStore.Session session in session_map[address.name]) {
            if (session.device_id == address.device_id) return true;
        }
        return false;
    }

    public override void delete_session(Address address) throws Error {
        if (!session_map.has_key(address.name)) throw_by_code(ErrorCode.UNKNOWN, "No session found");
        foreach (SessionStore.Session session in session_map[address.name]) {
            if (session.device_id == address.device_id) {
                session_map[address.name].remove(session);
                if (session_map[address.name].size == 0) {
                    session_map.unset(address.name);
                }
                session_removed(session);
                return;
            }
        }
    }

    public override void delete_all_sessions(string name) throws Error {
        if (session_map.has_key(name)) {
            foreach (SessionStore.Session session in session_map[name]) {
                session_map[name].remove(session);
                if (session_map[name].size == 0) {
                    session_map.unset(name);
                }
                session_removed(session);
            }
        }
    }
}

}