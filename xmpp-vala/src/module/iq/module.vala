using Gee;

namespace Xmpp.Iq {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "iq_module");

        private HashMap<string, ResponseListener> responseListeners = new HashMap<string, ResponseListener>();
        private HashMap<string, ArrayList<Handler>> namespaceRegistrants = new HashMap<string, ArrayList<Handler>>();

        public async Iq.Stanza send_iq_async(XmppStream stream, Iq.Stanza iq) {
            Iq.Stanza? return_stanza = null;
            send_iq(stream, iq, (_, result_iq) => {
                return_stanza = result_iq;
                Idle.add(send_iq_async.callback);
            });
            yield;
            return return_stanza;
        }

        public delegate void OnResult(XmppStream stream, Iq.Stanza iq);
        public void send_iq(XmppStream stream, Iq.Stanza iq, owned OnResult? listener = null) {
            stream.write(iq.stanza);
            if (listener != null) {
                responseListeners[iq.id] = new ResponseListener((owned) listener);
            }
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
        }

        public override void detach(XmppStream stream) {
            stream.received_iq_stanza.disconnect(on_received_iq_stanza);
        }

        public override bool mandatory_outstanding(XmppStream stream) { return false; }

        public override bool negotiation_active(XmppStream stream) { return false; }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private async void on_received_iq_stanza(XmppStream stream, StanzaNode node) {
            Iq.Stanza iq = new Iq.Stanza.from_stanza(node, stream.has_flag(Bind.Flag.IDENTITY) ? stream.get_flag(Bind.Flag.IDENTITY).my_jid : null);

            if (iq.type_ == Iq.Stanza.TYPE_RESULT || iq.is_error()) {
                if (responseListeners.has_key(iq.id)) {
                    ResponseListener? listener = responseListeners.get(iq.id);
                    if (listener != null) {
                        listener.on_result(stream, iq);
                    }
                    responseListeners.unset(iq.id);
                }
            } else {
                Gee.List<StanzaNode> children = node.get_all_subnodes();
                if (children.size == 1 && namespaceRegistrants.has_key(children[0].ns_uri)) {
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

        private class ResponseListener {
            public OnResult on_result { get; private owned set; }

            public ResponseListener(owned OnResult on_result) {
                this.on_result = (owned) on_result;
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
