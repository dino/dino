using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ConnectionManager {

    public signal void stream_opened(Account account, Core.XmppStream stream);
    public signal void connection_state_changed(Account account, ConnectionState state);

    public enum ConnectionState {
        CONNECTED,
        CONNECTING,
        DISCONNECTED
    }

    private ArrayList<Account> connection_todo = new ArrayList<Account>(Account.equals_func);
    private HashMap<Account, Connection> stream_states = new HashMap<Account, Connection>(Account.hash_func, Account.equals_func);
    private NetworkManager? network_manager;
    private Login1Manager? login1;
    private ModuleManager module_manager;

    private class Connection {
        public Core.XmppStream stream { get; set; }
        public ConnectionState connection_state { get; set; default = ConnectionState.DISCONNECTED; }
        public DateTime established { get; set; }
        public class Connection(Core.XmppStream stream, DateTime established) {
            this.stream = stream;
            this.established = established;
        }
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
    }

    public Core.XmppStream? get_stream(Account account) {
        if (get_connection_state(account) == ConnectionState.CONNECTED) {
            return stream_states[account].stream;
        }
        return null;
    }

    public ConnectionState get_connection_state(Account account) {
        if (stream_states.has_key(account)){
            return stream_states[account].connection_state;
        }
        return ConnectionState.DISCONNECTED;
    }

    public ArrayList<Account> get_managed_accounts() {
        return connection_todo;
    }

    public Core.XmppStream? connect(Account account) {
        if (!connection_todo.contains(account)) connection_todo.add(account);
        if (!stream_states.has_key(account)) {
            return connect_(account);
        } else {
            check_reconnect(account);
        }
        return null;
    }

    public void disconnect(Account account) {
        change_connection_state(account, ConnectionState.DISCONNECTED);
        if (stream_states.has_key(account)) {
            try {
                stream_states[account].stream.disconnect();
            } catch (Error e) { }
        }
        connection_todo.remove(account);
    }

    private Core.XmppStream? connect_(Account account, string? resource = null) {
        if (resource == null) resource = account.resourcepart;
        if (stream_states.has_key(account)) {
            stream_states[account].stream.remove_modules();
        }

        Core.XmppStream stream = new Core.XmppStream();
        foreach (Core.XmppStreamModule module in module_manager.get_modules(account, resource)) {
            stream.add_module(module);
        }
        stream.debug = false;

        Connection connection = new Connection(stream, new DateTime.now_local());
        stream_states[account] = connection;
        change_connection_state(account, ConnectionState.CONNECTING);
        stream.stream_negotiated.connect((stream) => {
            change_connection_state(account, ConnectionState.CONNECTED);
        });
        new Thread<void*> (null, () => {
            try {
                stream.connect(account.domainpart);
            } catch (Error e) {
                stderr.printf("Stream Error: %s\n", e.message);
                change_connection_state(account, ConnectionState.DISCONNECTED);
                interpret_reconnect_flags(account, StreamError.Flag.get_flag(stream) ??
                    new StreamError.Flag() { reconnection_recomendation = StreamError.Flag.Reconnect.NOW });
            }
            return null;
        });
        stream_opened(account, stream);

        return stream;
    }

    private void interpret_reconnect_flags(Account account, StreamError.Flag stream_error_flag) {
        if (!connection_todo.contains(account)) return;
        int wait_sec = 10;
        if (network_manager != null && network_manager.State != NetworkManager.CONNECTED_GLOBAL) {
            wait_sec = 60;
        }
        switch (stream_error_flag.reconnection_recomendation) {
            case StreamError.Flag.Reconnect.NOW:
                wait_sec = 10;
                break;
            case StreamError.Flag.Reconnect.LATER:
            case StreamError.Flag.Reconnect.UNKNOWN:
                wait_sec = 60;
                break;
            case StreamError.Flag.Reconnect.NEVER:
                return;
        }
        print(@"recovering in $wait_sec\n");
        Timeout.add_seconds(wait_sec, () => {
            if (stream_error_flag.resource_rejected) {
                connect_(account, account.resourcepart + "-" + random_uuid());
            } else {
                connect_(account);
            }
            return false;
        });
    }

    private void check_reconnects() {
        foreach (Account account in connection_todo) {
            check_reconnect(account);
        }
    }

    private void check_reconnect(Account account) {
        PingResponseListenerImpl ping_response_listener = new PingResponseListenerImpl(this, account);
        Core.XmppStream stream = stream_states[account].stream;
        stream.get_module(Xep.Ping.Module.IDENTITY).send_ping(stream, account.domainpart, ping_response_listener);

        Timeout.add_seconds(5, () => {
            if (stream_states[account].stream != stream) return false;
            if (ping_response_listener.acked) return false;

            change_connection_state(account, ConnectionState.DISCONNECTED);
            try {
                stream_states[account].stream.disconnect();
            } catch (Error e) { }
            return false;
        });
    }

    private class PingResponseListenerImpl : Xep.Ping.ResponseListener, Object {
        public bool acked = false;
        ConnectionManager outer;
        Account account;
        public PingResponseListenerImpl(ConnectionManager outer, Account account) {
            this.outer = outer;
            this.account = account;
        }
        public void on_result(Core.XmppStream stream) {
            print("ping ok\n");
            acked = true;
            outer.change_connection_state(account, ConnectionState.CONNECTED);
        }
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
                    stream_states[account].stream.get_module(Presence.Module.IDENTITY).send_presence(stream_states[account].stream, presence);
                    stream_states[account].stream.disconnect();
                } catch (Error e) { print(@"on_prepare_for_sleep error  $(e.message)\n"); }
            }
        } else {
            print("un-suspend\n");
            check_reconnects();
        }
    }

    private void change_connection_state(Account account, ConnectionState state) {
        stream_states[account].connection_state = state;
        connection_state_changed(account, state);
    }
}

}
