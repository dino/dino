using Gee;
using Xmpp;


public delegate void Xmpp.Xep.Jingle.SessionTerminate(Jid to, string sid, StanzaNode reason);

public class Xmpp.Xep.Jingle.Session : Object {

    public signal void terminated(XmppStream stream, bool we_terminated, string? reason_name, string? reason_text);
    public signal void additional_content_add_incoming(XmppStream stream, Content content);

    // INITIATE_SENT/INITIATE_RECEIVED -> CONNECTING -> PENDING -> ACTIVE -> ENDED
    public enum State {
        INITIATE_SENT,
        INITIATE_RECEIVED,
        ACTIVE,
        ENDED,
    }

    public XmppStream stream { get; set; }
    public State state { get; set; }
    public string sid { get; private set; }
    public Jid local_full_jid { get; private set; }
    public Jid peer_full_jid { get; private set; }
    public bool we_initiated { get; private set; }

    public HashMap<string, Content> contents_map = new HashMap<string, Content>();
    public Gee.List<Content> contents = new ArrayList<Content>(); // Keep the order contents

    public SecurityParameters? security { get { return contents.to_array()[0].security_params; } }

    public Session.initiate_sent(XmppStream stream, string sid, Jid local_full_jid, Jid peer_full_jid) {
        this.stream = stream;
        this.sid = sid;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.state = State.INITIATE_SENT;
        this.we_initiated = true;
    }

    public Session.initiate_received(XmppStream stream, string sid, Jid local_full_jid, Jid peer_full_jid) {
        this.stream = stream;
        this.sid = sid;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        this.state = State.INITIATE_RECEIVED;
        this.we_initiated = false;
    }

    public void handle_iq_set(string action, StanzaNode jingle, Iq.Stanza iq) throws IqError {

        if (action.has_prefix("session-")) {
            switch (action) {
                case "session-accept":
                    Gee.List<ContentNode> content_nodes = get_content_nodes(jingle);

                    if (state != State.INITIATE_SENT) {
                        throw new IqError.OUT_OF_ORDER("got session-accept while not waiting for one");
                    }
                    handle_session_accept(content_nodes, jingle, iq);
                    break;
                case "session-info":
                    handle_session_info.begin(jingle, iq);
                    break;
                case "session-terminate":
                    handle_session_terminate(jingle, iq);
                    break;
                default:
                    throw new IqError.BAD_REQUEST("invalid action");
            }


        } else if (action.has_prefix("content-")) {
            switch (action) {
                case "content-accept":
                    ContentNode content_node = get_single_content_node(jingle);
                    handle_content_accept(content_node);
                    stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
                    break;
                case "content-add":
                    ContentNode content_node = get_single_content_node(jingle);
                    insert_content_node.begin(content_node, peer_full_jid);
                    stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
                    break;
                case "content-modify":
                    handle_content_modify(stream, jingle, iq);
                    break;
                case "content-reject":
                case "content-remove":
                    throw new IqError.NOT_IMPLEMENTED(@"$(action) is not implemented");
                default:
                    throw new IqError.BAD_REQUEST("invalid action");
            }


        } else if (action.has_prefix("transport-")) {
            ContentNode content_node = get_single_content_node(jingle);
            if (!contents_map.has_key(content_node.name)) {
                throw new IqError.BAD_REQUEST("unknown content");
            }

            if (content_node.transport == null) {
                throw new IqError.BAD_REQUEST("missing transport node");
            }

            Content content = contents_map[content_node.name];

            if (content_node.creator != content.content_creator) {
                throw new IqError.BAD_REQUEST("unknown content; creator");
            }

            switch (action) {
                case "transport-accept":
                    content.handle_transport_accept(stream, content_node.transport, jingle, iq);
                    break;
                case "transport-info":
                    content.handle_transport_info(stream, content_node.transport, jingle, iq);
                    break;
                case "transport-reject":
                    content.handle_transport_reject(stream, jingle, iq);
                    break;
                case "transport-replace":
                    content.handle_transport_replace(stream, content_node.transport, jingle, iq);
                    break;
                default:
                    throw new IqError.BAD_REQUEST("invalid action");
            }


        } else if (action == "description-info") {
            ContentNode content_node = get_single_content_node(jingle);
            if (!contents_map.has_key(content_node.name)) {
                throw new IqError.BAD_REQUEST("unknown content");
            }

            Content content = contents_map[content_node.name];

            if (content_node.creator != content.content_creator) {
                throw new IqError.BAD_REQUEST("unknown content; creator");
            }

            content.on_description_info(stream, content_node.description, jingle, iq);
        } else if (action == "security-info") {
            throw new IqError.NOT_IMPLEMENTED(@"$(action) is not implemented");


        } else {
            throw new IqError.BAD_REQUEST("invalid action");
        }
    }

