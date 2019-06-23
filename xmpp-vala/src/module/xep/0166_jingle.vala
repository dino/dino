using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

private const string NS_URI = "urn:xmpp:jingle:1";
private const string ERROR_NS_URI = "urn:xmpp:jingle:errors:1";

public errordomain CreateConnectionError {
    BAD_REQUEST,
    NOT_ACCEPTABLE,
}

public errordomain Error {
    GENERAL,
    BAD_REQUEST,
    INVALID_PARAMETERS,
    UNSUPPORTED_TRANSPORT,
    NO_SHARED_PROTOCOLS,
    TRANSPORT_ERROR,
}

public class Module : XmppStreamModule, Iq.Handler {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0166_jingle");

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
    }
    public override void detach(XmppStream stream) { }

    public void add_transport(XmppStream stream, Transport transport) {
        stream.get_flag(Flag.IDENTITY).add_transport(transport);
    }
    public Transport? select_transport(XmppStream stream, TransportType type, Jid receiver_full_jid) {
        return stream.get_flag(Flag.IDENTITY).select_transport(stream, type, receiver_full_jid);
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
        Session session = new Session(random_uuid(), type, receiver_full_jid);
        StanzaNode content = new StanzaNode.build("content", NS_URI)
            .put_attribute("creator", "initiator")
            .put_attribute("name", content_name)
            .put_attribute("senders", senders.to_string())
            .put_node(description)
            .put_node(transport.to_transport_stanza_node());
        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-initiate")
            .put_attribute("initiator", my_jid.to_string())
            .put_attribute("sid", session.sid)
            .put_node(content);
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=receiver_full_jid };

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            stream.get_flag(Flag.IDENTITY).add_session(session);
        });

        return session;
    }

    public void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? jingle = iq.stanza.get_subnode("jingle", NS_URI);
        string? sid = jingle != null ? jingle.get_attribute("sid") : null;
        string? action = jingle != null ? jingle.get_attribute("action") : null;
        if (jingle == null || sid == null || action == null) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("missing jingle node, sid or action")));
            return;
        }
        Session? session = stream.get_flag(Flag.IDENTITY).get_session(sid);
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
    public abstract bool is_transport_available(XmppStream stream, Jid full_jid);
    public abstract TransportType transport_type();
    public abstract StanzaNode to_transport_stanza_node();
    public abstract Connection? create_transport_connection(XmppStream stream, Jid peer_full_jid, StanzaNode content) throws CreateConnectionError;
}

public class Session {
    public enum State {
        PENDING,
        ACTIVE,
        ENDED,
    }

    public State state { get; private set; }
    Connection? conn;

    public string sid { get; private set; }
    public Type type_ { get; private set; }
    public Jid peer_full_jid { get; private set; }

    public Session(string sid, Type type, Jid peer_full_jid) {
        this.state = PENDING;
        this.conn = null;
        this.sid = sid;
        this.type_ = type;
        this.peer_full_jid = peer_full_jid;
    }

    public signal void on_error(XmppStream stream, Error error);
    public signal void on_data(XmppStream stream, uint8[] data);
    // Signals that the stream is ready to send (more) data.
    public signal void on_ready(XmppStream stream);

    private void handle_error(XmppStream stream, Error error) {
        if (state == PENDING || state == ACTIVE) {
            StanzaNode reason = new StanzaNode.build("reason", NS_URI)
                .put_node(new StanzaNode.build("general-error", NS_URI)) // TODO(hrxi): Is this the right error?
                .put_node(new StanzaNode.build("text", NS_URI)
                    .put_node(new StanzaNode.text(error.message))
                );
            terminate(stream, reason);
        }
    }

