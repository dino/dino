using Gee;

namespace Xmpp.Core {

public errordomain IOStreamError {
    READ,
    WRITE,
    CONNECT,
    DISCONNECT

}

public class XmppStream {
    private static string NS_URI = "http://etherx.jabber.org/streams";

    public string remote_name;
    public bool debug = false;
    public StanzaNode? features { get; private set; default = new StanzaNode.build("features", NS_URI); }

    private IOStream? stream;
    private StanzaReader? reader;
    private StanzaWriter? writer;

    private ArrayList<XmppStreamFlag> flags = new ArrayList<XmppStreamFlag>();
    private ArrayList<XmppStreamModule> modules = new ArrayList<XmppStreamModule>();
    private bool setup_needed = false;
    private bool negotiation_complete = false;

    public signal void received_node(XmppStream stream, StanzaNode node);
    public signal void received_root_node(XmppStream stream, StanzaNode node);
    public signal void received_features_node(XmppStream stream);
    public signal void received_message_stanza(XmppStream stream, StanzaNode node);
    public signal void received_presence_stanza(XmppStream stream, StanzaNode node);
    public signal void received_iq_stanza(XmppStream stream, StanzaNode node);
    public signal void received_nonza(XmppStream stream, StanzaNode node);
    public signal void stream_negotiated(XmppStream stream);

    public void connect(string? remote_name = null) throws IOStreamError {
        if (remote_name != null) this.remote_name = remote_name;
        SocketClient client = new SocketClient();
        try {
            SocketConnection? stream = client.connect(new NetworkService("xmpp-client", "tcp", this.remote_name));
            if (stream == null) throw new IOStreamError.CONNECT("client.connect() returned null");
            reset_stream(stream);
        } catch (Error e) {
            stderr.printf("CONNECTION LOST?\n");
            throw new IOStreamError.CONNECT(e.message);
        }
        loop();
    }

    public void disconnect() throws IOStreamError {
        if (writer == null) throw new IOStreamError.DISCONNECT("trying to disconnect, but no stream open");
        if (debug) stderr.puts("OUT\n</stream:stream>\n");
        writer.write.begin("</stream:stream>");
        reader.cancel();
        stream.close_async.begin();
    }

    public void reset_stream(IOStream stream) {
        this.stream = stream;
        reader = new StanzaReader.for_stream(stream.input_stream);
        writer = new StanzaWriter.for_stream(stream.output_stream);
        require_setup();
    }

    public void require_setup() {
        setup_needed = true;
    }

    public bool is_setup_needed() {
        return setup_needed;
    }

    public StanzaNode read() throws IOStreamError {
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            var node = reader.read_node();
            if (debug) stderr.printf("IN\n%s\n", node.to_string());
            return node;
        } catch (XmlError e) {
            throw new IOStreamError.READ(e.message);
        }
    }

    public void write(StanzaNode node) throws IOStreamError {
        if (writer == null) throw new IOStreamError.WRITE("trying to write, but no stream open");
        try {
            if (debug) stderr.printf("OUT\n%s\n", node.to_string());
            writer.write_node(node);
        } catch (XmlError e) {
            throw new IOStreamError.WRITE(e.message);
        }
    }

    internal IOStream? get_stream() {
        return stream;
    }

    public void add_flag(XmppStreamFlag flag) {
        flags.add(flag);
    }

    public bool has_flag<T>(FlagIdentity<T>? identity) {
        return get_flag(identity) != null;
    }

    public T? get_flag<T>(FlagIdentity<T>? identity) {
        if (identity == null) return null;
        foreach (var flag in flags) {
            if (identity.matches(flag)) return identity.cast(flag);
        }
        return null;
    }

    public void remove_flag(XmppStreamFlag flag) {
        flags.remove(flag);
    }

    public XmppStream add_module(XmppStreamModule module) {
        modules.add(module);
        if (negotiation_complete || module as XmppStreamNegotiationModule != null) {
            module.attach(this);
        }
        return this;
    }

    public void remove_modules() {
        foreach (XmppStreamModule module in modules) module.detach(this);
    }