    internal void insert_content(Content content) {
        this.contents_map[content.content_name] = content;
        this.contents.add(content);
        content.set_session(this);
    }

    internal async void insert_content_node(ContentNode content_node, Jid peer_full_jid) throws IqError {
        if (content_node.description == null || content_node.transport == null) {
            throw new IqError.BAD_REQUEST("missing description or transport node");
        }

        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;

        Transport? transport = stream.get_module(Jingle.Module.IDENTITY).get_transport(content_node.transport.ns_uri);
        ContentType? content_type = stream.get_module(Jingle.Module.IDENTITY).get_content_type(content_node.description.ns_uri);

        if (content_type == null) {
            // TODO(hrxi): how do we signal an unknown content type?
            throw new IqError.NOT_IMPLEMENTED("unknown content type");
        }

        TransportParameters? transport_params = null;
        if (transport != null) {
            transport_params = transport.parse_transport_parameters(stream, content_type.required_components, my_jid, peer_full_jid, content_node.transport);
        } else {
            // terminate the session below
        }

        ContentParameters content_params = content_type.parse_content_parameters(content_node.description);

        SecurityPrecondition? precondition = content_node.security != null ? stream.get_module(Jingle.Module.IDENTITY).get_security_precondition(content_node.security.ns_uri) : null;
        SecurityParameters? security_params = null;
        if (precondition != null) {
            debug("Using precondition %s", precondition.security_ns_uri());
            security_params = precondition.parse_security_parameters(stream, my_jid, peer_full_jid, content_node.security);
        } else if (content_node.security != null) {
            throw new IqError.NOT_IMPLEMENTED("unknown security precondition");
        }

        TransportType type = content_type.required_transport_type;

        if (transport == null || transport.type_ != type) {
            terminate(ReasonElement.UNSUPPORTED_TRANSPORTS, null, "unsupported transports");
            throw new IqError.NOT_IMPLEMENTED("unsupported transports");
        }

        Content content = new Content.initiate_received(content_node.name, content_node.senders,
                content_type, content_params,
                transport, transport_params,
                precondition, security_params,
                my_jid, peer_full_jid);
        insert_content(content);

        yield content_params.handle_proposed_content(stream, this, content);

        if (this.state == State.ACTIVE) {
            additional_content_add_incoming(stream, content);
        }
    }

    public async void add_content(Content content) {
        insert_content(content);

        StanzaNode content_add_node = new StanzaNode.build("jingle", NS_URI)
                .add_self_xmlns()
                .put_attribute("action", "content-add")
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("content", NS_URI)
                    .put_attribute("creator", "initiator")
                    .put_attribute("name", content.content_name)
                    .put_attribute("senders", content.senders.to_string())
                    .put_node(content.content_params.get_description_node())
                    .put_node(content.transport_params.to_transport_stanza_node("content-add")));

