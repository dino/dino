using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.Socks5Bytestreams {

internal const string NS_URI = "http://jabber.org/protocol/bytestreams";

public class Proxy : Object {
    public string host { get; private set; }
    public Jid jid { get; private set; }
    public int port { get; private set; }

    public Proxy(string host, Jid jid, int port) {
        this.host = host;
        this.jid = jid;
        this.port = port;
    }
}

public class Module : XmppStreamModule, Iq.Handler {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0065_socks5_bytestreams");

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        query_availability(stream);
    }
    public override void detach(XmppStream stream) { }

    public void on_iq_set(XmppStream stream, Iq.Stanza iq) { }

    public Gee.List<Proxy> get_proxies(XmppStream stream) {
        return stream.get_flag(Flag.IDENTITY).proxies;
    }

    private void query_availability(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).request_items(stream, stream.remote_name, (stream, items_result) => {
            foreach (Xep.ServiceDiscovery.Item item in items_result.items) {
                stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, item.jid, (stream, info_result) => {
                    foreach (string feature in info_result.features) {
                        if (feature == NS_URI) {
                            StanzaNode query_ = new StanzaNode.build("query", NS_URI).add_self_xmlns();
                            Iq.Stanza iq = new Iq.Stanza.get(query_) { to=item.jid };
                            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
                                if (iq.is_error()) {
                                    return;
                                }
                                StanzaNode? query = iq.stanza.get_subnode("query", NS_URI);
                                StanzaNode? stream_host = query != null ? query.get_subnode("streamhost", NS_URI) : null;
                                if (query == null || stream_host == null) {
                                    return;
                                }
                                string? host = stream_host.get_attribute("host");
                                string? jid_str = stream_host.get_attribute("jid");
                                Jid? jid = null;
                                try {
                                    jid = jid_str != null ? new Jid(jid_str) : null;
                                } catch (InvalidJidError ignored) {
                                }
                                int port = stream_host.get_attribute_int("port");
                                if (host == null || jid == null || port <= 0 || port > 65535) {
                                    return;
                                }
                                stream.get_flag(Flag.IDENTITY).proxies.add(new Proxy(host, jid, port));
                            });
                        }
                    }
                });
            }
        });
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "socks5_bytestreams");

    public Gee.List<Proxy> proxies = new ArrayList<Proxy>();

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}


}
