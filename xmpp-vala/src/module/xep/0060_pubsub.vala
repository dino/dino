using Gee;

namespace Xmpp.Xep.Pubsub {
    private const string NS_URI = "http://jabber.org/protocol/pubsub";
    private const string NS_URI_EVENT = NS_URI + "#event";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0060_pubsub_module");

        private HashMap<string, EventListenerDelegate> event_listeners = new HashMap<string, EventListenerDelegate>();

        public void add_filtered_notification(XmppStream stream, string node, owned EventListenerDelegate.ResultFunc listener) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature_notify(stream, node);
            event_listeners[node] = new EventListenerDelegate((owned)listener);
        }

        public delegate void OnResult(XmppStream stream, Jid jid, string? id, StanzaNode? node);
        public void request(XmppStream stream, Jid jid, string node, owned OnResult listener) { // TODO multiple nodes gehen auch
            Iq.Stanza request_iq = new Iq.Stanza.get(new StanzaNode.build("pubsub", NS_URI).add_self_xmlns().put_node(new StanzaNode.build("items", NS_URI).put_attribute("node", node)));
            request_iq.to = jid;
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, request_iq, (stream, iq) => {
                StanzaNode event_node = iq.stanza.get_subnode("pubsub", NS_URI);
                StanzaNode items_node = event_node != null ? event_node.get_subnode("items", NS_URI) : null;
                StanzaNode item_node = items_node != null ? items_node.get_subnode("item", NS_URI) : null;
                string? id = item_node != null ? item_node.get_attribute("id", NS_URI) : null;
                listener(stream, iq.from, id, item_node != null ? item_node.sub_nodes[0] : null);
            });
        }

        public void publish(XmppStream stream, Jid? jid, string node_id, string node, string? item_id, StanzaNode content) {
            StanzaNode pubsub_node = new StanzaNode.build("pubsub", NS_URI).add_self_xmlns();
            StanzaNode publish_node = new StanzaNode.build("publish", NS_URI).put_attribute("node", node_id);
            pubsub_node.put_node(publish_node);
            StanzaNode items_node = new StanzaNode.build("item", NS_URI);
            if (item_id != null) items_node.put_attribute("id", item_id);
            items_node.put_node(content);
            publish_node.put_node(items_node);
            Iq.Stanza iq = new Iq.Stanza.set(pubsub_node);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, null);
        }

        public override void attach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            StanzaNode event_node = message.stanza.get_subnode("event", NS_URI_EVENT); if (event_node == null) return;
            StanzaNode items_node = event_node.get_subnode("items", NS_URI_EVENT); if (items_node == null) return;
            StanzaNode item_node = items_node.get_subnode("item", NS_URI_EVENT); if (item_node == null) return;
            string node = items_node.get_attribute("node", NS_URI_EVENT);
            string id = item_node.get_attribute("id", NS_URI_EVENT);
            if (event_listeners.has_key(node)) {
                event_listeners[node].on_result(stream, message.from, id, item_node.sub_nodes[0]);
            }
        }
    }

    public class EventListenerDelegate {
        public delegate void ResultFunc(XmppStream stream, Jid jid, string id, StanzaNode? node);
        public ResultFunc on_result { get; private owned set; }

        public EventListenerDelegate(owned ResultFunc on_result) {
            this.on_result = (owned) on_result;
        }
    }
}