        Iq.Stanza iq = new Iq.Stanza.set(content_add_node) { to=peer_full_jid };
        yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
    }

    private void handle_content_accept(ContentNode content_node) throws IqError {
        if (content_node.description == null || content_node.transport == null) throw new IqError.BAD_REQUEST("missing description or transport node");
        if (!contents_map.has_key(content_node.name)) throw new IqError.BAD_REQUEST("unknown content");

        Content content = contents_map[content_node.name];

        if (content_node.creator != content.content_creator) warning("Counterpart accepts content with an unexpected `creator`");
        if (content_node.senders != content.senders) warning("Counterpart accepts content with an unexpected `senders`");
        if (content_node.transport.ns_uri != content.transport_params.ns_uri) throw new IqError.BAD_REQUEST("session-accept with unnegotiated transport method");

        content.handle_accept(stream, content_node);
    }

    private void handle_content_modify(XmppStream stream, StanzaNode jingle_node, Iq.Stanza iq) throws IqError {
        ContentNode content_node = get_single_content_node(jingle_node);

        Content? content = contents_map[content_node.name];

        if (content == null) throw new IqError.BAD_REQUEST("no such content");
        if (content_node.creator != content.content_creator) throw new IqError.BAD_REQUEST("mismatching creator");

        Iq.Stanza result_iq = new Iq.Stanza.result(iq) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, result_iq);

        content.handle_content_modify(stream, content_node.senders);
    }

    private void handle_session_accept(Gee.List<ContentNode> content_nodes, StanzaNode jingle, Iq.Stanza iq) throws IqError {
        string? responder_str = jingle.get_attribute("responder");
        Jid responder = iq.from;
        if (responder_str != null) {
            try {
                responder = new Jid(responder_str);
            } catch (InvalidJidError e) {
                warning("Received invalid session accept: %s", e.message);
            }
        }

        foreach (ContentNode content_node in content_nodes) {
            handle_content_accept(content_node);
        }
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));

        state = State.ACTIVE;
    }

    private void handle_session_terminate(StanzaNode jingle, Iq.Stanza iq) throws IqError {
        string? reason_text = null;
        string? reason_name = null;
        StanzaNode? reason_node = iq.stanza.get_deep_subnode(NS_URI + ":jingle", NS_URI + ":reason");
        if (reason_node != null) {
            if (reason_node.sub_nodes.size > 2) warning("Jingle session-terminate reason node w/ >2 subnodes: %s", iq.stanza.to_string());

            StanzaNode? specific_reason_node = null;
            StanzaNode? text_node = null;
            foreach (StanzaNode node in reason_node.sub_nodes) {
                if (node.name == "text") {
                    text_node = node;
                } else if (node.ns_uri == NS_URI) {
                    specific_reason_node = node;
                }
            }
            reason_name = specific_reason_node != null ? specific_reason_node.name : null;
            reason_text = text_node != null ? text_node.get_string_content() : null;

            if (reason_name != null && !(specific_reason_node.name in ReasonElement.NORMAL_TERMINATE_REASONS)) {
                warning("Jingle session terminated: %s : %s", reason_name ?? "", reason_text ?? "");
            } else {
                debug("Jingle session terminated: %s : %s", reason_name ?? "", reason_text ?? "");
            }
        }

        foreach (Content content in contents) {
            content.terminate(false, reason_name, reason_text);
        }

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        // TODO(hrxi): also handle presence type=unavailable

        state = State.ENDED;
        terminated(stream, false, reason_name, reason_text);
    }

    private async void handle_session_info(StanzaNode jingle, Iq.Stanza iq) throws IqError {
        StanzaNode? info = get_single_node_anyns(jingle);
        if (info == null) {
            // Jingle session ping
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
            return;
        }
        SessionInfoNs? info_ns = stream.get_module(Module.IDENTITY).get_session_info_type(info.ns_uri);
        if (info_ns == null) {
            throw new IqError.UNSUPPORTED_INFO("unknown session-info namespace");
        }
        info_ns.handle_content_session_info(stream, this, info, iq);

        Iq.Stanza result_iq = new Iq.Stanza.result(iq) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, result_iq);
    }

    private void accept() {
        if (state != State.INITIATE_RECEIVED) critical("Accepting a stream, but we're the initiator");

        StanzaNode jingle = new StanzaNode.build("jingle", NS_URI)
                .add_self_xmlns()
                .put_attribute("action", "session-accept")
                .put_attribute("sid", sid);
        foreach (Content content in contents) {
            StanzaNode content_node = new StanzaNode.build("content", NS_URI)
                    .put_attribute("creator", "initiator")
                    .put_attribute("name", content.content_name)
                    .put_attribute("senders", content.senders.to_string())
                    .put_node(content.content_params.get_description_node())
                    .put_node(content.transport_params.to_transport_stanza_node("session-accept"));
            jingle.put_node(content_node);
        }

        Iq.Stanza iq = new Iq.Stanza.set(jingle) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);


        foreach (Content content2 in contents) {
            content2.on_accept(stream);
        }

        state = State.ACTIVE;
    }

    internal void accept_content(Content content) {
        if (state == State.INITIATE_RECEIVED) {
            bool all_accepted = true;
            foreach (Content c in contents) {
                if (c.state != Content.State.WANTS_TO_BE_ACCEPTED) {
                    all_accepted = false;
                }
            }
            if (all_accepted) {
                accept();
            }
        } else if (state == State.ACTIVE) {
            StanzaNode content_accept_node = new StanzaNode.build("jingle", NS_URI)
                    .add_self_xmlns()
                    .put_attribute("action", "content-accept")
                    .put_attribute("sid", sid)
                    .put_node(new StanzaNode.build("content", NS_URI)
                        .put_attribute("creator", "initiator")
                        .put_attribute("name", content.content_name)
                        .put_attribute("senders", content.senders.to_string())
                        .put_node(content.content_params.get_description_node())
                        .put_node(content.transport_params.to_transport_stanza_node("content-accept")));

            Iq.Stanza iq = new Iq.Stanza.set(content_accept_node) { to=peer_full_jid };
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);

            content.on_accept(stream);
        }
    }

    private void reject() {
        if (state != State.INITIATE_RECEIVED) critical("Accepting a stream, but we're the initiator");
        terminate(ReasonElement.DECLINE, null, "declined");
    }

    internal void reject_content(Content content) {
        if (state == State.INITIATE_RECEIVED) {
            reject();
        } else {
            warning("not really handeling content rejects");
        }
    }

    public void set_application_error(StanzaNode? application_reason = null) {
        terminate(ReasonElement.FAILED_APPLICATION, null, "application error");
    }

    public void terminate(string? reason_name, string? reason_text, string? local_reason) {
        if (state == State.ENDED) return;
        debug("Jingle session %s terminated: %s; %s; %s", this.sid, reason_name ?? "-", reason_text ?? "-", local_reason ?? "-");

        if (state == State.ACTIVE) {
            string reason_str;
            if (local_reason != null) {
                reason_str = @"local session-terminate: $(local_reason)";
            } else {
                reason_str = "local session-terminate";
            }
            foreach (Content content in contents) {
                content.terminate(true, reason_name, reason_text);
            }
        }

        StanzaNode terminate_iq = new StanzaNode.build("jingle", NS_URI)
                .add_self_xmlns()
                .put_attribute("action", "session-terminate")
                .put_attribute("sid", sid);
        if (reason_name != null || reason_text != null) {
            StanzaNode reason_node = new StanzaNode.build("reason", NS_URI);
            if (reason_name != null) {
                reason_node.put_node(new StanzaNode.build(reason_name, NS_URI));
            }
            if (reason_text != null) {
                reason_node.put_node(new StanzaNode.text(reason_text));
            }
            terminate_iq.put_node(reason_node);
        }
        Iq.Stanza iq = new Iq.Stanza.set(terminate_iq) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);

        state = State.ENDED;
        terminated(stream, true, reason_name, reason_text);
    }

    internal void send_session_info(StanzaNode child_node) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("session-info").put_node(child_node);
        Iq.Stanza iq = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    internal void send_content_modify(Content content, Senders senders) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("content-modify")
                .put_node(content.build_outer_content_node()
                    .put_attribute("senders", senders.to_string()));

        Iq.Stanza iq = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    internal void send_transport_accept(Content content, TransportParameters transport_params) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("transport-accept")
                .put_node(content.build_outer_content_node()
                    .put_node(transport_params.to_transport_stanza_node("transport-accept")));

        Iq.Stanza iq_response = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq_response);
    }

    internal void send_transport_replace(Content content, TransportParameters transport_params) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("transport-replace")
                .put_node(content.build_outer_content_node()
                    .put_node(transport_params.to_transport_stanza_node("transport-replace")));

        Iq.Stanza iq = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    internal void send_transport_reject(Content content, StanzaNode transport_node) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("transport-reject")
                .put_node(content.build_outer_content_node().put_node(transport_node));

        Iq.Stanza iq_response = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq_response);
    }

    internal void send_transport_info(Content content, StanzaNode transport) {
        if (state == State.ENDED) return;

        StanzaNode jingle_node = build_outer_session_node("transport-info")
                .put_node(content.build_outer_content_node().put_node(transport));

        Iq.Stanza iq = new Iq.Stanza.set(jingle_node) { to=peer_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }

    private StanzaNode build_outer_session_node(string action) {
        return new StanzaNode.build("jingle", NS_URI)
                .add_self_xmlns()
                .put_attribute("action", action)
                .put_attribute("initiator", we_initiated ? local_full_jid.to_string() : peer_full_jid.to_string())
                .put_attribute("sid", sid);
    }

    public bool senders_include_us(Senders senders) {
        switch (senders) {
            case Senders.BOTH:
                return true;
            case Senders.NONE:
                return false;
            case Senders.INITIATOR:
                return we_initiated;
            case Senders.RESPONDER:
                return !we_initiated;
        }
        assert_not_reached();
    }

    public bool senders_include_counterpart(Senders senders) {
        switch (senders) {
            case Senders.BOTH:
                return true;
            case Senders.NONE:
                return false;
            case Senders.INITIATOR:
                return !we_initiated;
            case Senders.RESPONDER:
                return we_initiated;
        }
        assert_not_reached();
    }
}