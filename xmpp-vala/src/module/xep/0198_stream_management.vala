using Gee;

namespace Xmpp.Xep.StreamManagement  {

public const string NS_URI = "urn:xmpp:sm:3";

public class Module : XmppStreamNegotiationModule, WriteNodeFunc {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0198_stream_management");

    public int h_inbound = 0;
    public int h_outbound = 0;

    public string? session_id { get; set; default=null; }
    public Gee.List<XmppStreamFlag> flags = null;
    private HashMap<int, QueueItem> in_flight_stanzas = new HashMap<int, QueueItem>();
    private Gee.Queue<QueueItem> node_queue = new PriorityQueue<QueueItem>((a, b) => {
        return a.io_priority - b.io_priority;
    });

    private class QueueItem {
        public StanzaNode node;
        public int io_priority;
        public Cancellable? cancellable;
        public Promise<void*> promise;

        public QueueItem(StanzaNode node, int io_priority, Cancellable? cancellable) {
            this.node = node;
            this.io_priority = io_priority;
            this.cancellable = cancellable;
            this.promise = new Promise<void*>();
        }
    }

    public async void write_stanza(XmppStream stream, StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        var future = enqueue_stanza(stream, node, io_priority, cancellable);
        try {
            yield future.wait_async();
        } catch (FutureError e) {
            if (e is FutureError.ABANDON_PROMISE) {
                throw new IOError.FAILED("Future abandoned: %s".printf(e.message));
            } else if (e is FutureError.EXCEPTION) {
                if (future.exception is IOError) {
                    throw (IOError) future.exception;
                } else {
                    throw new IOError.FAILED("Unknown error %s".printf(future.exception.message));
                }
            } else {
                throw new IOError.FAILED("Unknown future error: %s".printf(e.message));
            }
        }
    }

    private Future<void*> enqueue_stanza(XmppStream stream, StanzaNode node, int io_priority, Cancellable? cancellable) {
        var queue_item = new QueueItem(node, io_priority, cancellable);
        node_queue.offer(queue_item);
        check_queue(stream);
        return queue_item.promise.future;
    }

    internal async void write_node(XmppStream stream, StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) {
        StanzaWriter? writer = ((IoXmppStream)stream).writer;
        if (writer == null) return;
        try {
            stream.log.node("OUT", node, stream);
            if (node.name == "message" || node.name == "iq" || node.name == "presence") {
                var r_node = new StanzaNode.build("r", NS_URI).add_self_xmlns();
                stream.log.node("OUT", r_node, stream);
                yield ((!)writer).write_nodes(node, r_node, io_priority, cancellable);
            } else {
                yield ((!)writer).write_node(node, io_priority, cancellable);
            }
        } catch (IOError e) { }
    }

    private void check_queue(XmppStream stream) {
        while (!node_queue.is_empty && in_flight_stanzas.size < 10) {
            QueueItem queue_item = node_queue.poll();
            try {
                queue_item.cancellable.set_error_if_cancelled();
            } catch (IOError e) {
                queue_item.promise.set_exception(e);
                continue;
            }
            StanzaNode node = queue_item.node;

            if (node.name == "message" || node.name == "iq" || node.name == "presence") {
                in_flight_stanzas[++h_outbound] = queue_item;
            }
            write_node.begin(stream, node, queue_item.io_priority, queue_item.cancellable);
        }
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.connect(check_enable);
        stream.received_features_node.connect(check_resume);

        stream.received_nonza.connect(on_received_nonza);
        stream.received_message_stanza.connect(on_stanza_received);
        stream.received_presence_stanza.connect(on_stanza_received);
        stream.received_iq_stanza.connect(on_stanza_received);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.disconnect(check_enable);
        stream.received_features_node.disconnect(check_resume);

        stream.received_nonza.disconnect(on_received_nonza);
        stream.received_message_stanza.disconnect(on_stanza_received);
        stream.received_presence_stanza.disconnect(on_stanza_received);
        stream.received_iq_stanza.disconnect(on_stanza_received);
    }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stream.add_module(new PrivateXmlStorage.Module());
    }

    public override bool mandatory_outstanding(XmppStream stream) { return false; }

