using Gee;

namespace Xmpp {

public errordomain IOStreamError {
    READ,
    WRITE,
    CONNECT,
    DISCONNECT,
    TLS
}

public class XmppStream {
    public const string NS_URI = "http://etherx.jabber.org/streams";

    public Jid remote_name;
    public XmppLog log = new XmppLog();
    public StanzaNode? features { get; private set; default = new StanzaNode.build("features", NS_URI); }

    private IOStream? stream;
    private StanzaReader? reader;
    private StanzaWriter? writer;

    public Gee.List<XmppStreamFlag> flags { get; private set; default=new ArrayList<XmppStreamFlag>(); }
    public Gee.List<XmppStreamModule> modules { get; private set; default=new ArrayList<XmppStreamModule>(); }
    private Gee.List<ServiceLookuper> service_lookupers = new ArrayList<ServiceLookuper>();
    public bool negotiation_complete { get; set; default=false; }
    private bool setup_needed = false;
    private bool non_negotiation_modules_attached = false;

    public signal void received_node(XmppStream stream, StanzaNode node);
    public signal void received_root_node(XmppStream stream, StanzaNode node);
    public signal void received_features_node(XmppStream stream);
    public signal void received_message_stanza(XmppStream stream, StanzaNode node);
    public signal void received_presence_stanza(XmppStream stream, StanzaNode node);
    public signal void received_iq_stanza(XmppStream stream, StanzaNode node);
    public signal void received_nonza(XmppStream stream, StanzaNode node);
    public signal void stream_negotiated(XmppStream stream);
    public signal void attached_modules(XmppStream stream);

    public XmppStream() {
        register_service_lookuper(new StartTlsServiceLookuper());
    }

    public async void connect(string? remote_name = null) throws IOStreamError {
        if (remote_name != null) this.remote_name = Jid.parse(remote_name);
        attach_negotation_modules();
        try {
            GLib.List<ConnectionProvider>? providers = new GLib.List<ConnectionProvider>();
            foreach (ServiceLookuper service_lookuper in service_lookupers) {
                providers.concat(yield service_lookuper.lookup(this.remote_name));
            }
            providers.sort((a, b) => { return a.get_priority() - b.get_priority(); });

            ConnectionProvider? provider = null;
            IOStream? stream = null;
            for (int i = 0; i < providers.length(); i++) {
                provider = providers.nth(i).data;

                stream = yield provider.connect(this);
                if (stream != null) {
                    break;
                }
            }

            if (stream == null) {
                stream = yield (new SocketClient()).connect_async(new NetworkService("xmpp-client", "tcp", this.remote_name.to_string()));
            }
            if (stream == null) {
                throw new IOStreamError.CONNECT("client.connect() returned null");
            }

            reset_stream((!)stream);
        } catch (Error e) {
            debug("[%p] Could not connect to server", this);
            throw new IOStreamError.CONNECT(e.message);
        }
        yield loop();
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

    public async StanzaNode read() throws IOStreamError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = yield ((!)reader).read_node();
            log.node("IN", node);
            return node;
        } catch (XmlError e) {
            throw new IOStreamError.READ(e.message);
        }
    }

    public void write(StanzaNode node) {
        write_async.begin(node);
    }

    public async void write_async(StanzaNode node) throws IOStreamError {
        StanzaWriter? writer = this.writer;
        if (writer == null) throw new IOStreamError.WRITE("trying to write, but no stream open");
        try {
            log.node("OUT", node);
            yield ((!)writer).write_node(node);
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
        foreach (XmppStreamModule m in modules) {
            if (m.get_ns() == module.get_ns() && m.get_id() == module.get_id()) {
                warning("[%p] Adding already added module: %s\n", this, module.get_id());
                return this;
            }
        }
        modules.add(module);
        if (negotiation_complete) module.attach(this);
        return this;
    }

    public void detach_modules() {
        foreach (XmppStreamModule module in modules) {
            if (!(module is XmppStreamNegotiationModule) && !negotiation_complete) continue;
            module.detach(this);
        }
    }

    public T? get_module<T>(ModuleIdentity<T>? identity) {
        if (identity == null) return null;
        foreach (var module in modules) {
            if (((!)identity).matches(module)) return ((!)identity).cast(module);
        }
        return null;
    }

    public void register_service_lookuper(ServiceLookuper service_lookuper) {
        service_lookupers.add(service_lookuper);
    }

    public bool is_negotiation_active() {
        foreach (XmppStreamModule module in modules) {
            if (module is XmppStreamNegotiationModule) {
                XmppStreamNegotiationModule negotiation_module = (XmppStreamNegotiationModule) module;
                if (negotiation_module.negotiation_active(this)) return true;
            }
        }
        return false;
    }

    private async void setup() throws IOStreamError {
        StanzaNode outs = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                            .put_attribute("to", remote_name.to_string())
                            .put_attribute("version", "1.0")
                            .put_attribute("xmlns", "jabber:client")
                            .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI);
        outs.has_nodes = true;
        log.node("OUT ROOT", outs);
        write(outs);
        received_root_node(this, yield read_root());
    }

