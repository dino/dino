using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ConnectionManager : Object {

    public signal void stream_opened(Account account, XmppStream stream);
    public signal void stream_attached_modules(Account account, XmppStream stream);
    public signal void connection_state_changed(Account account, ConnectionState state);
    public signal void connection_error(Account account, ConnectionError error);

    public enum ConnectionState {
        CONNECTED,
        CONNECTING,
        DISCONNECTED
    }

    private HashMap<Account, Connection> connections = new HashMap<Account, Connection>(Account.hash_func, Account.equals_func);
    private HashMap<Account, ConnectionError> connection_errors = new HashMap<Account, ConnectionError>(Account.hash_func, Account.equals_func);

    private HashMap<Account, bool> connection_ongoing = new HashMap<Account, bool>(Account.hash_func, Account.equals_func);
    private HashMap<Account, bool> connection_directly_retry = new HashMap<Account, bool>(Account.hash_func, Account.equals_func);

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
        public string uuid { get; set; }
        public XmppStream? stream { get; set; }
        public ConnectionState connection_state { get; set; default = ConnectionState.DISCONNECTED; }
        public DateTime? established { get; set; }
        public DateTime? last_activity { get; set; }

        public Connection() {
            reset();
        }

        public void reset() {
            if (stream != null) {
                stream.detach_modules();

                stream.disconnect.begin();
            }
            stream = null;
            established = last_activity = null;
            uuid = Xmpp.random_uuid();
        }

        public void make_offline() {
            Xmpp.Presence.Stanza presence = new Xmpp.Presence.Stanza();
            presence.type_ = Xmpp.Presence.Stanza.TYPE_UNAVAILABLE;
            if (stream != null) {
                stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence);
            }
        }

        public async void disconnect_account() {
            make_offline();

            if (stream != null) {
                try {
                    yield stream.disconnect();
                } catch (Error e) {
                    debug("Error disconnecting stream: %s", e.message);
                }
            }
        }
    }

    public ConnectionManager(ModuleManager module_manager) {
        this.module_manager = module_manager;
        network_monitor = GLib.NetworkMonitor.get_default();
        if (network_monitor != null) {
            network_monitor.network_changed.connect(on_network_changed);
            network_monitor.notify["connectivity"].connect(on_network_changed);
        }

        get_login1.begin((_, res) => {
            login1 = get_login1.end(res);
            if (login1 != null) {
                login1.PrepareForSleep.connect(on_prepare_for_sleep);
            }
        });

        Timeout.add_seconds(60, () => {
            foreach (Account account in connections.keys) {
                if (connections[account].last_activity == null ||
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
        return connections.keys;
    }

    public void connect_account(Account account) {
        if (!connections.has_key(account)) {
            connections[account] = new Connection();
            connection_ongoing[account] = false;
            connection_directly_retry[account] = false;

            connect_stream.begin(account);
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
        connections[account].make_offline();
        change_connection_state(account, ConnectionState.DISCONNECTED);
    }

    public async void disconnect_account(Account account) {
        if (connections.has_key(account)) {
            make_offline(account);
            connections[account].disconnect_account.begin();
            connections.unset(account);
        }
    }

    private async void connect_stream(Account account) {
        if (!connections.has_key(account)) return;

        debug("[%s] (Maybe) Establishing a new connection", account.bare_jid.to_string());

        connection_errors.unset(account);

        XmppStreamResult stream_result;

        if (connection_ongoing[account]) {
            debug("[%s] Connection attempt already in progress. Directly retry if it fails.", account.bare_jid.to_string());
            connection_directly_retry[account] = true;
            return;
        } else if (connections[account].stream != null) {
            debug("[%s] Cancelling connecting because there is already a stream", account.bare_jid.to_string());
            return;
        } else {
            connection_ongoing[account] = true;
            connection_directly_retry[account] = false;

            change_connection_state(account, ConnectionState.CONNECTING);
            stream_result = yield Xmpp.establish_stream(account.bare_jid, module_manager.get_modules(account), log_options,
                    (peer_cert, errors) => { return on_invalid_certificate(account.domainpart, peer_cert, errors); }
            );
            connections[account].stream = stream_result.stream;

            connection_ongoing[account] = false;
        }

        if (stream_result.stream == null) {
            if (stream_result.tls_errors != null) {
                set_connection_error(account, new ConnectionError(ConnectionError.Source.TLS, null) { reconnect_recomendation=ConnectionError.Reconnect.NEVER});
                return;
            }

            debug("[%s] Could not connect", account.bare_jid.to_string());

            change_connection_state(account, ConnectionState.DISCONNECTED);

            check_reconnect(account, connection_directly_retry[account]);

            return;
        }

        XmppStream stream = stream_result.stream;

        debug("[%s] New connection: %p", account.full_jid.to_string(), stream);

        connections[account].established = new DateTime.now_utc();
        stream.attached_modules.connect((stream) => {
            stream_attached_modules(account, stream);
            change_connection_state(account, ConnectionState.CONNECTED);

//            stream.get_module(Xep.Muji.Module.IDENTITY).join_call(stream, new Jid("test@muc.poez.io"), true);
        });
        stream.get_module(Sasl.Module.IDENTITY).received_auth_failure.connect((stream, node) => {
            set_connection_error(account, new ConnectionError(ConnectionError.Source.SASL, null));
        });

        string connection_uuid = connections[account].uuid;
        stream.received_node.connect(() => {
            if (connections[account].uuid == connection_uuid) {
                connections[account].last_activity = new DateTime.now_utc();
            } else {
                warning("Got node for outdated connection");
            }
        });
        stream_opened(account, stream);

        try {
            yield stream.loop();
        } catch (Error e) {
            debug("[%s %p] Connection error: %s", account.bare_jid.to_string(), stream, e.message);

            change_connection_state(account, ConnectionState.DISCONNECTED);
            if (!connections.has_key(account)) return;
            connections[account].reset();

            StreamError.Flag? flag = stream.get_flag(StreamError.Flag.IDENTITY);
            if (flag != null) {
                warning(@"[%s %p] Stream Error: %s", account.bare_jid.to_string(), stream, flag.error_type);
                set_connection_error(account, new ConnectionError(ConnectionError.Source.STREAM_ERROR, flag.error_type));

                if (flag.resource_rejected) {
                    account.set_random_resource();
                    connect_stream.begin(account);
                    return;
                }
            }

            ConnectionError? error = connection_errors[account];
            if (error != null && error.source == ConnectionError.Source.SASL) {
                return;
            }

            check_reconnect(account);
        }
    }

    private void check_reconnects() {
        foreach (Account account in connections.keys) {
            check_reconnect(account);
        }
    }

    private void check_reconnect(Account account, bool directly_reconnect = false) {
        if (!connections.has_key(account)) return;

        bool acked = false;
        DateTime? last_activity_was = connections[account].last_activity;

        if (connections[account].stream == null) {
            Timeout.add_seconds(10, () => {
                if (!connections.has_key(account)) return false;
                if (connections[account].stream != null) return false;
                if (connections[account].last_activity != last_activity_was) return false;

                connect_stream.begin(account);
                return false;
            });
            return;
        }

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

            connections[account].reset();
            connect_stream.begin(account);
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
            foreach (Account account in connections.keys) {
                change_connection_state(account, ConnectionState.DISCONNECTED);
            }
        }
    }

    private async void on_prepare_for_sleep(bool suspend) {
        foreach (Account account in connections.keys) {
            change_connection_state(account, ConnectionState.DISCONNECTED);
        }
        if (suspend) {
            debug("Login1: Device suspended");
            foreach (Account account in connections.keys) {
                try {
                    make_offline(account);
                    if (connections[account].stream != null) {
                        yield connections[account].stream.disconnect();
                    }
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

    public static bool on_invalid_certificate(string domain, TlsCertificate peer_cert, TlsCertificateFlags errors) {
        if (domain.has_suffix(".onion") && errors == TlsCertificateFlags.UNKNOWN_CA) {
            // It's barely possible for .onion servers to provide a non-self-signed cert.
            // But that's fine because encryption is provided independently though TOR.
            warning("Accepting TLS certificate from unknown CA from .onion address %s", domain);
            return true;
        }
        return false;
    }
}

}
