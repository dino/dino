using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

private const string NS_URI = "urn:xmpp:jingle:1";
private const string ERROR_NS_URI = "urn:xmpp:jingle:errors:1";

public errordomain IqError {
    BAD_REQUEST,
    NOT_ACCEPTABLE,
    NOT_IMPLEMENTED,
    OUT_OF_ORDER,
}

void send_iq_error(IqError iq_error, XmppStream stream, Iq.Stanza iq) {
    ErrorStanza error;
    if (iq_error is IqError.BAD_REQUEST) {
        error = new ErrorStanza.bad_request(iq_error.message);
    } else if (iq_error is IqError.NOT_ACCEPTABLE) {
        error = new ErrorStanza.not_acceptable(iq_error.message);
    } else if (iq_error is IqError.NOT_IMPLEMENTED) {
        error = new ErrorStanza.feature_not_implemented(iq_error.message);
    } else if (iq_error is IqError.OUT_OF_ORDER) {
        StanzaNode out_of_order = new StanzaNode.build("out-of-order", ERROR_NS_URI).add_self_xmlns();
        error = new ErrorStanza.build(ErrorStanza.TYPE_MODIFY, ErrorStanza.CONDITION_UNEXPECTED_REQUEST, iq_error.message, out_of_order);
    } else {
        assert_not_reached();
    }
    stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, error));
}

public errordomain Error {
    GENERAL,
    BAD_REQUEST,
    INVALID_PARAMETERS,
    UNSUPPORTED_TRANSPORT,
    NO_SHARED_PROTOCOLS,
    TRANSPORT_ERROR,
}

StanzaNode get_single_node_anyns(StanzaNode parent, string node_name) throws IqError {
    StanzaNode? result = null;
    foreach (StanzaNode child in parent.get_all_subnodes()) {
        if (child.name == node_name) {
            if (result != null) {
                throw new IqError.BAD_REQUEST(@"multiple $(node_name) nodes");
            }
            result = child;
        }
    }
    if (result == null) {
        throw new IqError.BAD_REQUEST(@"missing $(node_name) node");
    }
    return result;
}

public class Module : XmppStreamModule, Iq.Handler {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0166_jingle");

