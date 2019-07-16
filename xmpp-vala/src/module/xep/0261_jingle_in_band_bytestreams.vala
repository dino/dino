using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleInBandBytestreams {

private const string NS_URI = "urn:xmpp:jingle:transports:ibb:1";
private const int DEFAULT_BLOCKSIZE = 4096;
private const int MAX_BLOCKSIZE = 65535;

public class Module : Jingle.Transport, XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0261_jingle_in_band_bytestreams");

    public override void attach(XmppStream stream) {
        stream.get_module(Jingle.Module.IDENTITY).register_transport(this);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
    }
    public override void detach(XmppStream stream) { }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public bool is_transport_available(XmppStream stream, Jid full_jid) {
        bool? result = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        return result != null && result;
    }

    public string transport_ns_uri() {
        return NS_URI;
    }
    public Jingle.TransportType transport_type() {
        return Jingle.TransportType.STREAMING;
    }
    public Jingle.TransportParameters create_transport_parameters() {
        return new Parameters(random_uuid(), DEFAULT_BLOCKSIZE);
    }
    public Jingle.TransportParameters parse_transport_parameters(StanzaNode transport) throws Jingle.IqError {
        return Parameters.parse(transport);
    }
}

class Parameters : Jingle.TransportParameters, Object {
    public string sid { get; private set; }
    public int block_size { get; private set; }
    public Parameters(string sid, int block_size) {
        this.sid = sid;
        this.block_size = block_size;
    }
    public static Parameters parse(StanzaNode transport) throws Jingle.IqError {
        string? sid = transport.get_attribute("sid");
        int block_size = transport.get_attribute_int("block-size");
        if (sid == null || block_size <= 0 || block_size > MAX_BLOCKSIZE) {
            throw new Jingle.IqError.BAD_REQUEST("missing or invalid sid or blocksize");
        }
        return new Parameters(sid, block_size);
    }
    public string transport_ns_uri() {
        return NS_URI;
    }
    public StanzaNode to_transport_stanza_node() {
        return new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("block-size", block_size.to_string())
            .put_attribute("sid", sid);
    }
    public void update_transport(StanzaNode transport) throws Jingle.IqError {
        Parameters other = Parameters.parse(transport);
        if (other.sid != sid || other.block_size > block_size) {
            throw new Jingle.IqError.NOT_ACCEPTABLE("invalid IBB sid or block_size");
        }
        block_size = other.block_size;
    }
    public IOStream create_transport_connection(XmppStream stream, Jid peer_full_jid, Jingle.Role role) {
        return InBandBytestreams.Connection.create(stream, peer_full_jid, sid, block_size, role == Jingle.Role.INITIATOR);
    }
}

}
