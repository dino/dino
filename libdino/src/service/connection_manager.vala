using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ConnectionManager : Object {

    public signal void stream_opened(Account account, XmppStream stream);
    public signal void connection_state_changed(Account account, ConnectionState state);
    public signal void connection_error(Account account, ConnectionError error);

    public enum ConnectionState {
        CONNECTED,
        CONNECTING,
        DISCONNECTED
    }

    private HashSet<Account> connection_todo = new HashSet<Account>(Account.hash_func, Account.equals_func);
    private HashMap<Account, Connection> connections = new HashMap<Account, Connection>(Account.hash_func, Account.equals_func);
    private HashMap<Account, ConnectionError> connection_errors = new HashMap<Account, ConnectionError>(Account.hash_func, Account.equals_func);

    private NetworkMonitor? network_monitor;
    private Login1Manager? login1;
    private ModuleManager module_manager;
    public string? log_options;

    public class ConnectionError {

        public enum Source {
            CONNECTION,
            SASL,
            TLS,
            STREAM_ERROR
        }

        public enum Reconnect {
            NOW,
            LATER,
            NEVER
        }

        public Source source;
        public string? identifier;
        public Reconnect reconnect_recomendation { get; set; default=Reconnect.NOW; }

        public ConnectionError(Source source, string? identifier) {
            this.source = source;
            this.identifier = identifier;
        }
    }

    private class Connection {
        public XmppStream stream { get; set; }
        public ConnectionState connection_state { get; set; default = ConnectionState.DISCONNECTED; }
        public DateTime established { get; set; }
        public DateTime last_activity { get; set; }
        public class Connection(XmppStream stream, DateTime established) {
            this.stream = stream;
            this.established = established;
        }
    }

    public ConnectionManager(ModuleManager module_manager) {
        this.module_manager = module_manager;
        network_monitor = GLib.NetworkMonitor.get_default();
        if (network_monitor != null) {
            network_monitor.network_changed.connect(on_network_changed);
            network_monitor.notify["connectivity"].connect(on_network_changed);
        }
        login1 = get_login1();
        if (login1 != null) {
            login1.PrepareForSleep.connect(on_prepare_for_sleep);
        }
        Timeout.add_seconds(60, () => {
            foreach (Account account in connection_todo) {
                if (connections[account].last_activity != null &&
                        connections[account].last_activity.compare(new DateTime.now_utc().add_minutes(-1)) < 0) {
                    check_reconnect(account);
                }
            }
            return true;
        });
    }

    public XmppStream? get_stream(Account account) {
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

    public Collection<Account> get_managed_accounts() {
        return connection_todo;
    }

    public void connect_account(Account account) {
        if (!connection_todo.contains(account)) connection_todo.add(account);
        if (!connections.has_key(account)) {
            connect_(account);
        } else {
            check_reconnect(account);
        }
    }

    public void make_offline_all() {
        foreach (Account account in connections.keys) {
            make_offline(account);
        }
    }

    private void make_offline(Account account) {
        Xmpp.Presence.Stanza presence = new Xmpp.Presence.Stanza();
        presence.type_ = Xmpp.Presence.Stanza.TYPE_UNAVAILABLE;
        change_connection_state(account, ConnectionState.DISCONNECTED);
        connections[account].stream.get_module(Presence.Module.IDENTITY).send_presence(connections[account].stream, presence);
    }

    public async void disconnect_account(Account account) {
        if (connections.has_key(account)) {
            make_offline(account);
            try {
                yield connections[account].stream.disconnect();
            } catch (Error e) {
                debug("Error disconnecting stream: %s", e.message);
            }
            connection_todo.remove(account);
            if (connections.has_key(account)) {
                connections.unset(account);
            }
        }
    }

    private void connect_(Account account, string? resource = null) {
        if (connections.has_key(account)) connections[account].stream.detach_modules();
        connection_errors.unset(account);
        if (resource == null) resource = account.resourcepart;

        XmppStream stream = new XmppStream();
        foreach (XmppStreamModule module in module_manager.get_modules(account, resource)) {
            stream.add_module(module);
        }
        stream.log = new XmppLog(account.bare_jid.to_string(), log_options);
        debug("[%s] New connection with resource %s: %p", account.bare_jid.to_string(), resource, stream);

        Connection connection = new Connection(stream, new DateTime.now_utc());
        connections[account] = connection;
        change_connection_state(account, ConnectionState.CONNECTING);
        stream.attached_modules.connect((stream) => {
            change_connection_state(account, ConnectionState.CONNECTED);
        });
        stream.get_module(Sasl.Module.IDENTITY).received_auth_failure.connect((stream, node) => {
            set_connection_error(account, new ConnectionError(ConnectionError.Source.SASL, null));
        });
        stream.get_module(Tls.Module.IDENTITY).invalid_certificate.connect(() => {
            set_connection_error(account, new ConnectionError(ConnectionError.Source.TLS, null) { reconnect_recomendation=ConnectionError.Reconnect.NEVER});
        });
        stream.received_node.connect(() => {
            connection.last_activity = new DateTime.now_utc();
        });
        connect_async.begin(account, stream);
        stream_opened(account, stream);
    }

    private async void connect_async(Account account, XmppStream stream) {
        try {
            yield stream.connect(account.domainpart);
        } catch (Error e) {
            debug("[%s %p] Error: %s", account.bare_jid.to_string(), stream, e.message);
            change_connection_state(account, ConnectionState.DISCONNECTED);
            if (!connection_todo.contains(account)) {
                return;
            }
            StreamError.Flag? flag = stream.get_flag(StreamError.Flag.IDENTITY);
            if (flag != null) {
                warning(@"[%s %p] Stream Error: %s", account.bare_jid.to_string(), stream, flag.error_type);
                set_connection_error(account, new ConnectionError(ConnectionError.Source.STREAM_ERROR, flag.error_type));

                if (flag.resource_rejected) {
                    connect_(account, account.resourcepart + "-" + random_uuid());
                    return;
                }
            }

            ConnectionError? error = connection_errors[account];
            if (error != null && error.source == ConnectionError.Source.SASL) {
                return;
            }

            debug("[%s] Check reconnect in 5 sec", account.bare_jid.to_string());
            Timeout.add_seconds(5, () => {
                check_reconnect(account);
                return false;
            });
        }
    }

    private void check_reconnects() {
        foreach (Account account in connection_todo) {
            check_reconnect(account);
        }
    }

    private void check_reconnect(Account account) {
        if (!connections.has_key(account)) return;

        bool acked = false;
        DateTime? last_activity_was = connections[account].last_activity;

        XmppStream stream = connections[account].stream;
        stream.get_module(Xep.Ping.Module.IDENTITY).send_ping.begin(stream, account.bare_jid.domain_jid, () => {
            acked = true;
            if (connections[account].stream != stream) return;
            change_connection_state(account, ConnectionState.CONNECTED);
        });

        Timeout.add_seconds(10, () => {
            if (!connections.has_key(account)) return false;
            if (connections[account].stream != stream) return false;
            if (acked) return false;
            if (connections[account].last_activity != last_activity_was) return false;

            // Reconnect. Nothing gets through the stream.
            debug("[%s %p] Ping timeouted. Reconnecting", account.bare_jid.to_string(), stream);
            change_connection_state(account, ConnectionState.DISCONNECTED);

            connections[account].stream.disconnect.begin((_, res) => {
                try {
                    connections[account].stream.disconnect.end(res);
                } catch (Error e) {
                    debug("Error disconnecting stream: %s", e.message);
                }
            });

            connect_(account);
            return false;
        });
    }

    private bool network_is_online() {
        /* FIXME: We should also check for connectivity eventually. For more
         * details on why we don't do it for now, see:
         *
         * - https://github.com/dino/dino/pull/236#pullrequestreview-86851793
         * - https://bugzilla.gnome.org/show_bug.cgi?id=792240
         */
        return network_monitor != null && network_monitor.network_available;
    }

    private void on_network_changed() {
        if (network_is_online()) {
            debug("NetworkMonitor: Network reported online");
            check_reconnects();
        } else {
            debug("NetworkMonitor: Network reported offline");
            foreach (Account account in connection_todo) {
                change_connection_state(account, ConnectionState.DISCONNECTED);
            }
        }
    }

    private async void on_prepare_for_sleep(bool suspend) {
        foreach (Account account in connection_todo) {
            change_connection_state(account, ConnectionState.DISCONNECTED);
        }
        if (suspend) {
            debug("Login1: Device suspended");
            foreach (Account account in connection_todo) {
                try {
                    make_offline(account);
                    yield connections[account].stream.disconnect();
                } catch (Error e) {
                    debug("Error disconnecting stream %p: %s", connections[account].stream, e.message);
                }
            }
        } else {
            debug("Login1: Device un-suspend");
            check_reconnects();
        }
    }

    private void change_connection_state(Account account, ConnectionState state) {
        if (connections.has_key(account)) {
            connections[account].connection_state = state;
            connection_state_changed(account, state);
        }
    }

    private void set_connection_error(Account account, ConnectionError error) {
        connection_errors[account] = error;
        connection_error(account, error);
    }
}

}