    private HashMap<string, ContentType> content_types = new HashMap<string, ContentType>();
    private HashMap<string, Transport> transports = new HashMap<string, Transport>();

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
    }
    public override void detach(XmppStream stream) { }

    public void register_content_type(ContentType content_type) {
        content_types[content_type.content_type_ns_uri()] = content_type;
    }
    public ContentType? get_content_type(string ns_uri) {
        if (!content_types.has_key(ns_uri)) {
            return null;
        }
        return content_types[ns_uri];
    }
    public void register_transport(Transport transport) {
        transports[transport.transport_ns_uri()] = transport;
    }
    public Transport? get_transport(string ns_uri) {
        if (!transports.has_key(ns_uri)) {
            return null;
        }
        return transports[ns_uri];
    }
    public Transport? select_transport(XmppStream stream, TransportType type, Jid receiver_full_jid) {
        foreach (Transport transport in transports.values) {
            if (transport.transport_type() != type) {
                continue;
            }
            // TODO(hrxi): prioritization
            if (transport.is_transport_available(stream, receiver_full_jid)) {
                return transport;
            }
        }
        return null;
    }

    private bool is_jingle_available(XmppStream stream, Jid full_jid) {
        bool? has_jingle = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        return has_jingle != null && has_jingle;
    }

    public bool is_available(XmppStream stream, TransportType type, Jid full_jid) {
        return is_jingle_available(stream, full_jid) && select_transport(stream, type, full_jid) != null;
    }

    public Session create_session(XmppStream stream, TransportType type, Jid receiver_full_jid, Senders senders, string content_name, StanzaNode description) throws Error {
        if (!is_jingle_available(stream, receiver_full_jid)) {
            throw new Error.NO_SHARED_PROTOCOLS("No Jingle support");
        }
        Transport? transport = select_transport(stream, type, receiver_full_jid);
        if (transport == null) {
            throw new Error.NO_SHARED_PROTOCOLS("No suitable transports");
        }
        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
        if (my_jid == null) {
            throw new Error.GENERAL("Couldn't determine own JID");
        }
        TransportParameters transport_params = transport.create_transport_parameters();
        Session session = new Session.initiate_sent(random_uuid(), type, transport_params, receiver_full_jid, content_name, stream);
        StanzaNode content = new StanzaNode.build("content", NS_URI)
            .put_attribute("creator", "initiator")
            .put_attribute("name", content_name)
            .put_attribute("senders", senders.to_string())
            .put_node(description)
            .put_node(transport_params.to_transport_stanza_node());
        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-initiate")
            .put_attribute("initiator", my_jid.to_string())
            .put_attribute("sid", session.sid)
            .put_node(content);
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=receiver_full_jid };

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            // TODO(hrxi): handle errors
            stream.get_flag(Flag.IDENTITY).add_session(session);
        });

        return session;
    }

    public void handle_session_initiate(XmppStream stream, string sid, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        Gee.List<StanzaNode> contents = jingle.get_subnodes("content");
        if (contents.size == 0) {
            throw new IqError.BAD_REQUEST("missing content node");
        }
        if (contents.size > 1) {
            throw new IqError.NOT_IMPLEMENTED("can't process multiple content nodes");
        }
        StanzaNode content = contents[0];
        string? name = content.get_attribute("name");
        StanzaNode description = get_single_node_anyns(content, "description");
        StanzaNode transport_node = get_single_node_anyns(content, "transport");
        if (name == null) {
            throw new IqError.BAD_REQUEST("missing name");
        }

        Transport? transport = get_transport(transport_node.ns_uri);
        TransportParameters? transport_params = null;
        if (transport != null) {
            transport_params = transport.parse_transport_parameters(transport_node);
        } else {
            // terminate the session below
        }

        ContentType? content_type = get_content_type(description.ns_uri);
        if (content_type == null) {
            // TODO(hrxi): how do we signal an unknown content type?
            throw new IqError.NOT_IMPLEMENTED("unknown content type");
        }
        ContentParameters content_params = content_type.parse_content_parameters(description);

        TransportType type = content_type.content_type_transport_type();
        Session session = new Session.initiate_received(sid, type, transport_params, iq.from, name, stream);
        stream.get_flag(Flag.IDENTITY).add_session(session);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));

        if (transport == null || transport.transport_type() != type) {
            StanzaNode reason = new StanzaNode.build("reason", NS_URI)
                .put_node(new StanzaNode.build("unsupported-transports", NS_URI));
            session.terminate(stream, reason, "unsupported transports");
            return;
        }

        content_params.on_session_initiate(stream, session);
    }

    public void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        try {
            handle_iq_set(stream, iq);
        } catch (IqError e) {
            send_iq_error(e, stream, iq);
        }
    }

    public void handle_iq_set(XmppStream stream, Iq.Stanza iq) throws IqError {
        StanzaNode? jingle = iq.stanza.get_subnode("jingle", NS_URI);
        string? sid = jingle != null ? jingle.get_attribute("sid") : null;
        string? action = jingle != null ? jingle.get_attribute("action") : null;
        if (jingle == null || sid == null || action == null) {
            throw new IqError.BAD_REQUEST("missing jingle node, sid or action");
        }
        Session? session = stream.get_flag(Flag.IDENTITY).get_session(sid);
        if (action == "session-initiate") {
            if (session != null) {
                // TODO(hrxi): Info leak if other clients use predictable session IDs?
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.build(ErrorStanza.TYPE_MODIFY, ErrorStanza.CONDITION_CONFLICT, "session ID already in use", null)));
                return;
            }
            handle_session_initiate(stream, sid, jingle, iq);
            return;
        }
        if (session == null) {
            StanzaNode unknown_session = new StanzaNode.build("unknown-session", ERROR_NS_URI).add_self_xmlns();
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.item_not_found(unknown_session)));
            return;
        }
        session.handle_iq_set(stream, action, jingle, iq);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public enum TransportType {
    DATAGRAM,
    STREAMING,
}

public enum Senders {
    BOTH,
    INITIATOR,
    NONE,
    RESPONDER;

    public string to_string() {
        switch (this) {
            case BOTH: return "both";
            case INITIATOR: return "initiator";
            case NONE: return "none";
            case RESPONDER: return "responder";
        }
        assert_not_reached();
    }
}

public interface Transport : Object {
    public abstract string transport_ns_uri();
    public abstract bool is_transport_available(XmppStream stream, Jid full_jid);
    public abstract TransportType transport_type();
    public abstract TransportParameters create_transport_parameters();
    public abstract TransportParameters parse_transport_parameters(StanzaNode transport) throws IqError;
}

