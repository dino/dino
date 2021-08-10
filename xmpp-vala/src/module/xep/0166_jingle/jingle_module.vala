using Gee;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    public const string NS_URI = "urn:xmpp:jingle:1";
    private const string ERROR_NS_URI = "urn:xmpp:jingle:errors:1";

    // This module can only be attached to one stream at a time.
    public class Module : XmppStreamModule, Iq.Handler {
        public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0166_jingle");

        public signal void session_initiate_received(XmppStream stream, Session session);

        private HashMap<string, ContentType> content_types = new HashMap<string, ContentType>();
        private HashMap<string, SessionInfoNs> session_info_types = new HashMap<string, SessionInfoNs>();
        private HashMap<string, Transport> transports = new HashMap<string, Transport>();
        private HashMap<string, SecurityPrecondition> security_preconditions = new HashMap<string, SecurityPrecondition>();

        public override void attach(XmppStream stream) {
            stream.add_flag(new Flag());
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);

            // TODO update stream in all sessions
        }

        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
            stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI, this);
        }

        public void register_content_type(ContentType content_type) {
            content_types[content_type.ns_uri] = content_type;
        }

        public void register_session_info_type(SessionInfoNs info_ns) {
            session_info_types[info_ns.ns_uri] = info_ns;
        }

        public ContentType? get_content_type(string ns_uri) {
            if (!content_types.has_key(ns_uri)) {
                return null;
            }
            return content_types[ns_uri];
        }

        public SessionInfoNs? get_session_info_type(string ns_uri) {
            return session_info_types[ns_uri];
        }

        public void register_transport(Transport transport) {
            transports[transport.ns_uri] = transport;
        }

        public Transport? get_transport(string ns_uri) {
            if (!transports.has_key(ns_uri)) {
                return null;
            }
            return transports[ns_uri];
        }

        public async Transport? select_transport(XmppStream stream, TransportType type, uint8 components, Jid receiver_full_jid, Set<string> blacklist) {
            Transport? result = null;
            foreach (Transport transport in transports.values) {
                if (transport.type_ != type) {
                    continue;
                }
                if (transport.ns_uri in blacklist) {
                    continue;
                }
                if (yield transport.is_transport_available(stream, components, receiver_full_jid)) {
                    if (result != null) {
                        if (result.priority >= transport.priority) {
                            continue;
                        }
                    }
                    result = transport;
                }
            }
            return result;
        }

        public void register_security_precondition(SecurityPrecondition precondition) {
            security_preconditions[precondition.security_ns_uri()] = precondition;
        }

        public SecurityPrecondition? get_security_precondition(string? ns_uri) {
            if (ns_uri == null) return null;
            if (!security_preconditions.has_key(ns_uri)) {
                return null;
            }
            return security_preconditions[ns_uri];
        }

        private async bool is_jingle_available(XmppStream stream, Jid full_jid) {
            bool? has_jingle = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
            return has_jingle != null && has_jingle;
        }

        public async bool is_available(XmppStream stream, TransportType type, uint8 components, Jid full_jid) {
            return (yield is_jingle_available(stream, full_jid)) && (yield select_transport(stream, type, components, full_jid, Set.empty())) != null;
        }

        public async Session create_session(XmppStream stream, Gee.List<Content> contents, Jid receiver_full_jid, string? sid = null) throws Error {
            if (!yield is_jingle_available(stream, receiver_full_jid)) {
                throw new Error.NO_SHARED_PROTOCOLS("No Jingle support");
            }
            Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
            if (my_jid == null) {
                throw new Error.GENERAL("Couldn't determine own JID");
            }

            Session session = new Session.initiate_sent(stream, sid ?? random_uuid(), my_jid, receiver_full_jid);
            session.terminated.connect((session, stream, _1, _2, _3) => { stream.get_flag(Flag.IDENTITY).remove_session(session.sid); });

            foreach (Content content in contents) {
                session.insert_content(content);
            }

            // Build & send session-initiate iq stanza
            StanzaNode initiate_jingle_iq = new StanzaNode.build("jingle", NS_URI)
                    .add_self_xmlns()
                    .put_attribute("action", "session-initiate")
                    .put_attribute("initiator", my_jid.to_string())
                    .put_attribute("sid", session.sid);

            foreach (Content content in contents) {
                StanzaNode content_node = new StanzaNode.build("content", NS_URI)
                        .put_attribute("creator", "initiator")
                        .put_attribute("name", content.content_name)
                        .put_attribute("senders", content.senders.to_string())
                        .put_node(content.content_params.get_description_node())
                        .put_node(content.transport_params.to_transport_stanza_node("session-initiate"));
                if (content.security_params != null) {
                    content_node.put_node(content.security_params.to_security_stanza_node(stream, my_jid, receiver_full_jid));
                }
                initiate_jingle_iq.put_node(content_node);
            }

            Iq.Stanza iq = new Iq.Stanza.set(initiate_jingle_iq) { to=receiver_full_jid };

            stream.get_flag(Flag.IDENTITY).add_session(session);
            // We might get a follow-up before the ack => add_session before send_iq returns
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
                if (iq.is_error()) warning("Jingle session-initiate got error: %s", iq.stanza.to_string());
            });

            return session;
        }

        public async void handle_session_initiate(XmppStream stream, string sid, StanzaNode jingle, Iq.Stanza iq) throws IqError {
            Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
            if (my_jid == null) {
                throw new IqError.RESOURCE_CONSTRAINT("Couldn't determine own JID");
            }

            Session session = new Session.initiate_received(stream, sid, my_jid, iq.from);
            session.terminated.connect((stream) => { stream.get_flag(Flag.IDENTITY).remove_session(sid); });

            stream.get_flag(Flag.IDENTITY).pre_add_session(session.sid);

            foreach (ContentNode content_node in get_content_nodes(jingle)) {
                yield session.insert_content_node(content_node, iq.from);
            }

            stream.get_flag(Flag.IDENTITY).add_session(session);

            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));

            session_initiate_received(stream, session);
        }

        public async void on_iq_set(XmppStream stream, Iq.Stanza iq) {
            try {
                yield handle_iq_set(stream, iq);
            } catch (IqError e) {
                send_iq_error(e, stream, iq);
            }
        }

        public async void handle_iq_set(XmppStream stream, Iq.Stanza iq) throws IqError {
            StanzaNode? jingle_node = iq.stanza.get_subnode("jingle", NS_URI);
            if (jingle_node == null) {
                throw new IqError.BAD_REQUEST("missing jingle node");
            }
            string? sid = jingle_node.get_attribute("sid");
            string? action = jingle_node.get_attribute("action");
            if (sid == null || action == null) {
                throw new IqError.BAD_REQUEST("missing jingle node, sid or action");
            }

            Session? session = yield stream.get_flag(Flag.IDENTITY).get_session(sid);
            if (action == "session-initiate") {
                if (session != null) {
                    stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.build(ErrorStanza.TYPE_MODIFY, ErrorStanza.CONDITION_CONFLICT, "session ID already in use", null)) { to=iq.from });
                    return;
                }
                yield handle_session_initiate(stream, sid, jingle_node, iq);
                return;
            }
            if (session == null) {
                StanzaNode unknown_session = new StanzaNode.build("unknown-session", ERROR_NS_URI).add_self_xmlns();
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.item_not_found(unknown_session)) { to=iq.from });
                return;
            }
            session.handle_iq_set(action, jingle_node, iq);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
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
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, error) { to=iq.from });
    }
}