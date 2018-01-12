using Gee;

namespace Xmpp.StreamError {
    private const string NS_URI = "jabber:client";
    private const string NS_ERROR = "urn:ietf:params:xml:ns:xmpp-streams";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "stream_error_module");

        public override void attach(XmppStream stream) {
            stream.received_nonza.connect(on_received_nonstanza);
        }

        public override void detach(XmppStream stream) {
            stream.received_nonza.disconnect(on_received_nonstanza);
        }

        public static void require(XmppStream stream) {
            if (stream.get_module(IDENTITY) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void on_received_nonstanza(XmppStream stream, StanzaNode node) {
            if (node.name == "error" && node.ns_uri == "http://etherx.jabber.org/streams") {
                stream.add_flag(generate_error_flag(node));
            }
        }

        private Flag generate_error_flag(StanzaNode node) {
            string? subnode_name = null;
            Gee.List<StanzaNode> subnodes = node.sub_nodes;
            foreach (StanzaNode subnode in subnodes) { // TODO get subnode by ns
                if (subnode.ns_uri == "urn:ietf:params:xml:ns:xmpp-streams" && subnode.name != "text") {
                    subnode_name = subnode.name;
                }
            }
            Flag flag = new StreamError.Flag();
            flag.error_type = subnode_name;
            switch (subnode_name) {
                case "bad-format":
                case "conflict":
                case "connection-timeout":
                case "bad-namespace-prefix":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.NOW;
                    break;
                case "host-gone":
                case "host-unknown":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.LATER;
                    break;
                case "improper-addressing":
                case "internal-server-error":
                case "invalid-from":
                case "invalid-namespace":
                case "invalid-xml":
                case "not-authorized":
                case "not-well-formed":
                case "policy-violation":
                case "remote-connection-failed":
                case "reset":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.NOW;
                    break;
                case "resource-constraint":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.LATER;
                    break;
                case "restricted-xml":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.NOW;
                    break;
                case "see-other-host":
                case "system-shutdown":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.LATER;
                    break;
                case "undefined-condition":
                case "unsupported-encoding":
                case "unsupported-feature":
                case "unsupported-stanza-type":
                case "unsupported-version":
                    flag.reconnection_recomendation = StreamError.Flag.Reconnect.NOW;
                    break;
            }

            if (subnode_name == "conflict") flag.resource_rejected = true;
            return flag;
        }
    }

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "stream_error");

        public enum Reconnect {
            UNKNOWN,
            NOW,
            LATER,
            NEVER
        }

        public string? error_type;
        public Reconnect reconnection_recomendation = Reconnect.UNKNOWN;
        public bool resource_rejected = false;

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