public interface TransportParameters : Object {
    public abstract string transport_ns_uri();
    public abstract StanzaNode to_transport_stanza_node();
    public abstract void update_transport(StanzaNode transport) throws IqError;
    public abstract IOStream create_transport_connection(XmppStream stream, Jid peer_full_jid, Role role);
}

public enum Role {
    INITIATOR,
    RESPONDER;

    public string to_string() {
        switch (this) {
            case INITIATOR: return "initiator";
            case RESPONDER: return "responder";
        }
        assert_not_reached();
    }
}

public interface ContentType : Object {
    public abstract string content_type_ns_uri();
    public abstract TransportType content_type_transport_type();
    public abstract ContentParameters parse_content_parameters(StanzaNode description) throws IqError;
}

public interface ContentParameters : Object {
    public abstract void on_session_initiate(XmppStream stream, Session session);
}


public class Session {
    // INITIATE_SENT -> ACTIVE -> ENDED
    // INITIATE_RECEIVED -> ACTIVE -> ENDED
    public enum State {
        INITIATE_SENT,
        INITIATE_RECEIVED,
        ACTIVE,
        ENDED,
    }

    public State state { get; private set; }

    public string sid { get; private set; }
    public Type type_ { get; private set; }
    public Jid peer_full_jid { get; private set; }
    public string content_name { get; private set; }

    // INITIATE_SENT | INITIATE_RECEIVED
    TransportParameters? transport = null;

    // ACTIVE
    private Connection? connection;
    public IOStream? conn { get { return connection; } }

    // Only interesting in INITIATE_SENT.
    // Signals that the session has been accepted by the peer.
    public signal void accepted(XmppStream stream);

    XmppStream hack;

    public Session.initiate_sent(string sid, Type type, TransportParameters transport, Jid peer_full_jid, string content_name, XmppStream hack) {
        this.state = State.INITIATE_SENT;
        this.sid = sid;
        this.type_ = type;
        this.peer_full_jid = peer_full_jid;
        this.content_name = content_name;
        this.transport = transport;
        this.connection = new Connection(this);
        this.hack = hack;
    }

    public Session.initiate_received(string sid, Type type, TransportParameters? transport, Jid peer_full_jid, string content_name, XmppStream hack) {
        this.state = State.INITIATE_RECEIVED;
        this.sid = sid;
        this.type_ = type;
        this.peer_full_jid = peer_full_jid;
        this.content_name = content_name;
        this.transport = transport;
        this.connection = new Connection(this);
        this.hack = hack;
    }

    public void handle_iq_set(XmppStream stream, string action, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        switch (action) {
            case "session-accept":
                if (state != State.INITIATE_SENT) {
                    throw new IqError.OUT_OF_ORDER("got session-accept while not waiting for one");
                }
                handle_session_accept(stream, jingle, iq);
                break;
            case "session-terminate":
                handle_session_terminate(stream, jingle, iq);
                break;
            case "content-accept":
            case "content-add":
            case "content-modify":
            case "content-reject":
            case "content-remove":
            case "security-info":
            case "transport-accept":
            case "transport-info":
            case "transport-reject":
            case "transport-replace":
                throw new IqError.NOT_IMPLEMENTED(@"$(action) is not implemented");
            default:
                throw new IqError.BAD_REQUEST("invalid action");
        }
    }
    void handle_session_accept(XmppStream stream, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        string? responder_str = jingle.get_attribute("responder");
        Jid responder;
        if (responder_str != null) {
            responder = Jid.parse(responder_str) ?? iq.from;
        } else {
            responder = iq.from; // TODO(hrxi): and above, can we assume iq.from != null
            // TODO(hrxi): more sanity checking, perhaps replace who we're talking to
        }
        if (!responder.is_full()) {
            throw new IqError.BAD_REQUEST("invalid responder JID");
        }
        Gee.List<StanzaNode> contents = jingle.get_subnodes("content");
        if (contents.size == 0) {
            // TODO(hrxi): here and below, should we terminate the session?
            throw new IqError.BAD_REQUEST("missing content node");
        }
        if (contents.size > 1) {
            throw new IqError.NOT_IMPLEMENTED("can't process multiple content nodes");
        }
        StanzaNode content = contents[0];
        StanzaNode description = get_single_node_anyns(content, "description");
        StanzaNode transport_node = get_single_node_anyns(content, "transport");
        if (transport_node.ns_uri != transport.transport_ns_uri()) {
            throw new IqError.BAD_REQUEST("session-accept with unnegotiated transport method");
        }
        transport.update_transport(transport_node);
        connection.set_inner(transport.create_transport_connection(stream, peer_full_jid, Role.INITIATOR));
        transport = null;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        state = State.ACTIVE;
        accepted(stream);
    }
    void handle_session_terminate(XmppStream stream, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        connection.on_terminated_by_jingle("remote terminated jingle session");
        state = ENDED;
        stream.get_flag(Flag.IDENTITY).remove_session(sid);

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        // TODO(hrxi): also handle presence type=unavailable
    }

