using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.InBandBytestreams {

private const string NS_URI = "http://jabber.org/protocol/ibb";
private const int SEQ_MODULUS = 65536;

public class Module : XmppStreamModule, Iq.Handler {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0047_in_band_bytestreams");

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
    }
    public override void detach(XmppStream stream) {
        stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI, this);
    }

    public async void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        // the iq module ensures that there's only one child node
        StanzaNode? node = null;
        node = (node != null) ? node : iq.stanza.get_subnode("open", NS_URI);
        node = (node != null) ? node : iq.stanza.get_subnode("data", NS_URI);
        node = (node != null) ? node : iq.stanza.get_subnode("close", NS_URI);
        if (node == null) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("unknown IBB action")) { to=iq.from });
            return;
        }
        string? sid = node.get_attribute("sid");
        if (sid == null) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("missing sid")) { to=iq.from });
            return;
        }
        Connection? conn = stream.get_flag(Flag.IDENTITY).get_connection(sid);
        if (node.name == "open") {
            if (conn == null) {
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.not_acceptable("unexpected IBB connection")) { to=iq.from });
                return;
            }
            if (conn.state != Connection.State.WAITING_FOR_CONNECT) {
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("IBB open for already open connection")) { to=iq.from });
                return;
            }
            conn.handle_open(stream, node, iq);
        } else {
            if (conn == null || conn.state != Connection.State.CONNECTED) {
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.item_not_found()) { to=iq.from });
                return;
            }
            if (node.name == "close") {
                conn.handle_close(stream, node, iq);
            } else {
                conn.handle_data(stream, node, iq);
            }
        }
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Connection : IOStream {
    public class Input : InputStream {
        private weak Connection connection;
        public Input(Connection connection) {
            this.connection = connection;
        }
        public override ssize_t read(uint8[] buffer, Cancellable? cancellable = null) throws IOError {
            throw new IOError.NOT_SUPPORTED("can't do non-async reads on in-band bytestreams");
        }
        public override async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.read_async(buffer, io_priority, cancellable);
        }
        public override bool close(Cancellable? cancellable = null) throws IOError {
            throw new IOError.NOT_SUPPORTED("can't do non-async closes on in-band bytestreams");
        }
        public override async bool close_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.close_read_async(io_priority, cancellable);
        }
    }
    public class Output : OutputStream {
        private weak Connection connection;
        public Output(Connection connection) {
            this.connection = connection;
        }
        public override ssize_t write(uint8[] buffer, Cancellable? cancellable = null) throws IOError {
            throw new IOError.NOT_SUPPORTED("can't do non-async writes on in-band bytestreams");
        }
        public override async ssize_t write_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.write_async(buffer, io_priority, cancellable);
        }
        public override bool close(Cancellable? cancellable = null) throws IOError {
            throw new IOError.NOT_SUPPORTED("can't do non-async closes on in-band bytestreams");
        }
        public override async bool close_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.close_write_async(io_priority, cancellable);
        }
    }

    private Input input;
    private Output output;
    public override InputStream input_stream { get { return input; } }
    public override OutputStream output_stream { get { return output; } }

    public enum State {
        WAITING_FOR_CONNECT,
        CONNECTING,
        CONNECTED,
        DISCONNECTING,
        DISCONNECTED,
        ERROR,
    }
    public State state { get; private set; }
    Jid receiver_full_jid;
    public string sid { get; private set; }
    int block_size;
    int local_seq = 0;
    int remote_ack = 0;
    internal int remote_seq = 0;

    bool input_closed = false;
    bool output_closed = false;

    // ERROR
    string? error = null;

    XmppStream stream;

    int read_callback_priority;
    Cancellable? read_callback_cancellable = null;
    ulong read_callback_cancellable_id;
    SourceFunc? read_callback = null;
    int write_callback_priority;
    SourceFunc? write_callback = null;
    ulong write_callback_cancellable_id;
    Cancellable? write_callback_cancellable = null;
    // Need `Bytes` instead of `uint8[]` because the latter doesn't work in
    // parameter position of `LinkedList`.
    LinkedList<Bytes> received = new LinkedList<Bytes>();

    private Connection(XmppStream stream, Jid receiver_full_jid, string sid, int block_size, bool initiate) {
        this.stream = stream;
        this.receiver_full_jid = receiver_full_jid;
        this.sid = sid;
        this.block_size = block_size;
        this.state = initiate ? State.CONNECTING : State.WAITING_FOR_CONNECT;

        input = new Input(this);
        output = new Output(this);
    }

    public void set_read_callback(owned SourceFunc callback, Cancellable? cancellable, int io_priority) throws IOError {
        if (read_callback != null) {
            throw new IOError.PENDING("only one async read is permitted at a time on an in-band bytestream");
        }
        if (cancellable != null) {
            read_callback_cancellable_id = cancellable.connect(trigger_read_callback);
        }
        read_callback = (owned)callback;
        read_callback_cancellable = cancellable;
        read_callback_priority = io_priority;
    }
    public void set_write_callback(owned SourceFunc callback, Cancellable? cancellable, int io_priority) throws IOError {
        if (write_callback != null) {
            throw new IOError.PENDING("only one async write is permitted at a time on an in-band bytestream");
        }
        if (cancellable != null) {
            write_callback_cancellable_id = cancellable.connect(trigger_write_callback);
        }
        write_callback = (owned)callback;
        write_callback_cancellable = cancellable;
        write_callback_priority = io_priority;
    }
    public void trigger_read_callback() {
        if (read_callback != null) {
            Idle.add((owned) read_callback, read_callback_priority);
            read_callback = null;
            if (read_callback_cancellable != null) {
                read_callback_cancellable.disconnect(read_callback_cancellable_id);
            }
            read_callback_cancellable = null;
        }
    }
    public void trigger_write_callback() {
        if (write_callback != null) {
            Idle.add((owned) write_callback, write_callback_priority);
            write_callback = null;
            if (write_callback_cancellable != null) {
                write_callback_cancellable.disconnect(write_callback_cancellable_id);
            }
            write_callback_cancellable = null;
        }
    }

    public async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        while (true) {
            if (cancellable != null) {
                cancellable.set_error_if_cancelled();
            }
            if (input_closed) {
                return 0;
            }
            Bytes? chunk = received.poll();
            if (chunk != null) {
                int read = int.min(buffer.length, chunk.length);
                for (int i = 0; i < read; i++) {
                    buffer[i] = chunk[i];
                }
                if (buffer.length < chunk.length) {
                    received.offer_head(chunk[buffer.length:chunk.length]);
                }
                return read;
            }
            if (state == Connection.State.DISCONNECTED) {
                return 0;
            }
            set_read_callback(read_async.callback, cancellable, io_priority);
            yield;
        }
    }

    public async ssize_t write_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        while (state == State.WAITING_FOR_CONNECT || state == State.CONNECTING) {
            if (cancellable != null) {
                cancellable.set_error_if_cancelled();
            }
            set_write_callback(write_async.callback, cancellable, io_priority);
            yield;
        }
        throw_if_closed();
        assert(state == State.CONNECTED);
        // TODO(hrxi): merging?
        int seq = local_seq;
        local_seq = (local_seq + 1) % SEQ_MODULUS;
        if (buffer.length > block_size) {
            buffer = buffer[0:block_size];
        }
        StanzaNode data = new StanzaNode.build("data", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid)
            .put_attribute("seq", seq.to_string())
            .put_node(new StanzaNode.text(Base64.encode(buffer)));
        Iq.Stanza iq = new Iq.Stanza.set(data) { to=receiver_full_jid };
        set_write_callback(write_async.callback, cancellable, io_priority);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            if (iq.is_error()) {
                set_error("sending failed");
            } else if (remote_ack != seq) {
                set_error("out of order acks");
            } else {
                remote_ack = (remote_ack + 1) % SEQ_MODULUS;
                if (local_seq == remote_ack) {
                    trigger_write_callback();
                }
            }
        });
        yield;
        if (cancellable != null) {
            cancellable.set_error_if_cancelled();
        }
        throw_if_error();
        return buffer.length;
    }

    public async bool close_read_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        input_closed = true;
        if (!output_closed) {
            return true;
        }
        return yield close_async_impl(io_priority, cancellable);
    }
    public async bool close_write_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        output_closed = true;
        if (!input_closed) {
            return true;
        }
        return yield close_async_impl(io_priority, cancellable);
    }
    delegate void OnClose(bool success);
    private bool close_impl(Cancellable? cancellable, OnClose on_close) {
        if (state == State.DISCONNECTING || state == State.DISCONNECTED || state == State.ERROR) {
            on_close(true);
            return true;
        }
        if (state == State.WAITING_FOR_CONNECT) {
            state = State.DISCONNECTED;
            stream.get_flag(Flag.IDENTITY).remove_connection(this);
            trigger_read_callback();
            on_close(true);
            return true;
        }
        state = State.DISCONNECTING;
        StanzaNode close = new StanzaNode.build("close", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid);
        Iq.Stanza iq = new Iq.Stanza.set(close) { to=receiver_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            assert(state == State.DISCONNECTING);
            if (iq.is_error()) {
                set_error("disconnecting failed");
            } else {
                state = State.DISCONNECTED;
            }
            stream.get_flag(Flag.IDENTITY).remove_connection(this);
            trigger_read_callback();
            on_close(!iq.is_error());
        });
        return true;
    }
    private async bool close_async_impl(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        SourceFunc callback = close_async_impl.callback;
        close_impl(cancellable, () => { Idle.add((owned) callback); });
        yield;
        throw_if_error();
        return true;
    }

    public static Connection create(XmppStream stream, Jid receiver_full_jid, string sid, int block_size, bool initiate) {
        Connection conn = new Connection(stream, receiver_full_jid, sid, block_size, initiate);
        if (initiate) {
            StanzaNode open = new StanzaNode.build("open", NS_URI)
                .add_self_xmlns()
                .put_attribute("block-size", block_size.to_string())
                .put_attribute("sid", sid);

            Iq.Stanza iq = new Iq.Stanza.set(open) { to=receiver_full_jid };
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
                if (conn.state != State.CONNECTING) {
                    assert(conn.state != State.CONNECTED);
                    return;
                }
                if (!iq.is_error()) {
                    conn.state = State.CONNECTED;
                    stream.get_flag(Flag.IDENTITY).add_connection(conn);
                    conn.trigger_write_callback();
                } else {
                    conn.set_error("connection failed");
                }
            });
        } else {
            stream.get_flag(Flag.IDENTITY).add_connection(conn);
        }
        return conn;
    }

    void throw_if_error() throws IOError {
        if (state == State.ERROR) {
            throw new IOError.FAILED(error);
        }
    }

    void throw_if_closed() throws IOError {
        throw_if_error();
        if (state == State.DISCONNECTING || state == State.DISCONNECTED) {
            throw new IOError.CLOSED("can't read/write on a closed connection");
        }
    }

    void set_error(string error) {
        if (state != State.WAITING_FOR_CONNECT && state != State.DISCONNECTING && state != State.DISCONNECTED && state != State.ERROR) {
            close_async.begin();
        }
        state = State.ERROR;
        this.error = error;
        stream.get_flag(Flag.IDENTITY).remove_connection(this);
    }

    public void handle_open(XmppStream stream, StanzaNode open, Iq.Stanza iq) {
        assert(state == State.WAITING_FOR_CONNECT);
        int block_size = open.get_attribute_int("block-size");
        string? stanza = open.get_attribute("stanza");
        if (block_size < 0 || (stanza != null && stanza != "iq" && stanza != "message")) {
            set_error("invalid open");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("missing block_size or invalid stanza")) { to=iq.from });
            return;
        }
        if (stanza != null && stanza != "iq") {
            set_error("invalid open");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.feature_not_implemented("cannot use message stanzas for IBB")) { to=iq.from });
            return;
        }
        if (block_size > this.block_size) {
            set_error("invalid open");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.build(ErrorStanza.TYPE_CANCEL, ErrorStanza.CONDITION_RESOURCE_CONSTRAINT, "opening a connection with a greater than negotiated/acceptable block size", null)) { to=iq.from });
            return;
        }
        this.block_size = block_size;
        state = State.CONNECTED;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        trigger_write_callback();
    }
    public void handle_data(XmppStream stream, StanzaNode data, Iq.Stanza iq) {
        assert(state == State.CONNECTED);
        if (input_closed) {
            set_error("unexpected data");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.not_allowed("unexpected data")) { to=iq.from });
            return;
        }
        int seq = data.get_attribute_int("seq");
        // TODO(hrxi): return an error on malformed base64 (need to do this
        // according to the xep)
        uint8[] content = Base64.decode(data.get_string_content());
        if (content.length > block_size) {
            set_error("data longer than negotiated block size");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("data longer than negotiated block size")) { to=iq.from });
            return;
        }
        if (seq < 0 || seq != remote_seq) {
            set_error("out of order data packets");
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.build(ErrorStanza.TYPE_CANCEL, ErrorStanza.CONDITION_UNEXPECTED_REQUEST, "out of order data packets", null)) { to=iq.from });
            return;
        }
        remote_seq = (remote_seq + 1) % SEQ_MODULUS;

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        if (content.length != 0) {
            received.offer(new Bytes.take(content));
            trigger_read_callback();
        }
    }
    public void handle_close(XmppStream stream, StanzaNode close, Iq.Stanza iq) {
        assert(state == State.CONNECTED);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        stream.get_flag(Flag.IDENTITY).remove_connection(this);
        input_closed = true;
        output_closed = true;
        state = State.DISCONNECTED;

        trigger_read_callback();
    }
}


public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "in_band_bytestreams");

    private HashMap<string, Connection> active = new HashMap<string, Connection>();

    public void add_connection(Connection conn) {
        active[conn.sid] = conn;
    }
    public Connection? get_connection(string sid) {
        return active.has_key(sid) ? active[sid] : null;
    }
    public void remove_connection(Connection conn) {
        active.unset(conn.sid);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
