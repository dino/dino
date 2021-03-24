using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.JingleIceUdp {

private const string NS_URI = "urn:xmpp:jingle:transports:ice-udp:1";

public abstract class Module : XmppStreamModule, Jingle.Transport {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0176_jingle_ice_udp");

    public override void attach(XmppStream stream) {
        stream.get_module(Jingle.Module.IDENTITY).register_transport(this);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, "urn:xmpp:jingle:apps:dtls:0");
    }
    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public async bool is_transport_available(XmppStream stream, uint8 components, Jid full_jid) {
        return yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
    }

    public string ns_uri{ get { return NS_URI; } }
    public Jingle.TransportType type_{ get { return Jingle.TransportType.DATAGRAM; } }
    public int priority { get { return 1; } }

    public abstract Jingle.TransportParameters create_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid);

    public abstract Jingle.TransportParameters parse_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError;
}

}