    private async void loop() throws IOStreamError {
        while (true) {
            if (setup_needed) {
                yield setup();
                setup_needed = false;
            }

            StanzaNode node = yield read();

            Idle.add(loop.callback);
            yield;

            received_node(this, node);

            if (node.ns_uri == NS_URI && node.name == "features") {
                features = node;
                received_features_node(this);
            } else if (node.ns_uri == NS_URI && node.name == "stream" && node.pseudo) {
                debug("[%p] Server closed stream", this);
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

            if (!non_negotiation_modules_attached && negotiation_modules_done()) {
                attach_non_negotation_modules();
                non_negotiation_modules_attached = true;
                if (!negotiation_complete) {
                    stream_negotiated(this);
                    negotiation_complete = true;
                }
            }
        }
    }

    private bool negotiation_modules_done() throws IOStreamError {
        if (setup_needed) return false;
        if (is_negotiation_active()) return false;

        foreach (XmppStreamModule module in modules) {
            if (module is XmppStreamNegotiationModule) {
                XmppStreamNegotiationModule negotiation_module = (XmppStreamNegotiationModule) module;
                if (negotiation_module.mandatory_outstanding(this)) {
                    throw new IOStreamError.CONNECT("mandatory-to-negotiate feature not negotiated: " + negotiation_module.get_id());
                }
            }
        }
        return true;
    }

    private void attach_non_negotation_modules() {
        foreach (XmppStreamModule module in modules) {
            if (module as XmppStreamNegotiationModule == null) {
                module.attach(this);
            }
        }
        attached_modules(this);
    }

    private void attach_negotation_modules() {
        foreach (XmppStreamModule module in modules) {
            if (module as XmppStreamNegotiationModule != null) {
                module.attach(this);
            }
        }
    }

    private async StanzaNode read_root() throws IOStreamError {
        StanzaReader? reader = this.reader;
        if (reader == null) throw new IOStreamError.READ("trying to read, but no stream open");
        try {
            StanzaNode node = yield ((!)reader).read_root_node();
            log.node("IN ROOT", node);
            return node;
        } catch (XmlError.TLS e) {
            throw new IOStreamError.TLS(e.message);
        } catch (Error e) {
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

public abstract class ServiceLookuper {
    public async abstract GLib.List<ConnectionProvider>? lookup(Jid remote_name);
}

public abstract class ConnectionProvider {
    public abstract int? get_priority();
    public abstract string get_id();
    public async abstract IOStream? connect(XmppStream stream);

    protected const uint timeout = 7;
}

public class StartTlsServiceLookuper : ServiceLookuper {
    private GLib.List<SrvTarget>? xmpp_targets;

    public async override GLib.List<ConnectionProvider>? lookup(Jid remote_name) {
        GLib.List<StartTlsConnectionProvider> providers = new GLib.List<StartTlsConnectionProvider>();

        try {
            GLibFixes.Resolver resolver = GLibFixes.Resolver.get_default();
            xmpp_targets = yield resolver.lookup_service_async("xmpp-client", "tcp", remote_name.to_string(), null);
        } catch (Error e) {
            return null;
        }

        SrvTarget? target = null;
        for (int i = 0; i < xmpp_targets.length(); i++) {
            target = xmpp_targets.nth(i).data;
            StartTlsConnectionProvider? provider = new StartTlsConnectionProvider(target.get_hostname(), target.get_port());
            provider.set_priority(target.get_priority());
            providers.append(provider);
        }

        return providers;
    }
}

public class StartTlsConnectionProvider : ConnectionProvider {
    private int priority;
    private string hostname;
    private uint16 port;

    public StartTlsConnectionProvider(string hostname, uint16 port) {
        this.hostname = hostname;
        this.port = port;
    }

    public override int? get_priority() {
        return this.priority;
    }

    public void set_priority(int priority) {
        this.priority = priority;
    }

    public async override IOStream? connect(XmppStream stream) {
        try {
            SocketClient client = new SocketClient();
            client.set_timeout(timeout);
            IOStream? io_stream = yield client.connect_to_host_async(this.hostname, this.port);
            ((SocketConnection)io_stream).get_socket().set_timeout(0); // Back to zero if succeeded
            return io_stream;
        } catch (Error e) {
            return null;
        }
    }

    public override string get_id() { return "start_tls"; }
}

}