    public void accept(XmppStream stream, StanzaNode description) {
        if (state != State.INITIATE_RECEIVED) {
            return; // TODO(hrxi): what to do?
        }
        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-accept")
            .put_attribute("sid", sid)
            .put_node(new StanzaNode.build("content", NS_URI)
                .put_attribute("creator", "initiator")
                .put_attribute("name", content_name)
                .put_node(description)
                .put_node(transport.to_transport_stanza_node())
            );
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);

        connection.set_inner(transport.create_transport_connection(stream, peer_full_jid, Role.RESPONDER));
        transport = null;

        state = State.ACTIVE;
    }

    public void reject(XmppStream stream) {
        if (state != State.INITIATE_RECEIVED) {
            return; // TODO(hrxi): what to do?
        }
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("decline", NS_URI));
        terminate(stream, reason, "declined");
    }

    public void set_application_error(XmppStream stream, StanzaNode? application_reason = null) {
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("failed-application", NS_URI));
        if (application_reason != null) {
            reason.put_node(application_reason);
        }
        terminate(stream, reason, "application error");
    }

    public void on_connection_error(IOError error) {
        // TODO(hrxi): where can we get an XmppStream from?
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("failed-transport", NS_URI))
            .put_node(new StanzaNode.build("text", NS_URI)
                .put_node(new StanzaNode.text(error.message))
            );
        terminate(hack, reason, "transport error: $(error.message)");
    }
    public void on_connection_close() {
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("success", NS_URI));
        terminate(hack, reason, "success");
    }

    public void terminate(XmppStream stream, StanzaNode reason, string? local_reason) {
        if (state == State.ENDED) {
            return;
        }
        if (state == State.ACTIVE) {
            if (local_reason != null) {
                connection.on_terminated_by_jingle(@"local session-terminate: $(local_reason)");
            } else {
                connection.on_terminated_by_jingle("local session-terminate");
            }
        }

        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-terminate")
            .put_attribute("sid", sid)
            .put_node(reason);
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);

        state = State.ENDED;
        // Immediately remove the session from the open sessions as per the
        // XEP, don't wait for confirmation.
        stream.get_flag(Flag.IDENTITY).remove_session(sid);
    }
}

