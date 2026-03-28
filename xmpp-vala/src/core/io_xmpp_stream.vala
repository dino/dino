using Gee;

public interface Xmpp.WriteNodeFunc : Object {
    public abstract async void write_stanza(XmppStream stream, StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError;
}

public abstract class Xmpp.IoXmppStream : XmppStream {
    private IOStream? stream;
    internal Cancellable cancellable;
    internal StanzaReader? reader;
    internal StanzaWriter? writer;

    internal WriteNodeFunc? write_obj = null;

    protected IoXmppStream(Jid remote_name, Cancellable? cancellable = null) {
        base(remote_name);
        this.cancellable = cancellable ?? new Cancellable();
    }

    public void cancel() {
        cancellable.cancel();
    }

    public override async void disconnect() throws IOError {
        disconnected = true;
        cancel();
        if (writer == null || reader == null || stream == null) {
            throw new IOError.CLOSED("trying to disconnect, but no stream open");
        }
        log.str("OUT", "</stream:stream>", this);
        yield writer.write("</stream:stream>", Priority.LOW, new Cancellable());
        yield stream.close_async();
    }

    public void reset_stream(IOStream stream) {
        this.stream = stream;
        reader = new StanzaReader.for_stream(stream.input_stream, cancellable);
        writer = new StanzaWriter.for_stream(stream.output_stream, cancellable);
        require_setup();
    }

    public override async StanzaNode read() throws IOError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOError.NOT_CONNECTED("trying to read, but no stream open");
        StanzaNode node = yield ((!)reader).read_node();
        log.node("IN", node, this);
        return node;
    }

    [Version (deprecated = true, deprecated_since = "0.1", replacement = "write_async")]
    public override void write(StanzaNode node, int io_priority = Priority.DEFAULT) {
        write_async.begin(node, io_priority, null, (obj, res) => {
            try {
                write_async.end(res);
            } catch (Error e) {
                warning("Error while writing: %s", e.message);
            }
        });
    }

    public override async void write_async(StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        if (write_obj != null) {
            yield write_obj.write_stanza(this, node, io_priority, cancellable ?? this.cancellable);
        } else {
            StanzaWriter? writer = this.writer;
            if (writer == null) throw new IOError.NOT_CONNECTED("trying to write, but no stream open");
            log.node("OUT", node, this);
            yield ((!)writer).write_node(node, io_priority, cancellable ?? this.cancellable);
        }
    }

    internal IOStream? get_stream() {
        return stream;
    }

    public override async void setup() throws IOError {
        StanzaNode outs = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                .put_attribute("to", remote_name.to_string())
                .put_attribute("version", "1.0")
                .put_attribute("xmlns", "jabber:client")
                .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI);
        outs.has_nodes = true;
        log.node("OUT ROOT", outs, this);
        yield write_async(outs, Priority.HIGH, cancellable);
        received_root_node(this, yield read_root());

        setup_needed = false;
    }

    private async StanzaNode read_root() throws IOError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOError.NOT_CONNECTED("trying to read, but no stream open");
        StanzaNode node = yield ((!)reader).read_root_node();
        log.node("IN ROOT", node, this);
        return node;
    }
}