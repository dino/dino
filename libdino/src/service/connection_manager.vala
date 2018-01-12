using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ConnectionManager {

    public signal void stream_opened(Account account, XmppStream stream);
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
        public bool resource_rejected = false;

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

    public ArrayList<Account> get_managed_accounts() {
        return connection_todo;
    }

    public XmppStream? connect(Account account) {
        if (!connection_todo.contains(account)) connection_todo.add(account);
        if (!connections.has_key(account)) {
            return connect_(account);
        } else {
            check_reconnect(account);
        }
        return null;
    }

    public void make_offline_all() {
        foreach (Account account in connection_todo) {
            make_offline(account);
        }
    }

    private void make_offline(Account account) {
        Xmpp.Presence.Stanza presence = new Xmpp.Presence.Stanza();
        presence.type_ = Xmpp.Presence.Stanza.TYPE_UNAVAILABLE;
        change_connection_state(account, ConnectionState.DISCONNECTED);
        connections[account].stream.get_module(Presence.Module.IDENTITY).send_presence(connections[account].stream, presence);
    }

    public void disconnect(Account account) {
        make_offline(account);
        try {
            connections[account].stream.disconnect();
        } catch (Error e) { print(@"on_prepare_for_sleep error  $(e.message)\n"); }
        connection_todo.remove(account);
        if (connections.has_key(account)) {
            connections.unset(account);
        }
    }

    private XmppStream? connect_(Account account, string? resource = null) {
        if (connections.has_key(account)) connections[account].stream.detach_modules();
        connection_errors.unset(account);
        if (resource == null) resource = account.resourcepart;

        XmppStream stream = new XmppStream();
        foreach (XmppStreamModule module in module_manager.get_modules(account, resource)) {
            stream.add_module(module);
        }
        stream.log = new XmppLog(account.bare_jid.to_string(), log_options);

        Connection connection = new Connection(stream, new DateTime.now_utc());
        connections[account] = connection;
        change_connection_state(account, ConnectionState.CONNECTING);
        stream.attached_modules.connect((stream) => {
            change_connection_state(account, ConnectionState.CONNECTED);
        });
        stream.get_module(PlainSasl.Module.IDENTITY).received_auth_failure.connect((stream, node) => {
            set_connection_error(account, new ConnectionError(ConnectionError.Source.SASL, null));
            change_connection_state(account, ConnectionState.DISCONNECTED);
        });
        stream.received_node.connect(() => {
            connections[account].last_activity = new DateTime.now_utc();
        });
        connect_async.begin(account, stream);
        stream_opened(account, stream);

        return stream;
    }

    private async void connect_async(Account account, XmppStream stream) {
        try {
            yield stream.connect(account.domainpart);
        } catch (Error e) {
            stderr.printf("Stream Error: %s\n", e.message);
            change_connection_state(account, ConnectionState.DISCONNECTED);
            if (!connection_todo.contains(account)) {
                connections.unset(account);
                return;
            }
            if (e is IOStreamError.TLS) {
                set_connection_error(account, new ConnectionError(ConnectionError.Source.TLS, e.message) { reconnect_recomendation=ConnectionError.Reconnect.NEVER});
                return;
            }
            StreamError.Flag? flag = stream.get_flag(StreamError.Flag.IDENTITY);
            if (flag != null) {
                set_connection_error(account, new ConnectionError(ConnectionError.Source.STREAM_ERROR, flag.error_type) { resource_rejected=flag.resource_rejected });
            }
            interpret_connection_error(account);
        }
    }

    private void interpret_connection_error(Account account) {
        ConnectionError? error = connection_errors[account];
        int wait_sec = 5;
        if (error == null) {
            wait_sec = 3;
        } else if (error.source == ConnectionError.Source.STREAM_ERROR) {
            if (error.resource_rejected) {
                connect_(account, account.resourcepart + "-" + random_uuid());
                return;
            }
            switch (error.reconnect_recomendation) {
                case ConnectionError.Reconnect.NOW:
                    wait_sec = 5; break;
                case ConnectionError.Reconnect.LATER:
                    wait_sec = 60; break;
                case ConnectionError.Reconnect.NEVER:
                    return;
            }
        } else if (error.source == ConnectionError.Source.SASL) {
            return;
        }
        if (network_is_online()) {
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
        bool acked = false;

        XmppStream stream = connections[account].stream;
        stream.get_module(Xep.Ping.Module.IDENTITY).send_ping(stream, account.bare_jid.domain_jid, (stream) => {
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
            print("network online\n");
            check_reconnects();
        } else {
            print("network offline\n");
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

    private void set_connection_error(Account account, ConnectionError error) {
        connection_errors[account] = error;
        connection_error(account, error);
    }
}

}
