using Gee;
using Xmpp;
using Xmpp.Xep;

public class Xmpp.Xep.JingleRtp.Parameters : Jingle.ContentParameters, Object {

    public signal void stream_created(Stream stream);
    public signal void connection_ready();

    public string media { get; private set; }
    public string? ssrc { get; private set; }
    public bool rtcp_mux { get; private set; }

    public string? bandwidth { get; private set; }
    public string? bandwidth_type { get; private set; }

    public bool encryption_required { get; private set; default = false; }
    public PayloadType? agreed_payload_type { get; private set; }
    public Gee.List<PayloadType> payload_types = new ArrayList<PayloadType>(PayloadType.equals_func);
    public Gee.List<Crypto> cryptos = new ArrayList<Crypto>();

    public weak Stream? stream { get; private set; }

    private Module parent;

    public Parameters(Module parent,
                      string media, Gee.List<PayloadType> payload_types,
                      string? ssrc = null, bool rtcp_mux = false,
                      string? bandwidth = null, string? bandwidth_type = null,
                      bool encryption_required = false, Gee.List<Crypto> cryptos = new ArrayList<Crypto>()
    ) {
        this.parent = parent;
        this.media = media;
        this.ssrc = ssrc;
        this.rtcp_mux = rtcp_mux;
        this.bandwidth = bandwidth;
        this.bandwidth_type = bandwidth_type;
        this.encryption_required = encryption_required;
        this.payload_types = payload_types;
        this.cryptos = cryptos;
    }

    public Parameters.from_node(Module parent, StanzaNode node) throws Jingle.IqError {
        this.parent = parent;
        this.media = node.get_attribute("media");
        this.ssrc = node.get_attribute("ssrc");
        this.rtcp_mux = node.get_subnode("rtcp-mux") != null;
        StanzaNode? encryption = node.get_subnode("encryption");
        if (encryption != null) {
            this.encryption_required = encryption.get_attribute_bool("required", this.encryption_required);
            foreach (StanzaNode crypto in encryption.get_subnodes("crypto")) {
                this.cryptos.add(Crypto.parse(crypto));
            }
        }
        foreach (StanzaNode payloadType in node.get_subnodes("payload-type")) {
            this.payload_types.add(PayloadType.parse(payloadType));
        }
    }

    public async void handle_proposed_content(XmppStream stream, Jingle.Session session, Jingle.Content content) {
        agreed_payload_type = yield parent.pick_payload_type(media, payload_types);
        if (agreed_payload_type == null) {
            debug("no usable payload type");
            content.reject();
            return;
        }
    }

    public void accept(XmppStream stream, Jingle.Session session, Jingle.Content content) {
        debug("[%p] Jingle RTP on_accept", stream);

        Jingle.DatagramConnection rtp_datagram = (Jingle.DatagramConnection) content.get_transport_connection(1);
        Jingle.DatagramConnection rtcp_datagram = (Jingle.DatagramConnection) content.get_transport_connection(2);

        ulong rtcp_ready_handler_id = 0;
        rtcp_ready_handler_id = rtcp_datagram.notify["ready"].connect(() => {
            this.stream.on_rtcp_ready();

            rtcp_datagram.disconnect(rtcp_ready_handler_id);
            rtcp_ready_handler_id = 0;
        });

        ulong rtp_ready_handler_id = 0;
        rtp_ready_handler_id = rtp_datagram.notify["ready"].connect(() => {
            this.stream.on_rtp_ready();
            connection_ready();

            rtp_datagram.disconnect(rtp_ready_handler_id);
            rtp_ready_handler_id = 0;
        });

        session.notify["state"].connect((obj, _) => {
            Jingle.Session session2 = (Jingle.Session) obj;
            if (session2.state == Jingle.Session.State.ENDED) {
                if (rtcp_ready_handler_id != 0) rtcp_datagram.disconnect(rtcp_ready_handler_id);
                if (rtp_ready_handler_id != 0) rtp_datagram.disconnect(rtp_ready_handler_id);
            }
        });

        this.stream = parent.create_stream(content);
        rtp_datagram.datagram_received.connect(this.stream.on_recv_rtp_data);
        rtcp_datagram.datagram_received.connect(this.stream.on_recv_rtcp_data);
        this.stream.on_send_rtp_data.connect(rtp_datagram.send_datagram);
        this.stream.on_send_rtcp_data.connect(rtcp_datagram.send_datagram);
        this.stream_created(this.stream);
        this.stream.create();
    }

    public void handle_accept(XmppStream stream, Jingle.Session session, Jingle.Content content, StanzaNode description_node) {
        Gee.List<StanzaNode> payload_type_nodes = description_node.get_subnodes("payload-type");
        if (payload_type_nodes.size == 0) {
            warning("Counterpart didn't include any payload types");
            return;
        }
        PayloadType preferred_payload_type = PayloadType.parse(payload_type_nodes[0]);
        if (!payload_types.contains(preferred_payload_type)) {
            warning("Counterpart's preferred content type doesn't match any of our sent ones");
        }
        agreed_payload_type = preferred_payload_type;

        accept(stream, session, content);
    }

    public void terminate(bool we_terminated, string? reason_name, string? reason_text) {
        if (stream != null) parent.close_stream(stream);
    }

    public StanzaNode get_description_node() {
        StanzaNode ret = new StanzaNode.build("description", NS_URI)
                .add_self_xmlns()
                .put_attribute("media", media);

        if (agreed_payload_type != null) {
            ret.put_node(agreed_payload_type.to_xml());
        } else {
            foreach (PayloadType payload_type in payload_types) {
                ret.put_node(payload_type.to_xml());
            }
        }
        return ret;
    }
}