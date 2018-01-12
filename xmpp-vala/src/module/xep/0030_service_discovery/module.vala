using Gee;

namespace Xmpp.Xep.ServiceDiscovery {

private const string NS_URI = "http://jabber.org/protocol/disco";
public const string NS_URI_INFO = NS_URI + "#info";
public const string NS_URI_ITEMS = NS_URI + "#items";

public class Module : XmppStreamModule, Iq.Handler {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0030_service_discovery_module");

    public ArrayList<Identity> identities = new ArrayList<Identity>();

    public Module.with_identity(string category, string type, string? name = null) {
        add_identity(category, type, name);
    }

    public void add_feature(XmppStream stream, string feature) {
        stream.get_flag(Flag.IDENTITY).add_own_feature(feature);
    }

    public void add_feature_notify(XmppStream stream, string feature) {
        add_feature(stream, feature + "+notify");
    }

    public void add_identity(string category, string type, string? name = null) {
        identities.add(new Identity(category, type, name));
    }

    public delegate void HasEntryCategoryRes(XmppStream stream, Gee.List<Identity>? identities);
    public void get_entity_categories(XmppStream stream, Jid jid, owned HasEntryCategoryRes listener) {
        Gee.List<Identity>? res = stream.get_flag(Flag.IDENTITY).get_entity_categories(jid);
        if (res != null) listener(stream, res);
        request_info(stream, jid, (stream, query_result) => {
            listener(stream, query_result != null ? query_result.identities : null);
        });
    }

    public delegate void OnInfoResult(XmppStream stream, InfoResult? query_result);
    public void request_info(XmppStream stream, Jid jid, owned OnInfoResult listener) {
        Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_INFO).add_self_xmlns());
        iq.to = jid;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            InfoResult? result = InfoResult.create_from_iq(iq);
            stream.get_flag(Flag.IDENTITY).set_entity_features(iq.from, result != null ? result.features : null);
            stream.get_flag(Flag.IDENTITY).set_entity_identities(iq.from, result != null ? result.identities : null);
            listener(stream, result);
        });
    }

    public delegate void OnItemsResult(XmppStream stream, ItemsResult query_result);
    public void request_items(XmppStream stream, Jid jid, owned OnItemsResult listener) {
        Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("query", NS_URI_ITEMS).add_self_xmlns());
        iq.to = jid;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            ItemsResult? result = ItemsResult.create_from_iq(iq);
            stream.get_flag(Flag.IDENTITY).set_entity_items(iq.from, result != null ? result.items : null);
            listener(stream, result);
        });
    }

    public void on_iq_get(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI_INFO);
        if (query_node != null) {
            send_query_result(stream, iq);
        }
    }

    public void on_iq_set(XmppStream stream, Iq.Stanza iq) { }

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI_INFO, this);
        add_feature(stream, NS_URI_INFO);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI_INFO, this);
    }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stream.add_module(new ServiceDiscovery.Module());
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void send_query_result(XmppStream stream, Iq.Stanza iq_request) {
        InfoResult query_result = new ServiceDiscovery.InfoResult(iq_request);
        query_result.features = stream.get_flag(Flag.IDENTITY).features;
        query_result.identities = identities;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, query_result.iq);
    }
}

}
