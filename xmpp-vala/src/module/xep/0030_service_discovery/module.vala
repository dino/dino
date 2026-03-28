using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

public const string NS_URI = "http://jabber.org/protocol/disco";
public const string NS_URI_INFO = NS_URI + "#info";
public const string NS_URI_ITEMS = NS_URI + "#items";

public class Module : XmppStreamModule, Iq.Handler {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0030_service_discovery_module");

    private HashMap<Jid, Future<InfoResult?>> active_info_requests = new HashMap<Jid, Future<InfoResult?>>(Jid.hash_func, Jid.equals_func);

    public Identity own_identity;
    public CapsCache cache;

    public Module.with_identity(string category, string type, string? name = null) {
        this.own_identity = new Identity(category, type, name);
    }

    public void add_feature(XmppStream stream, string feature) {
        stream.get_flag(Flag.IDENTITY).add_own_feature(feature);
    }

    public void remove_feature(XmppStream stream, string feature) {
        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag != null) {
                flag.remove_own_feature(feature);
        }
    }

    public void add_feature_notify(XmppStream stream, string feature) {
        add_feature(stream, feature + "+notify");
    }

    public void remove_feature_notify(XmppStream stream, string feature) {
        remove_feature(stream, feature + "+notify");
    }

    public async bool has_entity_feature(XmppStream stream, Jid jid, string feature) {
        return yield this.cache.has_entity_feature(jid, feature);
    }

    public async Gee.Set<Identity>? get_entity_identities(XmppStream stream, Jid jid) {
        return yield this.cache.get_entity_identities(jid);
    }

    public async InfoResult? request_info(XmppStream stream, Jid jid) {
        var future = active_info_requests[jid];
        if (future == null) {
            var promise = new Promise<InfoResult?>();
            future = promise.future;
            active_info_requests[jid] = future;

            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_INFO).add_self_xmlns()) { to=jid };
            Iq.Stanza iq_response = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
            InfoResult? result = InfoResult.create_from_iq(iq_response);

            promise.set_value(result);
            active_info_requests.unset(jid);
        }

        try {
            InfoResult? res = yield future.wait_async();
            return res;
        } catch (FutureError error) {
            warning("Future error when waiting for info request result: %s", error.message);
            return null;
        }
    }

    public async ItemsResult? request_items(XmppStream stream, Jid jid) {
        StanzaNode query_node = new StanzaNode.build("query", NS_URI_ITEMS).add_self_xmlns();
        Iq.Stanza iq = new Iq.Stanza.get(query_node) { to=jid };

        Iq.Stanza iq_result = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
        ItemsResult? result = ItemsResult.create_from_iq(iq_result);

        return result;
    }

    public async void on_iq_get(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI_INFO);
        if (query_node != null) {
            send_query_result(stream, iq);
        }
    }

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_flag(Flag.IDENTITY).add_own_identity(own_identity);

        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI_INFO, this);
        add_feature(stream, NS_URI_INFO);
    }

    public override void detach(XmppStream stream) {
        active_info_requests.clear();

        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag != null) flag.remove_own_identity(own_identity);

        stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI_INFO, this);
        remove_feature(stream, NS_URI_INFO);
    }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stream.add_module(new ServiceDiscovery.Module());
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void send_query_result(XmppStream stream, Iq.Stanza iq_request) {
        InfoResult query_result = new ServiceDiscovery.InfoResult(iq_request);
        query_result.features = stream.get_flag(Flag.IDENTITY).own_features;
        query_result.identities = stream.get_flag(Flag.IDENTITY).own_identities;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, query_result.iq);
    }
}

public interface CapsCache : Object {
    public abstract async bool has_entity_feature(Jid jid, string feature);
    public abstract async Gee.Set<Identity> get_entity_identities(Jid jid);
}

}
