using Gee;
using Xmpp;
using Xmpp.Xep;

public class Xmpp.Xep.JingleRtp.ContentType : Jingle.ContentType, Object {
    public string ns_uri { get { return NS_URI; } }
    public Jingle.TransportType required_transport_type { get { return Jingle.TransportType.DATAGRAM; } }
    public uint8 required_components { get { return 2; /* RTP + RTCP */ } }

    private Module module;

    public ContentType(Module module) {
        this.module = module;
    }

    public Jingle.ContentParameters parse_content_parameters(StanzaNode description) throws Jingle.IqError {
        return new Parameters.from_node(module, description);
    }

    public Jingle.ContentParameters create_content_parameters(Object object) throws Jingle.IqError {
        assert_not_reached();
    }
}