namespace Xmpp.Xep.StreamManagement  {

public const string NS_URI = "urn:xmpp:sm:3";

public class Module : XmppStreamNegotiationModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0198_stream_management");

    public int h_inbound { get; private set; default=0; }
    public string? session_id { get; set; default=null; }
    public Gee.List<XmppStreamFlag> flags = null;

    public override void attach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.connect(check_enable);
        stream.received_features_node.connect(check_resume);

        stream.received_nonza.connect(on_received_nonza);
        stream.received_message_stanza.connect(on_stanza_received);
        stream.received_presence_stanza.connect(on_stanza_received);
        stream.received_iq_stanza.connect(on_stanza_received);
    }

    public override void detach(XmppStream stream) { }

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
        lock (h_inbound) h_inbound++;
    }

    private void check_resume(XmppStream stream) {
        if (stream_has_sm_feature(stream) && session_id != null) {
            Tls.Flag? tls_flag = stream.get_flag(Tls.Flag.IDENTITY);
            if (tls_flag != null && tls_flag.finished) {
                StanzaNode node = new StanzaNode.build("resume", NS_URI).add_self_xmlns()
                    .put_attribute("h", h_inbound.to_string())
                    .put_attribute("previd", session_id);
                stream.write(node);
                stream.add_flag(new Flag());
            }
        }
    }

    private void check_enable(XmppStream stream) {
        if (stream_has_sm_feature(stream) && session_id == null) {
            StanzaNode node = new StanzaNode.build("enable", NS_URI).add_self_xmlns().put_attribute("resume", "true");
            stream.write(node);
            stream.add_flag(new Flag());
        }
    }

    private void on_received_nonza(XmppStream stream, StanzaNode node) {
        if (node.ns_uri == NS_URI) {
            if (node.name == "r") {
                send_ack(stream);
            } else if (node.name == "a") {
                handle_ack(stream, node);
            } else if (node.name in new string[]{"enabled", "resumed", "failed"}) {
                stream.get_flag(Flag.IDENTITY).finished = true;

                if (node.name == "enabled") {
                    lock(h_inbound) h_inbound = 0;
                    session_id = node.get_attribute("id", NS_URI);
                    flags = stream.flags;
                } else if (node.name == "resumed") {
                    foreach (XmppStreamFlag flag in flags) {
                        stream.add_flag(flag);
                    }
                    stream.negotiation_complete = true;
                } else if (node.name == "failed") {
                    stream.received_features_node(stream);
                    session_id = null;
                }
            }
        }
    }

    private void send_ack(XmppStream stream) {
        StanzaNode node = new StanzaNode.build("a", NS_URI).add_self_xmlns().put_attribute("h", h_inbound.to_string());
        stream.write(node);
    }

    private void handle_ack(XmppStream stream, StanzaNode node) {

    }

    private bool stream_has_sm_feature(XmppStream stream) {
        return stream.features.get_subnode("sm", NS_URI) != null;
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "stream_management");
    public bool finished = false;

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