    delegate void SendIq(Iq.Stanza iq);
    public void handle_iq_set(XmppStream stream, string action, StanzaNode jingle, Iq.Stanza iq) {
        SendIq send_iq = (iq) => stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
        if (state != PENDING || action != "session-accept") {
            return;
        }
        StanzaNode? content = jingle.get_subnode("content");
        if (content == null) {
            // TODO(hrxi): here and below, should we terminate the session?
            send_iq(new Iq.Stanza.error(iq, new ErrorStanza.bad_request("no content element")));
            return;
        }
        string? responder_str = jingle.get_attribute("responder");
        Jid responder;
        if (responder_str != null) {
            responder = Jid.parse(responder_str) ?? iq.from;
        } else {
            responder = iq.from; // TODO(hrxi): and above, can we assume iq.from != null
            // TODO(hrxi): more sanity checking, perhaps replace who we're talking to
        }
        if (!responder.is_full()) {
            send_iq(new Iq.Stanza.error(iq, new ErrorStanza.bad_request("invalid responder JID")));
            return;
        }
        try {
            conn = stream.get_flag(Flag.IDENTITY).create_connection(stream, type_, peer_full_jid, content);
        } catch (CreateConnectionError e) {
            if (e is CreateConnectionError.BAD_REQUEST) {
                send_iq(new Iq.Stanza.error(iq, new ErrorStanza.bad_request(e.message)));
            } else if (e is CreateConnectionError.NOT_ACCEPTABLE) {
                send_iq(new Iq.Stanza.error(iq, new ErrorStanza.not_acceptable(e.message)));
            }
            return;
        }
        send_iq(new Iq.Stanza.result(iq));
        if (conn == null) {
            terminate(stream, new StanzaNode.build("reason", NS_URI)
                .put_node(new StanzaNode.build("unsupported-transports", NS_URI)));
            return;
        }
        conn.on_error.connect((stream, error) => on_error(stream, error));
        conn.on_data.connect((stream, data) => on_data(stream, data));
        conn.on_ready.connect((stream) => on_ready(stream));
        on_error.connect((stream, error) => handle_error(stream, error));
        conn.connect(stream);
        state = ACTIVE;
    }

    public void send(XmppStream stream, uint8[] data) {
        if (state != ACTIVE) {
            return; // TODO(hrxi): what to do?
        }
        conn.send(stream, data);
    }

    public void set_application_error(XmppStream stream, StanzaNode? application_reason = null) {
        StanzaNode reason = new StanzaNode.build("reason", NS_URI)
            .put_node(new StanzaNode.build("failed-application", NS_URI));
        if (application_reason != null) {
            reason.put_node(application_reason);
        }
        terminate(stream, reason);
    }

    public void close_connection(XmppStream stream) {
        if (state != ACTIVE) {
            return; // TODO(hrxi): what to do?
        }
        conn.close(stream);
    }

    public void terminate(XmppStream stream, StanzaNode reason) {
        if (state != PENDING && state != ACTIVE) {
            // TODO(hrxi): what to do?
            return;
        }
        if (conn != null) {
            conn.close(stream);
        }

        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
            .add_self_xmlns()
            .put_attribute("action", "session-terminate")
            .put_attribute("sid", sid)
            .put_node(reason);
        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);

        state = ENDED;
        // Immediately remove the session from the open sessions as per the
        // XEP, don't wait for confirmation.
        stream.get_flag(Flag.IDENTITY).remove_session(sid);
    }
}

public abstract class Connection {
    public Jid? peer_full_jid { get; private set; }

    public Connection(Jid peer_full_jid) {
        this.peer_full_jid = peer_full_jid;
    }

    public signal void on_error(XmppStream stream, Error error);
    public signal void on_data(XmppStream stream, uint8[] data);
    public signal void on_ready(XmppStream stream);

    public abstract void connect(XmppStream stream);
    public abstract void send(XmppStream stream, uint8[] data);
    public abstract void close(XmppStream stream);
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "jingle");

    private Gee.List<Transport> transports = new ArrayList<Transport>();
    private HashMap<string, Session> sessions = new HashMap<string, Session>();

    public void add_transport(Transport transport) { transports.add(transport); }
    public Transport? select_transport(XmppStream stream, TransportType type, Jid receiver_full_jid) {
        foreach (Transport transport in transports) {
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
    public void add_session(Session session) {
        sessions[session.sid] = session;
    }
    public Connection? create_connection(XmppStream stream, Type type, Jid peer_full_jid, StanzaNode content) throws CreateConnectionError {
        foreach (Transport transport in transports) {
            if (transport.transport_type() != type) {
                continue;
            }
            Connection? conn = transport.create_transport_connection(stream, peer_full_jid, content);
            if (conn != null) {
                return conn;
            }
        }
        return null;
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
