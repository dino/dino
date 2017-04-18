using Gee;

namespace Xmpp.Core {

public errordomain IOStreamError {
    READ,
    WRITE,
    CONNECT,
    DISCONNECT

}

public class XmppLog {
    protected const string ANSI_COLOR_END = "\x1b[0m";
    protected const string ANSI_COLOR_WHITE = "\x1b[37;1m";

    class NodeLogDesc {
        public string? name;
        private string? ns_uri;
        private string? val;
        private Map<string, string?> attrs = new HashMap<string, string?>();
        private NodeLogDesc? inner;

        public NodeLogDesc(string desc) {
            string d = desc;

            if (d.contains("[")) {
                int start = d.index_of("[");
                int end = d.index_of("]");
                string attrs = d.substring(start + 1, end - start - 1);
                d = d.substring(0, start) + d.substring(end + 1);
                foreach (string attr in attrs.split(",")) {
                    if (attr.contains("=")) {
                        string key = attr.substring(0, attr.index_of("="));
                        string val = attr.substring(attr.index_of("=") + 1);
                        this.attrs[key] = val;
                    } else {
                        this.attrs[attr] = null;
                    }
                }
            }
            if (d.contains(":") && d.index_of("{") == 0 && d.index_of("}") != -1) {
                int end = d.index_of("}");
                this.ns_uri = d.substring(1, end - 2);
                d = d.substring(end + 2);
            }
            if (d.contains(".")) {
                inner = new NodeLogDesc(d.substring(d.index_of(".") + 1));
                d = d.substring(0, d.index_of("."));
            } else if (d.contains("=")) {
                this.val = d.substring(d.index_of("="));
                d = d.substring(0, d.index_of("="));
            }

            if (d != "") this.name = d;
        }

        public bool matches(StanzaNode node) {
            if (name != null && node.name != name) return false;
            if (ns_uri != null && node.ns_uri != ns_uri) return false;
            if (val != null && node.val != val) return false;
            foreach (var pair in attrs.entries) {
                if (pair.value == null && node.get_attribute(pair.key) == null) return false;
                else if (pair.value != null && pair.value != node.get_attribute(pair.key)) return false;
            }
            if (inner == null) return true;
            foreach (StanzaNode snode in node.get_all_subnodes()) {
                if (((!)inner).matches(snode)) return true;
            }
            return false;
        }
    }

    private bool use_ansi;
    private bool hide_ns = true;
    private string ident;
    private string desc;
    private ArrayList<NodeLogDesc> descs = new ArrayList<NodeLogDesc>();

    public XmppLog(string? ident = null, string? desc = null) {
        this.ident = ident ?? "";
        this.desc = desc ?? "";
        this.use_ansi = is_atty(stderr.fileno());
        while (this.desc.contains(";")) {
            string opt = this.desc.substring(0, this.desc.index_of(";"));
            this.desc = this.desc.substring(opt.length + 1);
            switch (opt) {
                case "ansi": use_ansi = true; break;
                case "no-ansi": use_ansi = false; break;
                case "hide-ns": hide_ns = true; break;
                case "show-ns": hide_ns = false; break;
            }
        }
        if (desc != "") {
            foreach (string d in this.desc.split("|")) {
                descs.add(new NodeLogDesc(d));
            }
        }
    }

    public virtual bool should_log_node(StanzaNode node) {
        if (ident == "" || desc == "") return false;
        if (desc == "all") return true;
        foreach (var desc in descs) {
            if (desc.matches(node)) return true;
        }
        return false;
    }

    public virtual bool should_log_str(string str) {
        if (ident == "" || desc == "") return false;
        if (desc == "all") return true;
        foreach (var desc in descs) {
            if (desc.name == "#text") return true;
        }
        return false;
    }

    public void node(string what, StanzaNode node) {
        if (should_log_node(node)) {
            stderr.printf("%sXMPP %s [%s]%s\n%s\n", ANSI_COLOR_WHITE, what, ident, ANSI_COLOR_END, use_ansi ? node.to_ansi_string(hide_ns) : node.to_string());
        }
    }

    public void str(string what, string str) {
        if (should_log_str(str)) {
            stderr.printf("%sXMPP %s [%s]%s\n%s\n", ANSI_COLOR_WHITE, what, ident, ANSI_COLOR_END, str);
        }
    }

    [CCode (cname = "isatty")]
    private static extern bool is_atty(int fd);
}

public class XmppStream {
    private static string NS_URI = "http://etherx.jabber.org/streams";

    public string remote_name;
    public XmppLog log = new XmppLog();
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
        if (remote_name != null) this.remote_name = (!)remote_name;
        SocketClient client = new SocketClient();
        try {
            SocketConnection? stream = client.connect(new NetworkService("xmpp-client", "tcp", this.remote_name));
            if (stream == null) throw new IOStreamError.CONNECT("client.connect() returned null");
            reset_stream((!)stream);
        } catch (Error e) {
            stderr.printf("CONNECTION LOST?\n");
            throw new IOStreamError.CONNECT(e.message);
        }
        loop();
    }

    public void disconnect() throws IOStreamError {
        StanzaWriter? writer = this.writer;
        StanzaReader? reader = this.reader;
        IOStream? stream = this.stream;
        if (writer == null || reader == null || stream == null) throw new IOStreamError.DISCONNECT("trying to disconnect, but no stream open");
        log.str("OUT", "</stream:stream>");
        ((!)writer).write.begin("</stream:stream>");
        ((!)reader).cancel();
        ((!)stream).close_async.begin();
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
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = ((!)reader).read_node();
            log.node("IN", node);
            return node;
        } catch (XmlError e) {
            throw new IOStreamError.READ(e.message);
        }
    }

    public void write(StanzaNode node) throws IOStreamError {
        StanzaWriter? writer = this.writer;
        if (writer == null) throw new IOStreamError.WRITE("trying to write, but no stream open");
        try {
            log.node("OUT", node);
            ((!)writer).write_node(node);
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
            if (((!)identity).matches(flag)) return ((!)identity).cast(flag);
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
            if (((!)identity).matches(module)) return ((!)identity).cast(module);
        }
        return null;
    }

    private void setup() throws IOStreamError {
        StanzaNode outs = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                            .put_attribute("to", remote_name)
                            .put_attribute("version", "1.0")
                            .put_attribute("xmlns", "jabber:client")
                            .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI);
        outs.has_nodes = true;
        log.node("OUT ROOT", outs);
        write(outs);
        received_root_node(this, read_root());
    }

    private void loop() throws IOStreamError {
        while (true) {
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
                XmppStreamNegotiationModule? negotiation_module = module as XmppStreamNegotiationModule;
                if (negotiation_module != null) {
                    if (((!)negotiation_module).negotiation_active(this)) negotiation_active = true;
                    if (((!)negotiation_module).mandatory_outstanding(this)) mandatory_outstanding = true;
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
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = ((!)reader).read_root_node();
            log.node("IN ROOT", node);
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
