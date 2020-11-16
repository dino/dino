using Gee;

public interface Xmpp.WriteNodeFunc : Object {
    public abstract async void write_stanza(XmppStream stream, StanzaNode node) throws IOStreamError;
}

public abstract class Xmpp.IoXmppStream : XmppStream {
    private IOStream? stream;
    internal StanzaReader? reader;
    internal StanzaWriter? writer;

    internal WriteNodeFunc? write_obj = null;

    public override async void disconnect() throws IOStreamError, XmlError, IOError {
        disconnected = true;
        if (writer == null || reader == null || stream == null) {
            throw new IOStreamError.DISCONNECT("trying to disconnect, but no stream open");
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

    public override async StanzaNode read() throws IOStreamError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = yield ((!)reader).read_node();
            log.node("IN", node, this);
            return node;
        } catch (XmlError e) {
            throw new IOStreamError.READ(e.message);
        }
    }

    [Version (deprecated = true, deprecated_since = "0.1", replacement = "write_async")]
    public override void write(StanzaNode node) {
        write_async.begin(node, (obj, res) => {
            try {
                write_async.end(res);
            } catch (Error e) { }
        });
    }

    public override async void write_async(StanzaNode node) throws IOStreamError {
        if (write_obj != null) {
            yield write_obj.write_stanza(this, node);
        } else {
            StanzaWriter? writer = this.writer;
            if (writer == null) throw new IOStreamError.WRITE("trying to write, but no stream open");
            try {
                log.node("OUT", node, this);
                yield ((!)writer).write_node(node);
            } catch (XmlError e) {
                throw new IOStreamError.WRITE(e.message);
            }
        }
    }

    internal IOStream? get_stream() {
        return stream;
    }

    public override async void setup() throws IOStreamError {
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

    private async StanzaNode read_root() throws IOStreamError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = yield ((!)reader).read_root_node();
            log.node("IN ROOT", node, this);
            return node;
        } catch (XmlError.TLS e) {
            throw new IOStreamError.TLS(e.message);
        } catch (Error e) {
            throw new IOStreamError.READ(e.message);
        }
    }
}