using Gee;

public errordomain Xmpp.IOStreamError {
    READ,
    WRITE,
    CONNECT,
    DISCONNECT,
    TLS
}

public abstract class Xmpp.XmppStream {

    public signal void received_node(XmppStream stream, StanzaNode node);
    public signal void received_root_node(XmppStream stream, StanzaNode node);
    public signal void received_features_node(XmppStream stream);
    public signal void received_message_stanza(XmppStream stream, StanzaNode node);
    public signal void received_presence_stanza(XmppStream stream, StanzaNode node);
    public signal void received_iq_stanza(XmppStream stream, StanzaNode node);
    public signal void received_nonza(XmppStream stream, StanzaNode node);
    public signal void stream_negotiated(XmppStream stream);
    public signal void attached_modules(XmppStream stream);

    public const string NS_URI = "http://etherx.jabber.org/streams";

    public Gee.List<XmppStreamFlag> flags { get; private set; default=new ArrayList<XmppStreamFlag>(); }
    public Gee.List<XmppStreamModule> modules { get; private set; default=new ArrayList<XmppStreamModule>(); }

    public StanzaNode? features { get; private set; default = new StanzaNode.build("features", NS_URI); }
    public Jid remote_name;

    public XmppLog log = new XmppLog();
    public bool negotiation_complete { get; set; default=false; }
    protected bool non_negotiation_modules_attached = false;
    protected bool setup_needed = false;
    protected bool disconnected = false;

    public abstract async void connect() throws IOStreamError;

    public abstract async void disconnect() throws IOStreamError, XmlError, IOError;

    public abstract async StanzaNode read() throws IOStreamError;

    [Version (deprecated = true, deprecated_since = "0.1", replacement = "write_async")]
            public abstract void write(StanzaNode node);

    public abstract async void write_async(StanzaNode node) throws IOStreamError;

    public abstract async void setup() throws IOStreamError;

    public void require_setup() {
        setup_needed = true;
    }

    public bool is_setup_needed() {
        return setup_needed;
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

    public async void loop() throws IOStreamError {
        while (true) {
            if (setup_needed) {
                yield setup();
            }

            StanzaNode node = yield read();

            Idle.add(loop.callback);
            yield;

            if (disconnected) break;

            yield handle_stanza(node);

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

    private async void handle_stanza(StanzaNode node) {
        received_node(this, node);

        if (node.ns_uri == NS_URI && node.name == "features") {
            features = node;
            received_features_node(this);
        } else if (node.ns_uri == NS_URI && node.name == "stream" && node.pseudo) {
            debug("[%p] Server closed stream", this);
            try {
                yield disconnect();
            } catch (Error e) {}
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

    public void attach_negotation_modules() {
        foreach (XmppStreamModule module in modules) {
            if (module as XmppStreamNegotiationModule != null) {
                module.attach(this);
            }
        }
    }
}