using Xmpp.Core;

namespace Xmpp.Bind {
    private const string NS_URI = "urn:ietf:params:xml:ns:xmpp-bind";

    /** The parties to a stream MUST consider resource binding as mandatory-to-negotiate. (RFC6120 7.3.1) */
    public class Module : XmppStreamNegotiationModule {
        public const string ID = "bind_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        private string requested_resource;

        public signal void bound_to_resource(XmppStream stream, string my_jid);

        public Module(string requested_resource) {
            this.requested_resource = requested_resource;
        }

        public void iq_response_stanza(XmppStream stream, Iq.Stanza iq) {
            var flag = Flag.get_flag(stream);
            if (flag == null || flag.finished) return;

            if (iq.type_ == Iq.Stanza.TYPE_RESULT) {
                flag.my_jid = iq.stanza.get_subnode("jid", NS_URI, true).get_string_content();
                flag.finished = true;
                bound_to_resource(stream, flag.my_jid);
            }
        }

        public void received_features_node(XmppStream stream) {
            if (stream.is_setup_needed()) return;

            var bind = stream.features.get_subnode("bind", NS_URI);
            if (bind != null) {
                var flag = new Flag();
                StanzaNode bind_node = new StanzaNode.build("bind", NS_URI).add_self_xmlns();
                bind_node.put_node(new StanzaNode.build("resource", NS_URI).put_node(new StanzaNode.text(requested_resource)));
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.set(bind_node), on_bind_response);
                stream.add_flag(flag);
            }
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
            stream.received_features_node.connect(this.received_features_node);
        }

        public override void detach(XmppStream stream) {
            stream.received_features_node.disconnect(this.received_features_node);
        }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new Bind.Module(""));
        }

        public override bool mandatory_outstanding(XmppStream stream) {
            return !Flag.has_flag(stream) || !Flag.get_flag(stream).finished;
        }

        public override bool negotiation_active(XmppStream stream) {
            return Flag.has_flag(stream) && !Flag.get_flag(stream).finished;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private static void on_bind_response(XmppStream stream, Iq.Stanza iq) {
            stream.get_module(Bind.Module.IDENTITY).iq_response_stanza(stream, iq);
        }
    }

    public class Flag : XmppStreamFlag {
        public const string ID = "bind";
        public string? my_jid;
        public bool finished = false;

        public static Flag? get_flag(XmppStream stream) {
            return (Flag?) stream.get_flag(NS_URI, ID);
        }

        public static bool has_flag(XmppStream stream) {
            return get_flag(stream) != null;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }
}
