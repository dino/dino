using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ConnectionManager {

    public signal void stream_opened(Account account, Core.XmppStream stream);
    public signal void connection_state_changed(Account account, ConnectionState state);
    public signal void connection_error(Account account, ConnectionError error);

    public enum ConnectionState {
        CONNECTED,
        CONNECTING,
        DISCONNECTED
    }

    private ArrayList<Account> connection_todo = new ArrayList<Account>(Account.equals_func);
    private HashMap<Account, Connection> connections = new HashMap<Account, Connection>(Account.hash_func, Account.equals_func);
    private HashMap<Account, ConnectionError> connection_errors = new HashMap<Account, ConnectionError>(Account.hash_func, Account.equals_func);
    private HashMap<Account, RecMutexWrap> connection_mutexes = new HashMap<Account, RecMutexWrap>(Account.hash_func, Account.equals_func);

    private NetworkManager? network_manager;
    private Login1Manager? login1;
    private NetworkManagerDBusProperties? dbus_properties;
    private ModuleManager module_manager;
    public string? log_options;

    public class ConnectionError {

        public enum Source {
            CONNECTION,
            SASL,
            STREAM_ERROR
        }

        public Source source;
        public string? identifier;
        public StreamError.Flag? flag;

        public ConnectionError(Source source, string? identifier) {
            this.source = source;
            this.identifier = identifier;
        }
    }

    private class Connection {
        public Core.XmppStream stream { get; set; }
        public ConnectionState connection_state { get; set; default = ConnectionState.DISCONNECTED; }
        public DateTime established { get; set; }
        public DateTime last_activity { get; set; }
        public class Connection(Core.XmppStream stream, DateTime established) {
            this.stream = stream;
            this.established = established;
        }
    }

    private class RecMutexWrap {
        public RecMutex mutex = new RecMutex();
        public void lock() { mutex.lock(); }
        public void unlock() { mutex.unlock(); }
        public bool trylock() { return mutex.trylock(); }
    }

    public ConnectionManager(ModuleManager module_manager) {
        this.module_manager = module_manager;
        network_manager = get_network_manager();
        if (network_manager != null) {
            network_manager.StateChanged.connect(on_nm_state_changed);
        }
        login1 = get_login1();
        if (login1 != null) {
            login1.PrepareForSleep.connect(on_prepare_for_sleep);
        }
        dbus_properties = get_dbus_properties();
        if (dbus_properties != null) {
            dbus_properties.properties_changed.connect((s, sv, sa) => {
                foreach (string key in sv.get_keys()) {
                    if (key == "PrimaryConnection") {
                        print("primary connection changed\n");
                        check_reconnects();
                    }
                }
            });
        }
        Timeout.add_seconds(60, () => {
            foreach (Account account in connection_todo) {
                if (connections[account].last_activity.compare(new DateTime.now_utc().add_minutes(-1)) < 0) {
                    check_reconnect(account);
                }
            }
            return true;
        });
    }

    public Core.XmppStream? get_stream(Account account) {
        if (get_state(account) == ConnectionState.CONNECTED) {
            return connections[account].stream;
        }
        return null;
    }

    public ConnectionState get_state(Account account) {
        if (connections.has_key(account)){
            return connections[account].connection_state;
        }
        return ConnectionState.DISCONNECTED;
    }

    public ConnectionError? get_error(Account account) {
        if (connection_errors.has_key(account)) {
            return connection_errors[account];
        }
        return null;
    }

    public ArrayList<Account> get_managed_accounts() {
        return connection_todo;
    }

    public Core.XmppStream? connect(Account account) {
        if (!connection_mutexes.contains(account)) connection_mutexes[account] = new RecMutexWrap();
        if (!connection_todo.contains(account)) connection_todo.add(account);
        if (!connections.has_key(account)) {
            return connect_(account);
        } else {
            check_reconnect(account);
        }
        return null;
    }

    public void disconnect(Account account) {
        change_connection_state(account, ConnectionState.DISCONNECTED);
        connection_todo.remove(account);
        if (connections.has_key(account)) {
            try {
                connections[account].stream.disconnect();
                connections.unset(account);
            } catch (Error e) { }
        }
    }

    private Core.XmppStream? connect_(Account account, string? resource = null) {
        if (!connection_mutexes[account].trylock()) return null;

        if (connections.has_key(account)) connections[account].stream.remove_modules();
        connection_errors.unset(account);
        if (resource == null) resource = account.resourcepart;

        Core.XmppStream stream = new Core.XmppStream();
        foreach (Core.XmppStreamModule module in module_manager.get_modules(account, resource)) {
            stream.add_module(module);
        }
        stream.log = new Core.XmppLog(account.bare_jid.to_string(), log_options);

        Connection connection = new Connection(stream, new DateTime.now_utc());
        connections[account] = connection;
        change_connection_state(account, ConnectionState.CONNECTING);
        stream.attached_modules.connect((stream) => {
            change_connection_state(account, ConnectionState.CONNECTED);
        });
        stream.get_module(PlainSasl.Module.IDENTITY).received_auth_failure.connect((stream, node) => {
            set_connection_error(account, ConnectionError.Source.SASL, null);
            change_connection_state(account, ConnectionState.DISCONNECTED);
        });
        stream.received_node.connect(() => {
            connections[account].last_activity = new DateTime.now_utc();
        });
        new Thread<void*> (null, () => {
            try {
                stream.connect(account.domainpart);
            } catch (Error e) {
                stderr.printf("Stream Error: %s\n", e.message);
                change_connection_state(account, ConnectionState.DISCONNECTED);
                if (!connection_todo.contains(account)) {
                    connections.unset(account);
                    return null;
                }
                StreamError.Flag? flag = stream.get_flag(StreamError.Flag.IDENTITY);
                if (flag != null) {
                    set_connection_error(account, ConnectionError.Source.STREAM_ERROR, flag.error_type);
                }
                interpret_connection_error(account);
            }
            connection_mutexes[account].unlock();
            return null;
        });
        stream_opened(account, stream);

        connection_mutexes[account].unlock();
        return stream;
    }

    private void interpret_connection_error(Account account) {
        ConnectionError? error = connection_errors[account];
        int wait_sec = 5;
        if (error == null) {
            wait_sec = 3;
        } else if (error.source == ConnectionError.Source.STREAM_ERROR && error.flag != null) {
            if (error.flag.resource_rejected) {
                connect_(account, account.resourcepart + "-" + random_uuid());
                return;
            }
            switch (error.flag.reconnection_recomendation) {
                case StreamError.Flag.Reconnect.NOW:
                    wait_sec = 5; break;
                case StreamError.Flag.Reconnect.LATER:
                    wait_sec = 60; break;
                case StreamError.Flag.Reconnect.NEVER:
                    return;
            }
        } else if (error.source == ConnectionError.Source.SASL) {
            return;
        }
        if (network_manager != null && network_manager.State != NetworkManager.CONNECTED_GLOBAL) {
            wait_sec = 30;
        }
        print(@"recovering in $wait_sec\n");
        Timeout.add_seconds(wait_sec, () => {
            check_reconnect(account);
            return false;
        });
    }

    private void check_reconnects() {
        foreach (Account account in connection_todo) {
            check_reconnect(account);
        }
    }

    private void check_reconnect(Account account) {
        if (!connection_mutexes[account].trylock()) return;
        bool acked = false;

        Core.XmppStream stream = connections[account].stream;
        stream.get_module(Xep.Ping.Module.IDENTITY).send_ping(stream, account.domainpart, (stream) => {
            acked = true;
            change_connection_state(account, ConnectionState.CONNECTED);
        });

        Timeout.add_seconds(5, () => {
            if (connections[account].stream != stream) return false;
            if (acked) return false;

            change_connection_state(account, ConnectionState.DISCONNECTED);
            try {
                connections[account].stream.disconnect();
            } catch (Error e) { }
            connect_(account);
            connection_mutexes[account].unlock();
            return false;
        });
    }

    private void on_nm_state_changed(uint32 state) {
        print("nm " + state.to_string() + "\n");
        if (state == NetworkManager.CONNECTED_GLOBAL) {
            check_reconnects();
        } else {
            foreach (Account account in connection_todo) {
                change_connection_state(account, ConnectionState.DISCONNECTED);
            }
        }
    }

    private void on_prepare_for_sleep(bool suspend) {
        foreach (Account account in connection_todo) {
            change_connection_state(account, ConnectionState.DISCONNECTED);
        }
        if (suspend) {
            print("suspend\n");
            foreach (Account account in connection_todo) {
                Xmpp.Presence.Stanza presence = new Xmpp.Presence.Stanza();
                presence.type_ = Xmpp.Presence.Stanza.TYPE_UNAVAILABLE;
                try {
                    connections[account].stream.get_module(Presence.Module.IDENTITY).send_presence(connections[account].stream, presence);
                    connections[account].stream.disconnect();
                } catch (Error e) { print(@"on_prepare_for_sleep error  $(e.message)\n"); }
            }
        } else {
            print("un-suspend\n");
            check_reconnects();
        }
    }

    private void change_connection_state(Account account, ConnectionState state) {
        if (connections.has_key(account)) {
            connections[account].connection_state = state;
            connection_state_changed(account, state);
        }
    }

    private void set_connection_error(Account account, ConnectionError.Source source, string? id) {
        ConnectionError error = new ConnectionError(source, id);
        connection_errors[account] = error;
        connection_error(account, error);
    }
}

}
