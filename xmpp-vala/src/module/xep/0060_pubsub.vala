using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Pubsub {
    private const string NS_URI = "http://jabber.org/protocol/pubsub";
    private const string NS_URI_EVENT = NS_URI + "#event";

    public class Module : XmppStreamModule {
        public const string ID = "0060_pubsub_module";

        private HashMap<string, EventListenerDelegate> event_listeners = new HashMap<string, EventListenerDelegate>();

        public void add_filtered_notification(XmppStream stream, string node, EventListenerDelegate.ResultFunc on_result, Object? reference = null) {
            ServiceDiscovery.Module.get_module(stream).add_feature_notify(stream, node);
            event_listeners[node] = new EventListenerDelegate(on_result, reference);
        }

        public void request(XmppStream stream, string jid, string node, RequestResponseListener listener) { // TODO multiple nodes gehen auch
            Iq.Stanza a = new Iq.Stanza.get(new StanzaNode.build("pubsub", NS_URI).add_self_xmlns().put_node(new StanzaNode.build("items", NS_URI).put_attribute("node", node)));
            a.to = jid;
            Iq.Module.get_module(stream).send_iq(stream, a, new IqRequestResponseListener(listener));
        }

        private class IqRequestResponseListener : Iq.ResponseListener, Object {
            RequestResponseListener response_listener;
            public IqRequestResponseListener(RequestResponseListener response_listener) { this.response_listener = response_listener; }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                StanzaNode event_node = iq.stanza.get_subnode("pubsub", NS_URI);
                StanzaNode items_node = event_node != null ? event_node.get_subnode("items", NS_URI) : null;
                StanzaNode item_node = items_node != null ? items_node.get_subnode("item", NS_URI) : null;
                string? node = items_node != null ? items_node.get_attribute("node", NS_URI) : null;
                string? id = item_node != null ? item_node.get_attribute("id", NS_URI) : null;
                response_listener.on_result(stream, iq.from, id, item_node != null ? item_node.sub_nodes[0] : null);
            }
        }

        public void publish(XmppStream stream, string? jid, string node_id, string node, string item_id, StanzaNode content) {
            StanzaNode pubsub_node = new StanzaNode.build("pubsub", NS_URI).add_self_xmlns();
            StanzaNode publish_node = new StanzaNode.build("publish", NS_URI).put_attribute("node", node_id);
            pubsub_node.put_node(publish_node);
            StanzaNode items_node = new StanzaNode.build("item", NS_URI).put_attribute("id", item_id);
            items_node.put_node(content);
            publish_node.put_node(items_node);
            Iq.Stanza iq = new Iq.Stanza.set(pubsub_node);
            Iq.Module.get_module(stream).send_iq(stream, iq, null);
        }

        private class IqPublishResponseListener : Iq.ResponseListener, Object {
            PublishResponseListener response_listener;
            public IqPublishResponseListener(PublishResponseListener response_listener) { this.response_listener = response_listener; }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                if (iq.is_error()) {
                    response_listener.on_error(stream);
                } else {
                    response_listener.on_success(stream);
                }
            }
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
            Message.Module.require(stream);
            ServiceDiscovery.Module.require(stream);
            Message.Module.get_module(stream).received_message.connect(on_received_message);
        }

        public override void detach(XmppStream stream) {
            Message.Module.get_module(stream).received_message.disconnect(on_received_message);
        }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private void on_received_message(XmppStream stream, Message.Stanza message) {
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

    public interface RequestResponseListener : Object {
        public abstract void on_result(XmppStream stream, string jid, string? id, StanzaNode? node);
    }

    public class EventListenerDelegate {
        public delegate void ResultFunc(XmppStream stream, string jid, string id, StanzaNode node);
        public ResultFunc on_result { get; private set; }
        private Object reference;

        public EventListenerDelegate(ResultFunc on_result, Object? reference = null) {
            this.on_result = on_result;
            this.reference = reference;
        }
    }

    public interface PublishResponseListener : Object {
        public abstract void on_success(XmppStream stream);
        public abstract void on_error(XmppStream stream);
    }
}
