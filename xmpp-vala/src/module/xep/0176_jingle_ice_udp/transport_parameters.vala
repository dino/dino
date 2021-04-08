using Gee;
using Xmpp.Xep;
using Xmpp;

public abstract class Xmpp.Xep.JingleIceUdp.IceUdpTransportParameters : Jingle.TransportParameters, Object {
    public string ns_uri { get { return NS_URI; } }
    public string remote_pwd { get; private set; }
    public string remote_ufrag { get; private set; }
    public string local_pwd { get; private set; }
    public string local_ufrag { get; private set; }

    public ConcurrentList<Candidate> local_candidates = new ConcurrentList<Candidate>(Candidate.equals_func);
    public ConcurrentList<Candidate> unsent_local_candidates = new ConcurrentList<Candidate>(Candidate.equals_func);
    public Gee.List<Candidate> remote_candidates = new ArrayList<Candidate>(Candidate.equals_func);

    public uint8[]? own_fingerprint = null;
    public uint8[]? peer_fingerprint = null;
    public string? peer_fp_algo = null;

    public Jid local_full_jid { get; private set; }
    public Jid peer_full_jid { get; private set; }
    private uint8 components_;
    public uint8 components { get { return components_; } }

    public bool incoming { get; private set; default = false; }
    private bool connection_created = false;

    protected weak Jingle.Content? content = null;

    protected IceUdpTransportParameters(uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode? node = null) {
        this.components_ = components;
        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
        if (node != null) {
            incoming = true;
            remote_pwd = node.get_attribute("pwd");
            remote_ufrag = node.get_attribute("ufrag");
            foreach (StanzaNode candidateNode in node.get_subnodes("candidate")) {
                remote_candidates.add(Candidate.parse(candidateNode));
            }

            StanzaNode? fingerprint_node = node.get_subnode("fingerprint", DTLS_NS_URI);
            if (fingerprint_node != null) {
                peer_fingerprint = fingerprint_to_bytes(fingerprint_node.get_deep_string_content());
                peer_fp_algo = fingerprint_node.get_attribute("hash");
            }
        }
    }

    public void init(string ufrag, string pwd) {
        this.local_ufrag = ufrag;
        this.local_pwd = pwd;
        debug("Initialized for %s", pwd);
    }

    public void set_content(Jingle.Content content) {
        this.content = content;
        this.content.weak_ref(unset_content);
    }

    public void unset_content() {
        this.content = null;
    }

    public StanzaNode to_transport_stanza_node() {
        var node = new StanzaNode.build("transport", NS_URI)
                .add_self_xmlns()
                .put_attribute("ufrag", local_ufrag)
                .put_attribute("pwd", local_pwd);

        if (own_fingerprint != null) {
            var fingerprint_node = new StanzaNode.build("fingerprint", DTLS_NS_URI)
                    .add_self_xmlns()
                    .put_attribute("hash", "sha-256")
                    .put_node(new StanzaNode.text(format_fingerprint(own_fingerprint)));
            if (incoming) {
                fingerprint_node.put_attribute("setup", "active");
            } else {
                fingerprint_node.put_attribute("setup", "actpass");
            }
            node.put_node(fingerprint_node);
        }

        foreach (Candidate candidate in unsent_local_candidates) {
            node.put_node(candidate.to_xml());
        }
        unsent_local_candidates.clear();
        return node;
    }

    public virtual void handle_transport_accept(StanzaNode node) throws Jingle.IqError {
        string? pwd = node.get_attribute("pwd");
        string? ufrag = node.get_attribute("ufrag");
        if (pwd != null) remote_pwd = pwd;
        if (ufrag != null) remote_ufrag = ufrag;
        foreach (StanzaNode candidateNode in node.get_subnodes("candidate")) {
            remote_candidates.add(Candidate.parse(candidateNode));
        }

        StanzaNode? fingerprint_node = node.get_subnode("fingerprint", DTLS_NS_URI);
        if (fingerprint_node != null) {
            peer_fingerprint = fingerprint_to_bytes(fingerprint_node.get_deep_string_content());
            peer_fp_algo = fingerprint_node.get_attribute("hash");
        }
    }

    public virtual void handle_transport_info(StanzaNode node) throws Jingle.IqError {
        string? pwd = node.get_attribute("pwd");
        string? ufrag = node.get_attribute("ufrag");
        if (pwd != null) remote_pwd = pwd;
        if (ufrag != null) remote_ufrag = ufrag;
        uint8 components = 0;
        foreach (StanzaNode candidateNode in node.get_subnodes("candidate")) {
            remote_candidates.add(Candidate.parse(candidateNode));
        }
    }

    public virtual void create_transport_connection(XmppStream stream, Jingle.Content content) {
        connection_created = true;

        check_send_transport_info();
    }

    public void add_local_candidate_threadsafe(Candidate candidate) {
        if (local_candidates.contains(candidate)) return;

        debug("New local candidate %u %s %s:%u", candidate.component, candidate.type_.to_string(), candidate.ip, candidate.port);
        unsent_local_candidates.add(candidate);
        local_candidates.add(candidate);

        if (this.content != null && (this.connection_created || !this.incoming)) {
            Timeout.add(50, () => {
                check_send_transport_info();
                return false;
            });
        }
    }

    private void check_send_transport_info() {
        if (this.content != null && unsent_local_candidates.size > 0) {
            content.send_transport_info(to_transport_stanza_node());
        }
    }



    private string format_fingerprint(uint8[] fingerprint) {
        var sb = new StringBuilder();
        for (int i = 0; i < fingerprint.length; i++) {
            sb.append("%02x".printf(fingerprint[i]));
            if (i < fingerprint.length - 1) {
                sb.append(":");
            }
        }
        return sb.str;
    }

    private uint8[] fingerprint_to_bytes(string? fingerprint_) {
        if (fingerprint_ == null) return null;

        string fingerprint = fingerprint_.replace(":", "").up();

        uint8[] bin = new uint8[fingerprint.length / 2];
        const string HEX = "0123456789ABCDEF";
        for (int i = 0; i < fingerprint.length / 2; i++) {
            bin[i] = (uint8) (HEX.index_of_char(fingerprint[i*2]) << 4) | HEX.index_of_char(fingerprint[i*2+1]);
        }
        return bin;
    }
}