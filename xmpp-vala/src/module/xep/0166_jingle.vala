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
    UNSUPPORTED_INFO,
    OUT_OF_ORDER,
    RESOURCE_CONSTRAINT,
}

void send_iq_error(IqError iq_error, XmppStream stream, Iq.Stanza iq) {
    ErrorStanza error;
    if (iq_error is IqError.BAD_REQUEST) {
        error = new ErrorStanza.bad_request(iq_error.message);
    } else if (iq_error is IqError.NOT_ACCEPTABLE) {
        error = new ErrorStanza.not_acceptable(iq_error.message);
    } else if (iq_error is IqError.NOT_IMPLEMENTED) {
        error = new ErrorStanza.feature_not_implemented(iq_error.message);
    } else if (iq_error is IqError.UNSUPPORTED_INFO) {
        StanzaNode unsupported_info = new StanzaNode.build("unsupported-info", ERROR_NS_URI).add_self_xmlns();
        error = new ErrorStanza.build(ErrorStanza.TYPE_CANCEL, ErrorStanza.CONDITION_FEATURE_NOT_IMPLEMENTED, iq_error.message, unsupported_info);
    } else if (iq_error is IqError.OUT_OF_ORDER) {
        StanzaNode out_of_order = new StanzaNode.build("out-of-order", ERROR_NS_URI).add_self_xmlns();
        error = new ErrorStanza.build(ErrorStanza.TYPE_MODIFY, ErrorStanza.CONDITION_UNEXPECTED_REQUEST, iq_error.message, out_of_order);
    } else if (iq_error is IqError.RESOURCE_CONSTRAINT) {
        error = new ErrorStanza.resource_constraint(iq_error.message);
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

StanzaNode? get_single_node_anyns(StanzaNode parent, string node_name) throws IqError {
    StanzaNode? result = null;
    foreach (StanzaNode child in parent.get_all_subnodes()) {
        if (child.name == node_name) {
            if (result != null) {
                throw new IqError.BAD_REQUEST(@"multiple $(node_name) nodes");
            }
            result = child;
        }
    }
    return result;
}

class ContentNode {
    public Role creator;
    public string name;
    public StanzaNode? description;
    public StanzaNode? transport;
}

ContentNode get_single_content_node(StanzaNode jingle) throws IqError {
    Gee.List<StanzaNode> contents = jingle.get_subnodes("content");
    if (contents.size == 0) {
        throw new IqError.BAD_REQUEST("missing content node");
    }
    if (contents.size > 1) {
        throw new IqError.NOT_IMPLEMENTED("can't process multiple content nodes");
    }
    StanzaNode content = contents[0];
    string? creator_str = content.get_attribute("creator");
    // Vala can't typecheck the ternary operator here.
    Role? creator = null;
    if (creator_str != null) {
        creator = Role.parse(creator_str);
    } else {
        // TODO(hrxi): now, is the creator attribute optional or not (XEP-0166
        // Jingle)?
        creator = Role.INITIATOR;
    }

    string? name = content.get_attribute("name");
    StanzaNode? description = get_single_node_anyns(content, "description");
    StanzaNode? transport = get_single_node_anyns(content, "transport");
    if (name == null || creator == null) {
        throw new IqError.BAD_REQUEST("missing name or creator");
    }

    return new ContentNode() {
        creator=creator,
        name=name,
        description=description,
        transport=transport
    };
}

// This module can only be attached to one stream at a time.
public class Module : XmppStreamModule, Iq.Handler {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0166_jingle");

    private HashMap<string, ContentType> content_types = new HashMap<string, ContentType>();
    private HashMap<string, Transport> transports = new HashMap<string, Transport>();

    private XmppStream? current_stream = null;

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
        current_stream = stream;
    }
    public override void detach(XmppStream stream) {
        stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI, this);
    }

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
        Transport? result = null;
        foreach (Transport transport in transports.values) {
            if (transport.transport_type() != type) {
                continue;
            }
            if (transport.is_transport_available(stream, receiver_full_jid)) {
                if (result != null) {
                    if (result.transport_priority() >= transport.transport_priority()) {
                        continue;
                    }
                }
                result = transport;
            }
        }
        return result;
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
        TransportParameters transport_params = transport.create_transport_parameters(stream, my_jid, receiver_full_jid);
        Session session = new Session.initiate_sent(random_uuid(), type, transport_params, my_jid, receiver_full_jid, content_name, send_terminate_and_remove_session);
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
        ContentNode content = get_single_content_node(jingle);
        if (content.description == null || content.transport == null) {
            throw new IqError.BAD_REQUEST("missing description or transport node");
        }
        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
        if (my_jid == null) {
            throw new IqError.RESOURCE_CONSTRAINT("Couldn't determine own JID");
        }
        Transport? transport = get_transport(content.transport.ns_uri);
        TransportParameters? transport_params = null;
        if (transport != null) {
            transport_params = transport.parse_transport_parameters(stream, my_jid, iq.from, content.transport);
        } else {
            // terminate the session below
        }

        ContentType? content_type = get_content_type(content.description.ns_uri);
        if (content_type == null) {
            // TODO(hrxi): how do we signal an unknown content type?
            throw new IqError.NOT_IMPLEMENTED("unknown content type");
        }
        ContentParameters content_params = content_type.parse_content_parameters(content.description);

        TransportType type = content_type.content_type_transport_type();
        Session session = new Session.initiate_received(sid, type, transport_params, my_jid, iq.from, content.name, send_terminate_and_remove_session);
        stream.get_flag(Flag.IDENTITY).add_session(session);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));

        if (transport == null || transport.transport_type() != type) {
            StanzaNode reason = new StanzaNode.build("reason", NS_URI)
                .put_node(new StanzaNode.build("unsupported-transports", NS_URI));
            session.terminate(reason, "unsupported transports");
            return;
        }

        content_params.on_session_initiate(stream, session);
    }

    private void send_terminate_and_remove_session(Jid to, string sid, StanzaNode reason) {
        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-terminate")
            .put_attribute("sid", sid)
            .put_node(reason);
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=to };
        current_stream.get_module(Iq.Module.IDENTITY).send_iq(current_stream, iq);

        // Immediately remove the session from the open sessions as per the
        // XEP, don't wait for confirmation.
        current_stream.get_flag(Flag.IDENTITY).remove_session(sid);
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

