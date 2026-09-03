using Gee;

namespace Xmpp.Iq {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "iq_module");

        public signal void preprocess_incoming_iq_set_get(XmppStream stream, Stanza iq_stanza);
        public signal void preprocess_outgoing_iq_set_get(XmppStream stream, Stanza iq_stanza);

        private HashMap<XmppStream, HashMap<string, ResponseListener>> responseListeners = new HashMap<XmppStream, HashMap<string, ResponseListener>>();
        private HashSet<XmppStream> attachedStreams = new HashSet<XmppStream>();
        private HashMap<string, ArrayList<Handler>> namespaceRegistrants = new HashMap<string, ArrayList<Handler>>();

        public async Iq.Stanza send_iq_async(XmppStream stream, Iq.Stanza iq, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            assert(iq.type_ == Iq.Stanza.TYPE_GET || iq.type_ == Iq.Stanza.TYPE_SET);

            preprocess_outgoing_iq_set_get(stream, iq);
            string? stanza_id = iq.id;
            assert(stanza_id != null);
            string id = (!)stanza_id;
            Iq.Stanza? return_stanza = null;
            ResponseFailure? failure = null;
            string? failure_message = null;
            ResponseListener response_listener = new ResponseListener((_, result_iq) => {
                Idle.add(() => {
                    return_stanza = result_iq;
                    send_iq_async.callback();
                    return Source.REMOVE;
                });
            }, (reason, message) => {
                Idle.add(() => {
                    failure = reason;
                    failure_message = message;
                    send_iq_async.callback();
                    return Source.REMOVE;
                });
            });
            ResponseListenerRegistration registration = set_response_listener(stream, id, response_listener);
            if (registration == ResponseListenerRegistration.Closed) {
                throw new IOError.CLOSED("XMPP stream was detached");
            }
            if (registration == ResponseListenerRegistration.Duplicate) {
                throw new IOError.PENDING("IQ request ID is already pending");
            }
            ulong cancelled_handler_id = 0;
            bool should_write = true;
            if (cancellable != null) {
                cancelled_handler_id = cancellable.cancelled.connect(() => {
                    ResponseListener? listener = take_response_listener(stream, id, response_listener);
                    if (listener != null) {
                        ((!)listener).fail(ResponseFailure.Cancelled, "IQ request was cancelled");
                    }
                });
                if (cancellable.is_cancelled()) {
                    should_write = false;
                    ResponseListener? listener = take_response_listener(stream, id, response_listener);
                    if (listener != null) ((!)listener).fail(ResponseFailure.Cancelled, "IQ request was cancelled");
                }
            }
            if (should_write) {
                stream.write_async.begin(iq.stanza, io_priority, cancellable, (_, res) => {
                    try {
                        stream.write_async.end(res);
                    } catch (IOError e) {
                        ResponseListener? listener = take_response_listener(stream, id, response_listener);
                        if (listener != null) ((!)listener).fail(ResponseFailure.WriteError, e.message);
                    }
                });
            }
            yield;
            if (cancellable != null) {
                cancellable.disconnect(cancelled_handler_id);
            }
            if (failure == ResponseFailure.Cancelled) {
                throw new IOError.CANCELLED(failure_message ?? "IQ request was cancelled");
            }
            if (failure == ResponseFailure.Closed) {
                throw new IOError.CLOSED(failure_message ?? "XMPP stream was detached");
            }
            if (failure == ResponseFailure.WriteError) {
                throw new IOError.FAILED(failure_message ?? "Failed to write IQ request");
            }
            return (!)return_stanza;
        }

        public delegate void OnResult(XmppStream stream, Iq.Stanza iq);
        public void send_iq(XmppStream stream, Iq.Stanza iq, owned OnResult? listener = null, int io_priority = Priority.DEFAULT) {
            preprocess_outgoing_iq_set_get(stream, iq);
            if (listener != null) {
                string? stanza_id = iq.id;
                assert(stanza_id != null);
                string id = (!)stanza_id;
                ResponseListenerRegistration registration = set_response_listener(
                        stream, id, new ResponseListener((owned) listener));
                if (registration == ResponseListenerRegistration.Closed) {
                    warning("Not sending IQ on a detached XMPP stream");
                    return;
                }
                if (registration == ResponseListenerRegistration.Duplicate) {
                    warning("Not sending IQ with an already pending request ID");
                    return;
                }
            }
            stream.write(iq.stanza, io_priority);
        }

        public void register_for_namespace(string namespace, Handler module) {
            if (!namespaceRegistrants.has_key(namespace)) {
                namespaceRegistrants.set(namespace, new ArrayList<Handler>());
            }
            namespaceRegistrants[namespace].add(module);
        }

        public void unregister_from_namespace(string namespace, Handler module) {
            ArrayList<Handler>? handlers = namespaceRegistrants[namespace];
            if (handlers != null) handlers.remove(module);
        }

        public override void attach(XmppStream stream) {
            stream.received_iq_stanza.connect(on_received_iq_stanza);
            lock (responseListeners) {
                attachedStreams.add(stream);
            }
        }

        public override void detach(XmppStream stream) {
            ArrayList<ResponseListener> listeners = new ArrayList<ResponseListener>();
            lock (responseListeners) {
                attachedStreams.remove(stream);
                HashMap<string, ResponseListener>? stream_listeners = responseListeners[stream];
                if (stream_listeners != null) {
                    foreach (ResponseListener listener in stream_listeners.values) listeners.add(listener);
                    responseListeners.unset(stream);
                }
            }
            stream.received_iq_stanza.disconnect(on_received_iq_stanza);
            foreach (ResponseListener listener in listeners) {
                listener.fail(ResponseFailure.Closed, "XMPP stream was detached");
            }
        }

        public override bool mandatory_outstanding(XmppStream stream) { return false; }

        public override bool negotiation_active(XmppStream stream) { return false; }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private async void on_received_iq_stanza(XmppStream stream, StanzaNode node) {
            Iq.Stanza iq = new Iq.Stanza.from_stanza(node, stream.has_flag(Bind.Flag.IDENTITY) ? stream.get_flag(Bind.Flag.IDENTITY).my_jid : null);

            if (iq.type_ == Iq.Stanza.TYPE_RESULT || iq.is_error()) {
                string? id = iq.id;
                if (id != null) {
                    ResponseListener? listener = take_response_listener(stream, (!)id);
                    if (listener != null) ((!)listener).on_result(stream, iq);
                }
            } else {
                Gee.List<StanzaNode> children = node.get_all_subnodes();
                if (children.size == 1 && namespaceRegistrants.has_key(children[0].ns_uri)) {
                    preprocess_incoming_iq_set_get(stream, iq);
                    Gee.List<Handler> handlers = namespaceRegistrants[children[0].ns_uri];
                    foreach (Handler handler in handlers) {
                        if (iq.type_ == Iq.Stanza.TYPE_GET) {
                            yield handler.on_iq_get(stream, iq);
                        } else if (iq.type_ == Iq.Stanza.TYPE_SET) {
                            yield handler.on_iq_set(stream, iq);
                        }
                    }
                } else {
                    // Send error if we don't handle the NS of the IQ get/set payload (RFC6120 10.3.3 (2))
                    Iq.Stanza unavailable_error = new Iq.Stanza.error(iq, new ErrorStanza.service_unavailable()) { to=iq.from };
                    send_iq(stream, unavailable_error);
                }
            }
        }

        private ResponseListenerRegistration set_response_listener(XmppStream stream, string id, ResponseListener listener) {
            lock (responseListeners) {
                if (!attachedStreams.contains(stream)) return ResponseListenerRegistration.Closed;
                if (responseListeners.has_key(stream) && responseListeners[stream].has_key(id)) {
                    return ResponseListenerRegistration.Duplicate;
                }
                if (!responseListeners.has_key(stream)) {
                    responseListeners[stream] = new HashMap<string, ResponseListener>();
                }
                responseListeners[stream][id] = listener;
                return ResponseListenerRegistration.Registered;
            }
        }

        private ResponseListener? take_response_listener(XmppStream stream, string id, ResponseListener? expected = null) {
            lock (responseListeners) {
                HashMap<string, ResponseListener>? stream_listeners = responseListeners[stream];
                if (stream_listeners == null) return null;

                ResponseListener? listener = stream_listeners[id];
                if (listener == null || (expected != null && listener != expected)) return null;

                stream_listeners.unset(id);
                if (stream_listeners.is_empty) responseListeners.unset(stream);
                return listener;
            }
        }

        private enum ResponseFailure {
            Cancelled,
            Closed,
            WriteError
        }

        private enum ResponseListenerRegistration {
            Registered,
            Closed,
            Duplicate
        }

        private delegate void OnFailure(ResponseFailure failure, string message);

        private class ResponseListener {
            public OnResult on_result { get; private owned set; }
            private OnFailure? on_failure;

            public ResponseListener(owned OnResult on_result, owned OnFailure? on_failure = null) {
                this.on_result = (owned) on_result;
                this.on_failure = (owned) on_failure;
            }

            public void fail(ResponseFailure failure, string message) {
                if (on_failure != null) on_failure(failure, message);
            }
        }
    }

    public interface Handler : Object {
        public async virtual void on_iq_get(XmppStream stream, Iq.Stanza iq) {
            Iq.Stanza bad_request = new Iq.Stanza.error(iq, new ErrorStanza.bad_request("unexpected IQ get for this namespace"));
            stream.get_module(Module.IDENTITY).send_iq(stream, bad_request);
        }
        public async virtual void on_iq_set(XmppStream stream, Iq.Stanza iq) {
            Iq.Stanza bad_request = new Iq.Stanza.error(iq, new ErrorStanza.bad_request("unexpected IQ set for this namespace"));
            stream.get_module(Module.IDENTITY).send_iq(stream, bad_request);
        }
    }

}
