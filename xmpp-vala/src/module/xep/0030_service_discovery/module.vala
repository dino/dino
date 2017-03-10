using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.ServiceDiscovery {
    private const string NS_URI = "http://jabber.org/protocol/disco";
    public const string NS_URI_INFO = NS_URI + "#info";
    public const string NS_URI_ITEMS = NS_URI + "#items";

    public class Module : XmppStreamModule, Iq.Handler {
        public const string ID = "0030_service_discovery_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public ArrayList<Identity> identities = new ArrayList<Identity>();

        public Module.with_identity(string category, string type, string? name = null) {
            add_identity(category, type, name);
        }

        public void add_feature(XmppStream stream, string feature) {
            Flag.get_flag(stream).add_own_feature(feature);
        }

        public void add_feature_notify(XmppStream stream, string feature) {
            add_feature(stream, feature + "+notify");
        }

        public void add_identity(string category, string type, string? name = null) {
            identities.add(new Identity(category, type, name));
        }

        public void request_info(XmppStream stream, string jid, InfoResponseListener response_listener) {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_INFO).add_self_xmlns());
            iq.to = jid;
            Iq.Module.get_module(stream).send_iq(stream, iq, new IqInfoResponseListener(response_listener));
        }

        private class IqInfoResponseListener : Iq.ResponseListener, Object {
            InfoResponseListener response_listener;
            public IqInfoResponseListener(InfoResponseListener response_listener) {
                this.response_listener = response_listener;
            }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                InfoResult? result = InfoResult.create_from_iq(iq);
                if (result != null) {
                    Flag.get_flag(stream).set_entitiy_features(iq.from, result.features);
                    response_listener.on_result(stream, result);
                } else {
                    response_listener.on_error(stream, iq);
                }
            }
        }

        public void request_items(XmppStream stream, string jid, ItemsResponseListener response_listener) {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_ITEMS).add_self_xmlns());
            iq.to = jid;
            Iq.Module.get_module(stream).send_iq(stream, iq, new IqItemsResponseListener(response_listener));
        }

        private class IqItemsResponseListener : Iq.ResponseListener, Object {
            ItemsResponseListener response_listener;
            public IqItemsResponseListener(ItemsResponseListener response_listener) { this.response_listener = response_listener; }
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                //response_listener.on_result(stream, new ServiceDiscoveryItemsResult.from_iq(iq));
            }
        }

        public void on_iq_get(XmppStream stream, Iq.Stanza iq) {
            StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI_INFO);
            if (query_node != null) {
                send_query_result(stream, iq);
            }
        }

        public void on_iq_set(XmppStream stream, Iq.Stanza iq) { }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
            Iq.Module.get_module(stream).register_for_namespace(NS_URI_INFO, this);
            stream.add_flag(new Flag());
            add_feature(stream, NS_URI_INFO);
        }

        public override void detach(XmppStream stream) { }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(IDENTITY);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new ServiceDiscovery.Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }

        private void send_query_result(XmppStream stream, Iq.Stanza iq_request) {
            InfoResult query_result = new ServiceDiscovery.InfoResult(iq_request);
            query_result.features = Flag.get_flag(stream).features;
            query_result.identities = identities;
            Iq.Module.get_module(stream).send_iq(stream, query_result.iq, null);
        }
    }

    public class Identity {
        public string category { get; set; }
        public string type_ { get; set; }
        public string? name { get; set; }

        public Identity(string category, string type, string? name = null) {
            this.category = category;
            this.type_ = type;
            this.name = name;
        }
    }

    public class Item {
        public string jid;
        public string? name;
        public string? node;

        public Item(string jid, string? name = null, string? node = null) {
            this.jid = jid;
            this.name = name;
            this.node = node;
        }
    }

    public interface InfoResponseListener : Object {
        public abstract void on_result(XmppStream stream, InfoResult query_result);
        public void on_error(XmppStream stream, Iq.Stanza iq) { }
    }

    public interface ItemsResponseListener : Object {
        public abstract void on_result(XmppStream stream, ItemsResult query_result);
        public void on_error(XmppStream stream, Iq.Stanza iq) { }
    }
}
