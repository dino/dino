using Gee;

namespace Xmpp.Xep.BitsOfBinary {

    public const string NS_URI = "urn:xmpp:bob";

    public static HashMap<string, Bytes> known_bobs = null;

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "bits_of_binary");

        private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

        public override void attach(XmppStream stream) {
            known_bobs = new HashMap<string, Bytes>();
            var message_module = stream.get_module(MessageModule.IDENTITY);
            if (message_module != null) {
                message_module.received_pipeline.connect(received_pipeline_listener);
            }
            stream.received_iq_stanza.connect(on_received_iq_stanza);
        }

        public override void detach(XmppStream stream) {
            var message_module = stream.get_module(MessageModule.IDENTITY);
            if (message_module != null) {
                message_module.received_pipeline.disconnect(received_pipeline_listener);
            }

            stream.received_iq_stanza.disconnect(on_received_iq_stanza);
        }

        private async void on_received_iq_stanza(XmppStream stream, StanzaNode node) {
            if (node.sub_nodes == null || node.sub_nodes.size == 0) return;
            Gee.List<StanzaNode> data_nodes = node.sub_nodes[0].get_subnodes("data", NS_URI);
            foreach (var data_node in data_nodes) {
                string cid = data_node.get_attribute("cid", NS_URI);
                if (cid == null) continue;

                known_bobs[cid] = new Bytes.take(Base64.decode(data_node.get_string_content()));
            }
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

    public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

        private const string[] after_actions_const = {};

        public override string action_group { get { return ""; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(XmppStream stream, MessageStanza message) {
            Gee.List<StanzaNode> data_nodes = message.stanza.get_subnodes("data", NS_URI);
            foreach (var data_node in data_nodes) {
                string cid = data_node.get_attribute("cid", NS_URI);
                if (cid == null) continue;

                known_bobs[cid] = new Bytes.take(Base64.decode(data_node.get_string_content()));
            }

            return false;
        }
    }
}