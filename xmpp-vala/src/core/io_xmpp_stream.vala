using Gee;

public interface Xmpp.WriteNodeFunc : Object {
    public abstract async void write_stanza(XmppStream stream, StanzaNode node) throws IOError;
}

public abstract class Xmpp.IoXmppStream : XmppStream {
    private IOStream? stream;
    internal StanzaReader? reader;
    internal StanzaWriter? writer;

    internal WriteNodeFunc? write_obj = null;

    protected IoXmppStream(Jid remote_name) {
        base(remote_name);
    }

    public override async void disconnect() throws IOError {
        disconnected = true;
        if (writer == null || reader == null || stream == null) {
            throw new IOError.CLOSED("trying to disconnect, but no stream open");
        }
        log.str("OUT", "</stream:stream>", this);
        yield writer.write("</stream:stream>");
        reader.cancel();
        yield stream.close_async();
    }

    public void reset_stream(IOStream stream) {
        this.stream = stream;
        reader = new StanzaReader.for_stream(stream.input_stream);
        writer = new StanzaWriter.for_stream(stream.output_stream);

        writer.cancel.connect(reader.cancel);
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
    public override void write(StanzaNode node) {
        write_async.begin(node, (obj, res) => {
            try {
                write_async.end(res);
            } catch (Error e) { }
        });
    }

    public override async void write_async(StanzaNode node) throws IOError {
        if (write_obj != null) {
            yield write_obj.write_stanza(this, node);
        } else {
            StanzaWriter? writer = this.writer;
            if (writer == null) throw new IOError.NOT_CONNECTED("trying to write, but no stream open");
            log.node("OUT", node, this);
            yield ((!)writer).write_node(node);
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
        write(outs);
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