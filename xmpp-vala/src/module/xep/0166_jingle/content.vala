using Gee;
using Xmpp;

public class Xmpp.Xep.Jingle.Content : Object {

    public signal void senders_modify_incoming(Senders proposed_senders);

    // INITIATE_SENT -> CONNECTING -> [REPLACING_TRANSPORT -> CONNECTING ->]... ACTIVE -> ENDED
    // INITIATE_RECEIVED -> CONNECTING -> [WAITING_FOR_TRANSPORT_REPLACE -> CONNECTING ->].. ACTIVE -> ENDED
    public enum State {
        PENDING,
        WANTS_TO_BE_ACCEPTED,
        ACCEPTED,
        REPLACING_TRANSPORT,
        WAITING_FOR_TRANSPORT_REPLACE
    }

    public State state { get; set; }

    public Role role { get; private set; }
    public Jid local_full_jid { get; private set; }
    public Jid peer_full_jid { get; private set; }
    public Role content_creator { get; private set; }
    public string content_name { get; private set; }
    public Senders senders { get; private set; }

    public ContentType content_type;
    public ContentParameters content_params;
    public Transport transport;
    public TransportParameters? transport_params;
    public SecurityPrecondition security_precondition;
    public SecurityParameters? security_params;

    public weak Session session;
    public Map<uint8, ComponentConnection> component_connections = new HashMap<uint8, ComponentConnection>(); // TODO private

    public HashMap<string, ContentEncryption> encryptions = new HashMap<string, ContentEncryption>();

    private Set<string> tried_transport_methods = new HashSet<string>();


    public Content.initiate_sent(string content_name, Senders senders,
                                 ContentType content_type, ContentParameters content_params,
                                 Transport transport, TransportParameters? transport_params,
                                 SecurityPrecondition? security_precondition, SecurityParameters? security_params,
                                 Jid local_full_jid, Jid peer_full_jid) {
        this.content_name = content_name;
        this.senders = senders;
        this.role = Role.INITIATOR;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.content_creator = Role.INITIATOR;

        this.content_type = content_type;
        this.content_params = content_params;
        this.transport = transport;
        this.transport_params = transport_params;
        this.security_precondition = security_precondition;
        this.security_params = security_params;

        this.tried_transport_methods.add(transport.ns_uri);

        state = State.PENDING;
    }

    public Content.initiate_received(string content_name, Senders senders,
                                     ContentType content_type, ContentParameters content_params,
                                     Transport transport, TransportParameters? transport_params,
                                     SecurityPrecondition? security_precondition, SecurityParameters? security_params,
                                     Jid local_full_jid, Jid peer_full_jid) throws Error {
        this.content_name = content_name;
        this.senders = senders;
        this.role = Role.RESPONDER;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.content_creator = Role.INITIATOR;

        this.content_type = content_type;
        this.content_params = content_params;
        this.transport = transport;
        this.transport_params = transport_params;
        this.security_precondition = security_precondition;
        this.security_params = security_params;

        if (transport != null) {
            this.tried_transport_methods.add(transport.ns_uri);
        }

        state = State.PENDING;
    }

    public void set_session(Session session) {
        this.session = session;
        this.transport_params.set_content(this);
    }

    public void accept() {
        if (state != State.PENDING) {
            warning("accepting a non-pending content");
            return;
        }
        state = State.WANTS_TO_BE_ACCEPTED;
        session.accept_content(this);
    }

    public void reject() {
        if (state != State.PENDING) {
            warning("rejecting a non-pending content");
            return;
        }
        session.reject_content(this);
    }

    public void terminate(bool we_terminated, string? reason_name, string? reason_text) {
        if (state == State.PENDING) {
            warning("terminating a pending call");
            return;
        }
        content_params.terminate(we_terminated, reason_name, reason_text);
        transport_params.dispose();

        foreach (ComponentConnection connection in component_connections.values) {
            connection.terminate.begin(we_terminated, reason_name, reason_text);
        }
    }

    public void modify(Senders new_sender) {
        session.send_content_modify(this, new_sender);
        this.senders = new_sender;
    }

    public void accept_content_modify(Senders senders) {
        this.senders = senders;
    }

    internal void handle_content_modify(XmppStream stream, Senders proposed_senders) {
        senders_modify_incoming(proposed_senders);
    }

    internal void on_accept(XmppStream stream) {
        this.transport_params.create_transport_connection(stream, this);
        this.content_params.accept(stream, session, this);
    }

