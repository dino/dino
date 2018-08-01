namespace Xmpp.Bind {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-bind";

    /** The parties to a stream MUST consider resource binding as mandatory-to-negotiate. (RFC6120 7.3.1) */
    public class Module : XmppStreamNegotiationModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "bind_module");

        public string requested_resource { get; set; }

        public signal void bound_to_resource(XmppStream stream, Jid my_jid);

        public Module(string requested_resource) {
            this.requested_resource = requested_resource;
        }

        public void iq_response_stanza(XmppStream stream, Iq.Stanza iq) {
            var flag = stream.get_flag(Flag.IDENTITY);
            if (flag == null || flag.finished) return;

            if (iq.type_ == Iq.Stanza.TYPE_RESULT) {
                flag.my_jid = Jid.parse(iq.stanza.get_subnode("jid", NS_URI, true).get_string_content());
                flag.finished = true;
                bound_to_resource(stream, flag.my_jid);
            }
        }

        public void received_features_node(XmppStream stream) {
            if (stream.is_setup_needed()) return;
            if (stream.is_negotiation_active()) return;

            var bind = stream.features.get_subnode("bind", NS_URI);
            if (bind != null) {
                var flag = new Flag();
                StanzaNode bind_node = new StanzaNode.build("bind", NS_URI).add_self_xmlns();
                bind_node.put_node(new StanzaNode.build("resource", NS_URI).put_node(new StanzaNode.text(requested_resource)));
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.set(bind_node), iq_response_stanza);
                stream.add_flag(flag);
            }
        }

        public override void attach(XmppStream stream) {
            stream.received_features_node.connect(this.received_features_node);
        }

        public override void detach(XmppStream stream) {
            stream.received_features_node.disconnect(this.received_features_node);
        }

        public override bool mandatory_outstanding(XmppStream stream) {
            return !stream.has_flag(Flag.IDENTITY) || !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override bool negotiation_active(XmppStream stream) {
            return stream.has_flag(Flag.IDENTITY) && !stream.get_flag(Flag.IDENTITY).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "bind");
        public Jid? my_jid;
        public bool finished = false;

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
