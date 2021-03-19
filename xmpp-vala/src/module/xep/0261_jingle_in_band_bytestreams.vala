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
    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public async bool is_transport_available(XmppStream stream, uint8 components, Jid full_jid) {
        return components == 1 && yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
    }

    public string ns_uri { get { return NS_URI; } }
    public Jingle.TransportType type_ { get { return Jingle.TransportType.STREAMING; } }
    public int priority { get { return 0; } }
    public Jingle.TransportParameters create_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid) {
        assert(components == 1);
        return new Parameters.create(peer_full_jid, random_uuid());
    }
    public Jingle.TransportParameters parse_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
        return Parameters.parse(peer_full_jid, transport);
    }
}

class Parameters : Jingle.TransportParameters, Object {
    public string ns_uri { get { return NS_URI; } }
    public uint8 components { get { return 1; } }
    public Jingle.Role role { get; private set; }
    public Jid peer_full_jid { get; private set; }
    public string sid { get; private set; }
    public int block_size { get; private set; }

    private Parameters(Jingle.Role role, Jid peer_full_jid, string sid, int block_size) {
        this.role = role;
        this.peer_full_jid = peer_full_jid;
        this.sid = sid;
        this.block_size = block_size;
    }

    public Parameters.create(Jid peer_full_jid, string sid) {
        this(Jingle.Role.INITIATOR, peer_full_jid, sid, DEFAULT_BLOCKSIZE);
    }

    public static Parameters parse(Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
        string? sid = transport.get_attribute("sid");
        int block_size = transport.get_attribute_int("block-size");
        if (sid == null || block_size <= 0 || block_size > MAX_BLOCKSIZE) {
            throw new Jingle.IqError.BAD_REQUEST("missing or invalid sid or blocksize");
        }
        return new Parameters(Jingle.Role.RESPONDER, peer_full_jid, sid, block_size);
    }

    public string transport_ns_uri() {
        return NS_URI;
    }

    public void set_content(Jingle.Content content) {

    }

    public StanzaNode to_transport_stanza_node() {
        return new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("block-size", block_size.to_string())
            .put_attribute("sid", sid);
    }

    public void handle_transport_accept(StanzaNode transport) throws Jingle.IqError {
        Parameters other = Parameters.parse(peer_full_jid, transport);
        if (other.sid != sid || other.block_size > block_size) {
            throw new Jingle.IqError.NOT_ACCEPTABLE("invalid IBB sid or block_size");
        }
        block_size = other.block_size;
    }

    public void handle_transport_info(StanzaNode transport) throws Jingle.IqError {
        throw new Jingle.IqError.UNSUPPORTED_INFO("transport-info not supported for IBBs");
    }

    public void create_transport_connection(XmppStream stream, Jingle.Content content) {
        IOStream iostream = InBandBytestreams.Connection.create(stream, peer_full_jid, sid, block_size, role == Jingle.Role.INITIATOR);
        Jingle.StreamingConnection connection = new Jingle.StreamingConnection();
        if (content.security_params != null) {
            iostream = content.security_params.wrap_stream(iostream);
        }
        connection.init.begin(iostream);
        debug("set transport conn ibb");
        content.set_transport_connection(connection, 1);
    }
}

}