public delegate void SessionTerminate(Jid to, string sid, StanzaNode reason);

public interface Transport : Object {
    public abstract string transport_ns_uri();
    public abstract bool is_transport_available(XmppStream stream, Jid full_jid);
    public abstract TransportType transport_type();
    public abstract int transport_priority();
    public abstract TransportParameters create_transport_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid);
    public abstract TransportParameters parse_transport_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws IqError;
}


// Gets a null `stream` if connection setup was unsuccessful and another
// transport method should be tried.
public interface TransportParameters : Object {
    public abstract string transport_ns_uri();
    public abstract StanzaNode to_transport_stanza_node();
    public abstract void on_transport_accept(StanzaNode transport) throws IqError;
    public abstract void on_transport_info(StanzaNode transport) throws IqError;
    public abstract void create_transport_connection(XmppStream stream, Session session);
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

    public static Role parse(string role) throws IqError {
        switch (role) {
            case "initiator": return INITIATOR;
            case "responder": return RESPONDER;
        }
        throw new IqError.BAD_REQUEST(@"invalid role $(role)");
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
    // INITIATE_SENT -> CONNECTING -> ACTIVE -> ENDED
    // INITIATE_RECEIVED -> CONNECTING -> ACTIVE -> ENDED
    public enum State {
        INITIATE_SENT,
        INITIATE_RECEIVED,
        CONNECTING,
        ACTIVE,
        ENDED,
    }

    public State state { get; private set; }

    public string sid { get; private set; }
    public Type type_ { get; private set; }
    public Jid local_full_jid { get; private set; }
    public Jid peer_full_jid { get; private set; }
    public Role content_creator { get; private set; }
    public string content_name { get; private set; }

    private Connection connection;
    public IOStream conn { get { return connection; } }

    // INITIATE_SENT | INITIATE_RECEIVED | CONNECTING
    TransportParameters? transport = null;

    SessionTerminate session_terminate_handler;

    public Session.initiate_sent(string sid, Type type, TransportParameters transport, Jid local_full_jid, Jid peer_full_jid, string content_name, owned SessionTerminate session_terminate_handler) {
        this.state = State.INITIATE_SENT;
        this.sid = sid;
        this.type_ = type;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.content_creator = Role.INITIATOR;
        this.content_name = content_name;
        this.transport = transport;
        this.connection = new Connection(this);
        this.session_terminate_handler = (owned)session_terminate_handler;
    }

    public Session.initiate_received(string sid, Type type, TransportParameters? transport, Jid local_full_jid, Jid peer_full_jid, string content_name, owned SessionTerminate session_terminate_handler) {
        this.state = State.INITIATE_RECEIVED;
        this.sid = sid;
        this.type_ = type;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.content_creator = Role.INITIATOR;
        this.content_name = content_name;
        this.transport = transport;
        this.connection = new Connection(this);
        this.session_terminate_handler = (owned)session_terminate_handler;
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
            case "transport-info":
                handle_transport_info(stream, jingle, iq);
                return;
            case "content-accept":
            case "content-add":
            case "content-modify":
            case "content-reject":
            case "content-remove":
            case "security-info":
            case "transport-accept":
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
        ContentNode content = get_single_content_node(jingle);
        verify_content(content);
        if (content.description == null || content.transport == null) {
            throw new IqError.BAD_REQUEST("missing description or transport node");
        }
        if (content.transport.ns_uri != transport.transport_ns_uri()) {
            throw new IqError.BAD_REQUEST("session-accept with unnegotiated transport method");
        }
        transport.on_transport_accept(content.transport);
        StanzaNode description = content.description; // TODO(hrxi): handle this :P
        state = State.CONNECTING;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        transport.create_transport_connection(stream, this);
    }
    void connection_created(XmppStream stream, IOStream? conn) {
        if (state != State.CONNECTING) {
            return;
        }
        if (conn != null) {
            state = State.ACTIVE;
            transport = null;
            connection.set_inner(conn);
        } else {
            // TODO(hrxi): try negotiating other transports…
            StanzaNode reason = new StanzaNode.build("reason", NS_URI)
                .put_node(new StanzaNode.build("failed-transport", NS_URI));
            terminate(reason, "failed transport");
        }
    }
    void handle_session_terminate(XmppStream stream, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        connection.on_terminated_by_jingle("remote terminated jingle session");
        state = State.ENDED;
        stream.get_flag(Flag.IDENTITY).remove_session(sid);

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        // TODO(hrxi): also handle presence type=unavailable
    }
    void handle_transport_info(XmppStream stream, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        if (state != State.INITIATE_RECEIVED && state != State.INITIATE_SENT && state != State.CONNECTING) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
            throw new IqError.UNSUPPORTED_INFO("transport-info unsupported after connection setup");
        }
        ContentNode content = get_single_content_node(jingle);
        verify_content(content);
        if (content.description != null || content.transport == null) {
            throw new IqError.BAD_REQUEST("unexpected description node or missing transport node");
        }
        transport.on_transport_info(content.transport);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
    }
    void verify_content(ContentNode content) throws IqError {
        if (content.name != content_name || content.creator != content_creator) {
            throw new IqError.BAD_REQUEST("unknown content");
        }
    }
    public void set_transport_connection(XmppStream stream, IOStream? conn) {
        if (state != State.CONNECTING) {
            return;
        }
        connection_created(stream, conn);
    }
    public void send_transport_info(XmppStream stream, StanzaNode transport) {
        if (state != State.CONNECTING) {
            return;
        }
        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "transport-info")
            .put_attribute("sid", sid)
            .put_node(new StanzaNode.build("content", NS_URI)
                .put_attribute("creator", "initiator")
                .put_attribute("name", content_name)
                .put_node(transport)
            );
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
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