public class Connection : IOStream {
    public class Input : InputStream {
        private weak Connection connection;
        public Input(Connection connection) {
            this.connection = connection;
        }
        public override ssize_t read(uint8[] buffer, Cancellable? cancellable = null) throws IOError {
            throw new IOError.NOT_SUPPORTED("can't do non-async reads on jingle connections");
        }
        public override async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.read_async(buffer, io_priority, cancellable);
        }
        public override bool close(Cancellable? cancellable = null) throws IOError {
            return connection.close_read(cancellable);
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
            throw new IOError.NOT_SUPPORTED("can't do non-async writes on jingle connections");
        }
        public override async ssize_t write_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.write_async(buffer, io_priority, cancellable);
        }
        public override bool close(Cancellable? cancellable = null) throws IOError {
            return connection.close_write(cancellable);
        }
        public override async bool close_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield connection.close_write_async(io_priority, cancellable);
        }
    }

    private Input input;
    private Output output;
    public override InputStream input_stream { get { return input; } }
    public override OutputStream output_stream { get { return output; } }

    private weak Session session;
    private IOStream? inner = null;
    private string? error = null;

    private bool read_closed = false;
    private bool write_closed = false;

    private class OnSetInnerCallback {
        public SourceFunc callback;
        public int io_priority;
    }

    Gee.List<OnSetInnerCallback> callbacks = new ArrayList<OnSetInnerCallback>();

    public Connection(Session session) {
        this.input = new Input(this);
        this.output = new Output(this);
        this.session = session;
    }

    public void set_inner(IOStream inner) {
        assert(this.inner == null);
        this.inner = inner;
        foreach (OnSetInnerCallback c in callbacks) {
            Idle.add((owned) c.callback, c.io_priority);
        }
        callbacks = null;
    }

    public void on_terminated_by_jingle(string reason) {
        if (error == null) {
            close_async.begin();
            error = reason;
        }
    }

    private void check_for_errors() throws IOError {
        if (error != null) {
            throw new IOError.CLOSED(error);
        }
    }
    private async void wait_and_check_for_errors(int io_priority, Cancellable? cancellable = null) throws IOError {
        while (true) {
            check_for_errors();
            if (inner != null) {
                return;
            }
            SourceFunc callback = wait_and_check_for_errors.callback;
            ulong id = cancellable.connect(() => callback());
            callbacks.add(new OnSetInnerCallback() { callback=(owned)callback, io_priority=io_priority});
            yield;
            cancellable.disconnect(id);
        }
    }
    private void handle_connection_error(IOError error) {
        Session? strong = session;
        if (strong != null) {
            strong.on_connection_error(error);
        }
    }
    private void handle_connection_close() {
        Session? strong = session;
        if (strong != null) {
            strong.on_connection_close();
        }
    }

    public async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield wait_and_check_for_errors(io_priority, cancellable);
        try {
            return yield inner.input_stream.read_async(buffer, io_priority, cancellable);
        } catch (IOError e) {
            print("read_async error\n");
            handle_connection_error(e);
            throw e;
        }
    }
    public async ssize_t write_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield wait_and_check_for_errors(io_priority, cancellable);
        try {
            return yield inner.output_stream.write_async(buffer, io_priority, cancellable);
        } catch (IOError e) {
            print("write_async error\n");
            handle_connection_error(e);
            throw e;
        }
    }
    public bool close_read(Cancellable? cancellable = null) throws IOError {
        check_for_errors();
        if (read_closed) {
            return true;
        }
        close_read_async.begin(GLib.Priority.DEFAULT, cancellable);
        return true;
    }
    public async bool close_read_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield wait_and_check_for_errors(io_priority, cancellable);
        if (read_closed) {
            return true;
        }
        read_closed = true;
        IOError error = null;
        bool result = true;
        try {
            result = yield inner.input_stream.close_async(io_priority, cancellable);
        } catch (IOError e) {
            print("input_stream.close_async error\n");
            if (error == null) {
                error = e;
            }
        }
        try {
            result = (yield close_if_both_closed(io_priority, cancellable)) && result;
        } catch (IOError e) {
            print("close_if_both_closed error\n");
            if (error == null) {
                error = e;
            }
        }
        if (error != null) {
            handle_connection_error(error);
            throw error;
        }
        return result;
    }
    public bool close_write(Cancellable? cancellable = null) throws IOError {
        check_for_errors();
        if (write_closed) {
            return true;
        }
        close_write_async.begin(GLib.Priority.DEFAULT, cancellable);
        return true;
    }
    public async bool close_write_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield wait_and_check_for_errors(io_priority, cancellable);
        if (write_closed) {
            return true;
        }
        write_closed = true;
        IOError error = null;
        bool result = true;
        try {
            result = yield inner.output_stream.close_async(io_priority, cancellable);
        } catch (IOError e) {
            print("output_stream.close_async error\n");
            if (error == null) {
                error = e;
            }
        }
        try {
            result = (yield close_if_both_closed(io_priority, cancellable)) && result;
        } catch (IOError e) {
            print("close_if_both_closed error\n");
            if (error == null) {
                error = e;
            }
        }
        if (error != null) {
            handle_connection_error(error);
            throw error;
        }
        return result;
    }
    private async bool close_if_both_closed(int io_priority, Cancellable? cancellable = null) throws IOError {
        if (read_closed && write_closed) {
            handle_connection_close();
            //return yield inner.close_async(io_priority, cancellable);
        }
        return true;
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "jingle");

    private HashMap<string, Session> sessions = new HashMap<string, Session>();

    public void add_session(Session session) {
        sessions[session.sid] = session;
    }
    public Session? get_session(string sid) {
        return sessions.has_key(sid) ? sessions[sid] : null;
    }
    public void remove_session(string sid) {
        sessions.unset(sid);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