    internal void handle_accept(XmppStream stream, ContentNode content_node) {
        this.transport_params.handle_transport_accept(content_node.transport);
        this.transport_params.create_transport_connection(stream, this);
        this.content_params.handle_accept(stream, this.session, this, content_node.description);
    }

    public async void select_new_transport() {
        XmppStream stream = session.stream;
        Transport? new_transport = yield stream.get_module(Module.IDENTITY).select_transport(stream, transport.type_, transport_params.components, peer_full_jid, tried_transport_methods);
        if (new_transport == null) {
            session.terminate(ReasonElement.FAILED_TRANSPORT, null, "failed transport");
            // TODO should we only terminate this content or really the whole session?
            return;
        }
        tried_transport_methods.add(new_transport.ns_uri);
        transport_params = new_transport.create_transport_parameters(stream, transport_params.components, local_full_jid, peer_full_jid);
        set_transport_params(transport_params);
        session.send_transport_replace(this, transport_params);
        state = State.REPLACING_TRANSPORT;
    }

    public void handle_transport_accept(XmppStream stream, StanzaNode transport_node, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        if (state != State.REPLACING_TRANSPORT) {
            throw new IqError.OUT_OF_ORDER("no outstanding transport-replace request");
        }
        if (transport_node.ns_uri != transport.ns_uri) {
            throw new IqError.BAD_REQUEST("transport-accept with unnegotiated transport method");
        }
        transport_params.handle_transport_accept(transport_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        transport_params.create_transport_connection(stream, this);
    }

    public void handle_transport_reject(XmppStream stream, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        if (state != State.REPLACING_TRANSPORT) {
            throw new IqError.OUT_OF_ORDER("no outstanding transport-replace request");
        }
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        select_new_transport.begin();
    }

    public void handle_transport_replace(XmppStream stream, StanzaNode transport_node, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        Transport? transport = stream.get_module(Module.IDENTITY).get_transport(transport_node.ns_uri);
        TransportParameters? parameters = null;
        if (transport != null) {
            // Just parse the transport info for the errors.
            parameters = transport.parse_transport_parameters(stream, content_type.required_components, local_full_jid, peer_full_jid, transport_node);
        }
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        if (state != State.WAITING_FOR_TRANSPORT_REPLACE || transport == null) {
            session.send_transport_reject(this, transport_node);
            return;
        }
        set_transport_params(parameters);
        session.send_transport_accept(this, parameters);

        this.transport_params.create_transport_connection(stream, this);
    }

    public void handle_transport_info(XmppStream stream, StanzaNode transport, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        this.transport_params.handle_transport_info(transport);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
    }

    public void on_description_info(XmppStream stream, StanzaNode description, StanzaNode jinglq, Iq.Stanza iq) throws IqError {
        // TODO: do something.
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
    }

    public void set_transport_connection(ComponentConnection? conn, uint8 component = 1) {
        debug(@"set_transport_connection: %s, %s, %i, %s, overwrites: %s", this.content_name, this.state.to_string(), component, (conn != null).to_string(), component_connections.has_key(component).to_string());

        if (conn != null) {
            component_connections[component] = conn;
            if (transport_params.components == component) {
                state = State.ACCEPTED;
                tried_transport_methods.clear();
            }
        } else {
            if (role == Role.INITIATOR) {
                select_new_transport.begin();
            } else {
                state = State.WAITING_FOR_TRANSPORT_REPLACE;
            }
        }
    }

    private void set_transport_params(TransportParameters transport_params) {
        this.transport_params = transport_params;
    }

    public ComponentConnection? get_transport_connection(uint8 component = 1) {
        return component_connections[component];
    }

    public void send_transport_info(StanzaNode transport) {
        session.send_transport_info(this, transport);
    }

    internal StanzaNode build_outer_content_node() {
        return new StanzaNode.build("content", NS_URI)
                .put_attribute("creator", content_creator.to_string())
                .put_attribute("name", content_name);
    }
}

public class Xmpp.Xep.Jingle.ContentEncryption : Object {
    public string encryption_ns;
    public string encryption_name;
    public uint8[] our_key;
    public uint8[] peer_key;

    public class ContentEncryption(string encryption_ns, string encryption_name, uint8[] our_key = new uint8[]{}, uint8[] peer_key = new uint8[]{}) {
        this.encryption_ns = encryption_ns;
        this.encryption_name = encryption_name;
        this.our_key = our_key;
        this.peer_key = peer_key;
    }
}