        state = State.CONNECTING;
        transport.create_transport_connection(stream, this);
    }

    public void reject(XmppStream stream) {
        if (state != State.INITIATE_RECEIVED) {
            return; // TODO(hrxi): what to do?
        }
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("decline", NS_URI));
        terminate(reason, "declined");
    }

    public void set_application_error(XmppStream stream, StanzaNode? application_reason = null) {
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("failed-application", NS_URI));
        if (application_reason != null) {
            reason.put_node(application_reason);
        }
        terminate(reason, "application error");
    }

    public void on_connection_error(IOError error) {
        // TODO(hrxi): where can we get an XmppStream from?
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("failed-transport", NS_URI))
            .put_node(new StanzaNode.build("text", NS_URI)
                .put_node(new StanzaNode.text(error.message))
            );
        terminate(reason, "transport error: $(error.message)");
    }
    public void on_connection_close() {
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("success", NS_URI));
        terminate(reason, "success");
    }

    public void terminate(StanzaNode reason, string? local_reason) {
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

        session_terminate_handler(peer_full_jid, sid, reason);
        state = State.ENDED;
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
            handle_connection_error(e);
            throw e;
        }
    }
    public async ssize_t write_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield wait_and_check_for_errors(io_priority, cancellable);
        try {
            return yield inner.output_stream.write_async(buffer, io_priority, cancellable);
        } catch (IOError e) {
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
            if (error == null) {
                error = e;
            }
        }
        try {
            result = (yield close_if_both_closed(io_priority, cancellable)) && result;
        } catch (IOError e) {
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
            if (error == null) {
                error = e;
            }
        }
        try {
            result = (yield close_if_both_closed(io_priority, cancellable)) && result;
        } catch (IOError e) {
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