    public T? get_module<T>(ModuleIdentity<T>? identity) {
        if (identity == null) return null;
        foreach (var module in modules) {
            if (identity.matches(module)) return identity.cast(module);
        }
        return null;
    }

    private void setup() throws IOStreamError {
        var outs = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                            .put_attribute("to", remote_name)
                            .put_attribute("version", "1.0")
                            .put_attribute("xmlns", "jabber:client")
                            .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI);
        outs.has_nodes = true;
        write(outs);
        received_root_node(this, read_root());
    }

    private void loop() throws IOStreamError {
        while(true) {
            if (setup_needed) {
                setup();
                setup_needed = false;
            }

            StanzaNode node = read();
            received_node(this, node);

            if (node.ns_uri == NS_URI && node.name == "features") {
                features = node;
                received_features_node(this);
            } else if (node.ns_uri == NS_URI && node.name == "stream" && node.pseudo) {
                print("disconnect\n");
                disconnect();
                return;
            } else if (node.ns_uri == JABBER_URI) {
                if (node.name == "message") {
                    received_message_stanza(this, node);
                } else if (node.name == "presence") {
                    received_presence_stanza(this, node);
                } else if (node.name == "iq") {
                    received_iq_stanza(this, node);
                } else {
                    received_nonza(this, node);
                }
            } else {
                received_nonza(this, node);
            }

            if (!negotiation_complete && negotiation_modules_done()) {
                negotiation_complete = true;
                attach_non_negotation_modules();
                stream_negotiated(this);
            }
        }
    }

    private bool negotiation_modules_done() throws IOStreamError {
        if (!setup_needed) {
            bool mandatory_outstanding = false;
            bool negotiation_active = false;
            foreach (XmppStreamModule module in modules) {
                XmppStreamNegotiationModule negotiation_module = module as XmppStreamNegotiationModule;
                if (negotiation_module != null) {
                    if (negotiation_module.negotiation_active(this)) negotiation_active = true;
                    if (negotiation_module.mandatory_outstanding(this)) mandatory_outstanding = true;
                }
            }
            if (!negotiation_active) {
                if (mandatory_outstanding) {
                    throw new IOStreamError.CONNECT("mandatory-to-negotiate feature not negotiated");
                } else {
                    return true;
                }
            }
        }
        return false;
    }

    private void attach_non_negotation_modules() {
        foreach (XmppStreamModule module in modules) {
            if (module as XmppStreamNegotiationModule == null) {
                module.attach(this);
            }
        }
    }

    private StanzaNode read_root() throws IOStreamError {
        try {
            var node = reader.read_root_node();
            if (debug) stderr.printf("IN\n%s\n", node.to_string());
            return node;
        } catch (XmlError e) {
            throw new IOStreamError.READ(e.message);
        }
    }
}

public class FlagIdentity<T> : Object {
    public string ns { get; private set; }
    public string id { get; private set; }

    public FlagIdentity(string ns, string id) {
        this.ns = ns;
        this.id = id;
    }

    public T? cast(XmppStreamFlag flag) {
        return flag.get_type().is_a(typeof(T)) ? (T?) flag : null;
    }

    public bool matches(XmppStreamFlag module) {
        return module.get_ns() == ns && module.get_id() == id;
    }
}

public abstract class XmppStreamFlag : Object {
    public abstract string get_ns();
    public abstract string get_id();
}

public class ModuleIdentity<T> : Object {
    public string ns { get; private set; }
    public string id { get; private set; }

    public ModuleIdentity(string ns, string id) {
        this.ns = ns;
        this.id = id;
    }

    public T? cast(XmppStreamModule module) {
        return module.get_type().is_a(typeof(T)) ? (T?) module : null;
    }

    public bool matches(XmppStreamModule module) {
        return module.get_ns() == ns && module.get_id() == id;
    }
}

public abstract class XmppStreamModule : Object {
    public abstract void attach(XmppStream stream);
    public abstract void detach(XmppStream stream);
    public abstract string get_ns();
    public abstract string get_id();
}

public abstract class XmppStreamNegotiationModule : XmppStreamModule {
    public abstract bool mandatory_outstanding(XmppStream stream);
    public abstract bool negotiation_active(XmppStream stream);
}
}
