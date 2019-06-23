using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleInBandBytestreams {

private const string NS_URI = "urn:xmpp:jingle:transports:ibb:1";
private const int DEFAULT_BLOCKSIZE = 4096;

public class Module : Jingle.Transport, XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0261_jingle_in_band_bytestreams");

    public override void attach(XmppStream stream) {
        stream.get_module(Jingle.Module.IDENTITY).add_transport(stream, this);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
    }
    public override void detach(XmppStream stream) { }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    public bool is_transport_available(XmppStream stream, Jid full_jid) {
        bool? result = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        return result != null && result;
    }

    public Jingle.TransportType transport_type() {
        return Jingle.TransportType.STREAMING;
    }
    public StanzaNode to_transport_stanza_node() {
        return new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("block-size", DEFAULT_BLOCKSIZE.to_string())
            .put_attribute("sid", random_uuid());
    }

    public Jingle.Connection? create_transport_connection(XmppStream stream, Jid peer_full_jid, StanzaNode content) throws Jingle.CreateConnectionError {
        StanzaNode? transport = content.get_subnode("transport", NS_URI);
        if (transport == null) {
            return null;
        }
        string? sid = transport.get_attribute("sid");
        int block_size = transport.get_attribute_int("block-size");
        if (sid == null || block_size <= 0) {
            throw new Jingle.CreateConnectionError.BAD_REQUEST("Invalid IBB parameters");
        }
        if (block_size > DEFAULT_BLOCKSIZE) {
            throw new Jingle.CreateConnectionError.NOT_ACCEPTABLE("Invalid IBB parameters: peer increased block size");
        }
        return new Connection(peer_full_jid, new InBandBytestreams.Connection(peer_full_jid, sid, block_size));
    }
}

public class Connection : Jingle.Connection {
    InBandBytestreams.Connection inner;

    public Connection(Jid full_jid, InBandBytestreams.Connection inner) {
        base(full_jid);
        inner.on_error.connect((stream, error) => on_error(stream, new Jingle.Error.TRANSPORT_ERROR(error)));
        inner.on_data.connect((stream, data) => on_data(stream, data));
        inner.on_ready.connect((stream) => on_ready(stream));
        this.inner = inner;
    }

    public override void connect(XmppStream stream) {
        inner.connect(stream);
    }
    public override void send(XmppStream stream, uint8[] data) {
        inner.send(stream, data);
    }
    public override void close(XmppStream stream) {
        inner.close(stream);
    }
}

}
