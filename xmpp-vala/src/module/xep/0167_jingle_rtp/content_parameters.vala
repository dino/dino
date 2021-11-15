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
    public Gee.List<HeaderExtension> header_extensions = new ArrayList<HeaderExtension>();
    public Gee.List<Crypto> remote_cryptos = new ArrayList<Crypto>();
    public Crypto? local_crypto = null;
    public Crypto? remote_crypto = null;
    public Jid? muji_muc = null;

    public bool rtp_ready { get; private set; default=false; }
    public bool rtcp_ready { get; private set; default=false; }

    public weak Stream? stream { get; private set; }

    private Module parent;

    public Parameters(Module parent,
                      string media, Gee.List<PayloadType> payload_types,
                      Jid? muji_muc,
                      string? ssrc = null, bool rtcp_mux = false,
                      string? bandwidth = null, string? bandwidth_type = null,
                      bool encryption_required = false, Crypto? local_crypto = null
    ) {
        this.parent = parent;
        this.media = media;
        this.ssrc = ssrc;
        this.rtcp_mux = true;
        this.bandwidth = bandwidth;
        this.bandwidth_type = bandwidth_type;
        this.encryption_required = encryption_required;
        this.payload_types = payload_types;
        this.local_crypto = local_crypto;
        this.muji_muc = muji_muc;
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
                this.remote_cryptos.add(Crypto.parse(crypto));
            }
        }
        foreach (StanzaNode payloadType in node.get_subnodes(PayloadType.NAME)) {
            this.payload_types.add(PayloadType.parse(payloadType));
        }
        foreach (StanzaNode subnode in node.get_subnodes(HeaderExtension.NAME, HeaderExtension.NS_URI)) {
            this.header_extensions.add(HeaderExtension.parse(subnode));
        }
        string? muji_muc_str = node.get_deep_attribute(Xep.Muji.NS_URI + ":muji", "muc");
        if (muji_muc_str != null) {
            muji_muc = new Jid(muji_muc_str);
        }
    }

    public async void handle_proposed_content(XmppStream stream, Jingle.Session session, Jingle.Content content) {
        agreed_payload_type = yield parent.pick_payload_type(media, payload_types);
        if (agreed_payload_type == null) {
            debug("no usable payload type");
            content.reject();
            return;
        }
        // Drop unsupported header extensions
        var iter = header_extensions.iterator();
        while(iter.next()) {
            if (!parent.is_header_extension_supported(media, iter.@get())) iter.remove();
        }
        remote_crypto = parent.pick_remote_crypto(remote_cryptos);
        if (local_crypto == null && remote_crypto != null) {
            local_crypto = parent.pick_local_crypto(remote_crypto);
        }
        if ((local_crypto == null || remote_crypto == null) && encryption_required) {
            debug("no usable encryption, but encryption required");
            content.reject();
            return;
        }
    }

    public void accept(XmppStream stream, Jingle.Session session, Jingle.Content content) {
        debug("[%p] Jingle RTP on_accept", stream);

        Jingle.DatagramConnection rtp_datagram = (Jingle.DatagramConnection) content.get_transport_connection(1);
        Jingle.DatagramConnection rtcp_datagram = (Jingle.DatagramConnection) content.get_transport_connection(2);

        ulong rtcp_ready_handler_id = 0;
        rtcp_ready_handler_id = rtcp_datagram.notify["ready"].connect((rtcp_datagram, _) => {
            this.stream.on_rtcp_ready();
            this.rtcp_ready = true;

            ((Jingle.DatagramConnection)rtcp_datagram).disconnect(rtcp_ready_handler_id);
            rtcp_ready_handler_id = 0;
        });

        ulong rtp_ready_handler_id = 0;
        rtp_ready_handler_id = rtp_datagram.notify["ready"].connect((rtp_datagram, _) => {
            this.stream.on_rtp_ready();
            this.rtp_ready = true;
            if (rtcp_mux) {
                this.stream.on_rtcp_ready();
                this.rtcp_ready = true;
            }
            connection_ready();

            ((Jingle.DatagramConnection)rtp_datagram).disconnect(rtp_ready_handler_id);
            rtp_ready_handler_id = 0;
        });

        ulong session_state_handler_id = 0;
        session_state_handler_id = session.notify["state"].connect((obj, _) => {
            Jingle.Session session2 = (Jingle.Session) obj;
            if (session2.state == Jingle.Session.State.ENDED) {
                if (rtcp_ready_handler_id != 0) rtcp_datagram.disconnect(rtcp_ready_handler_id);
                if (rtp_ready_handler_id != 0) rtp_datagram.disconnect(rtp_ready_handler_id);
                if (session_state_handler_id != 0) {
                    session2.disconnect(session_state_handler_id);
                }
            }
        });

        if (remote_crypto == null || local_crypto == null) {
            if (encryption_required) {
                warning("Encryption required but not provided in both directions");
                return;
            }
            remote_crypto = null;
            local_crypto = null;
        }
        if (remote_crypto != null && local_crypto != null) {
            var content_encryption = new Xmpp.Xep.Jingle.ContentEncryption("", "SRTP", local_crypto.key, remote_crypto.key);
            content.encryptions[content_encryption.encryption_name] = content_encryption;
        }

        this.stream = parent.create_stream(content);
        this.stream.weak_ref(() => this.stream = null);
        rtp_datagram.datagram_received.connect(this.stream.on_recv_rtp_data);
        rtcp_datagram.datagram_received.connect(this.stream.on_recv_rtcp_data);
        this.stream.on_send_rtp_data.connect(rtp_datagram.send_datagram);
        this.stream.on_send_rtcp_data.connect(rtcp_datagram.send_datagram);
        this.stream_created(this.stream);
        this.stream.create();
    }

    public void handle_accept(XmppStream stream, Jingle.Session session, Jingle.Content content, StanzaNode description_node) {
        rtcp_mux = description_node.get_subnode("rtcp-mux") != null;
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

        Gee.List<StanzaNode> crypto_nodes = description_node.get_deep_subnodes("encryption", "crypto");
        if (crypto_nodes.size == 0) {
            debug("Counterpart didn't include any cryptos");
            if (encryption_required) {
                return;
            }
        } else {
            Crypto preferred_crypto = Crypto.parse(crypto_nodes[0]);
            if (local_crypto.crypto_suite != preferred_crypto.crypto_suite) {
                warning("Counterpart's crypto suite doesn't match any of our sent ones");
            }
            remote_crypto = preferred_crypto;
        }

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
        foreach (HeaderExtension ext in header_extensions) {
            ret.put_node(ext.to_xml());
        }
        if (local_crypto != null) {
            ret.put_node(new StanzaNode.build("encryption", NS_URI)
                .put_node(local_crypto.to_xml()));
        }
        if (rtcp_mux) {
            ret.put_node(new StanzaNode.build("rtcp-mux", NS_URI));
        }
        if (muji_muc != null) {
            ret.put_node(new StanzaNode.build("muji", Xep.Muji.NS_URI).add_self_xmlns().put_attribute("muc", muji_muc.to_string()));
        }
        return ret;
    }
}

public class Xmpp.Xep.JingleRtp.HeaderExtension {
    public const string NS_URI = "urn:xmpp:jingle:apps:rtp:rtp-hdrext:0";
    public const string NAME = "rtp-hdrext";

    public uint8 id { get; private set; }
    public string uri { get; private set; }

    public HeaderExtension(uint8 id, string uri) {
        this.id = id;
        this.uri = uri;
    }

    public static HeaderExtension parse(StanzaNode node) {
        return new HeaderExtension((uint8) node.get_attribute_int("id"), node.get_attribute("uri"));
    }

    public StanzaNode to_xml() {
        return new StanzaNode.build(NAME, NS_URI)
                .add_self_xmlns()
                .put_attribute("id", id.to_string())
                .put_attribute("uri", uri);
    }
}