    public override bool negotiation_active(XmppStream stream) {
        return stream.has_flag(Flag.IDENTITY) && !stream.get_flag(Flag.IDENTITY).finished;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_stanza_received(XmppStream stream, StanzaNode node) {
        h_inbound++;
    }

    private void check_resume(XmppStream stream) {
        if (stream_has_sm_feature(stream) && session_id != null && !Flag.get_add_flag(stream).finished) {
            StanzaNode node = new StanzaNode.build("resume", NS_URI).add_self_xmlns()
                .put_attribute("h", h_inbound.to_string())
                .put_attribute("previd", session_id);
            write_node.begin(stream, node);

            Flag.get_add_flag(stream);
        }
    }

    private void check_enable(XmppStream stream) {
        if (stream_has_sm_feature(stream) && session_id == null && !Flag.get_add_flag(stream).finished) {
            StanzaNode node = new StanzaNode.build("enable", NS_URI).add_self_xmlns().put_attribute("resume", "true");
            write_node.begin(stream, node);

            Flag.get_add_flag(stream);

            h_outbound = 0;
        }
    }

    private void on_received_nonza(XmppStream stream, StanzaNode node) {
        if (node.ns_uri == NS_URI) {
            if (node.name == "r") {
                send_ack(stream);
            } else if (node.name == "a") {
                handle_ack(stream, node);
            } else if (node.name in new string[]{"enabled", "resumed", "failed"}) {
                if (node.name == "enabled") {
                    on_enabled(stream, node);
                } else if (node.name == "resumed") {
                    on_resumed(stream, node);
                } else if (node.name == "failed") {
                    on_resume_failed(stream, node);
                }
            }
        }
    }

    public void on_resumed(XmppStream stream, StanzaNode resumed_node) {
        var flag = stream.get_flag(Flag.IDENTITY);
        flag.resumed = true;
        flag.finished = true;

        foreach (XmppStreamFlag f in flags) {
            stream.add_flag(f);
        }

        h_outbound = int.parse(resumed_node.get_attribute("h", NS_URI));
        handle_incoming_h(stream, h_outbound);
        foreach (var id in in_flight_stanzas.keys) {
            node_queue.add(in_flight_stanzas[id]);
        }
        in_flight_stanzas.clear();
        check_queue(stream);
        ((IoXmppStream)stream).write_obj = this;

        stream.get_flag(Flag.IDENTITY).finished = true;
    }

    public void on_resume_failed(XmppStream stream, StanzaNode failed_node) {
        session_id = null;
        string? h_acked = failed_node.get_attribute("h", NS_URI);
        if (h_acked != null) {
            h_outbound = int.parse(h_acked);
            handle_incoming_h(stream, h_outbound);
        }
        foreach (var id in in_flight_stanzas.keys) {
            in_flight_stanzas[id].promise.set_exception(new IOError.FAILED("Stanza not acked and session not resumed"));
        }
        in_flight_stanzas.clear();
        check_queue(stream);
        stream.received_features_node(stream);

        stream.get_flag(Flag.IDENTITY).finished = true;
    }

    public void on_enabled(XmppStream stream, StanzaNode enabled_node) {
        h_inbound = 0;
        session_id = enabled_node.get_attribute("id", NS_URI);
        flags = stream.flags;
        ((IoXmppStream)stream).write_obj = this;

        stream.get_flag(Flag.IDENTITY).finished = true;
    }

    private void send_ack(XmppStream stream) {
        StanzaNode node = new StanzaNode.build("a", NS_URI).add_self_xmlns().put_attribute("h", h_inbound.to_string());
        write_node.begin(stream, node);
    }

    private void handle_ack(XmppStream stream, StanzaNode node) {
        string? h_acked = node.get_attribute("h", NS_URI);
        int parsed_int = int.parse(h_acked);
        handle_incoming_h(stream, parsed_int);
        check_queue(stream);
    }

    private void handle_incoming_h(XmppStream stream, int h) {
        var remove_nrs = new ArrayList<int>();
        foreach (int nr in in_flight_stanzas.keys) {
            if (nr <= h) {
                remove_nrs.add(nr);
            }
        }
        foreach (int nr in remove_nrs) {
            in_flight_stanzas[nr].promise.set_value(null);
            in_flight_stanzas.unset(nr);
        }
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "stream_management");
    public bool finished { get; set; default=false; }
    public bool resumed = false;

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public static Flag get_add_flag(XmppStream stream) {
        Flag? flag = stream.get_flag(IDENTITY);
        if (flag == null) {
            flag = new Flag();
            stream.add_flag(flag);
        }
        return flag;
    }
}

    public class Bind2Activation : Bind2.Bind2InlineActivation {
        public override StanzaNode? get_activation_node(XmppStream stream) {
            // Always insert an enable node, even if we also try to resume in Sasl2. Because if resumption fails, enable will be used.
            Flag.get_add_flag(stream);

            stream.get_module(Module.IDENTITY).h_outbound = 0;

            return new StanzaNode.build("enable", NS_URI).add_self_xmlns().put_attribute("resume", "true");
        }

        public override void on_bound(XmppStream stream, StanzaNode bound_node) {
            StanzaNode? enabled_node = bound_node.get_subnode("enabled", NS_URI);
            if (enabled_node != null) {
                stream.get_module(Module.IDENTITY).on_enabled(stream, enabled_node);
            }
        }
    }

    public class Sasl2Activation : ExtensibleSaslProfile.Sasl2InlineActivation {
        public override StanzaNode? get_activation_node(XmppStream stream, StanzaNode node) {
            if (stream.get_module(Module.IDENTITY).session_id != null) {
                Flag.get_add_flag(stream);

                var sm_module = stream.get_module(Module.IDENTITY);

                StanzaNode resume_node = new StanzaNode.build("resume", NS_URI).add_self_xmlns()
                        .put_attribute("h", sm_module.h_inbound.to_string())
                        .put_attribute("previd", sm_module.session_id);
                return resume_node;
            }
            return null;
        }

        public override void on_bound(XmppStream stream, Jid authorization_identifier, StanzaNode success_node) {
            StanzaNode? resumed_node = success_node.get_subnode("resumed", NS_URI);
            if (resumed_node != null) {
                stream.get_module(Module.IDENTITY).on_resumed(stream, resumed_node);
            }

            StanzaNode? failed_node = success_node.get_subnode("failed", NS_URI);
            if (failed_node != null) {
                stream.get_module(Module.IDENTITY).on_resume_failed(stream, failed_node);
            }
        }
    }

    private bool stream_has_sm_feature(XmppStream stream) {
        return stream.features.get_subnode("sm", NS_URI) != null;
    }
}
