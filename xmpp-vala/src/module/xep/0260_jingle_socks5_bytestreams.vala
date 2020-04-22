using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleSocks5Bytestreams {

private const string NS_URI = "urn:xmpp:jingle:transports:s5b:1";

public class Module : Jingle.Transport, XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0260_jingle_socks5_bytestreams");

    public override void attach(XmppStream stream) {
        stream.get_module(Jingle.Module.IDENTITY).register_transport(this);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
    }
    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

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
    public int transport_priority() {
        return 1;
    }
    private Gee.List<Candidate> get_local_candidates(XmppStream stream) {
        Gee.List<Candidate> result = new ArrayList<Candidate>();
        int i = 1 << 15;
        foreach (Socks5Bytestreams.Proxy proxy in stream.get_module(Socks5Bytestreams.Module.IDENTITY).get_proxies(stream)) {
            result.add(new Candidate.proxy(random_uuid(), proxy, i));
            i -= 1;
        }
        return result;
    }
    public Jingle.TransportParameters create_transport_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid) {
        Parameters result = new Parameters.create(local_full_jid, peer_full_jid, random_uuid());
        result.local_candidates.add_all(get_local_candidates(stream));
        return result;
    }
    public Jingle.TransportParameters parse_transport_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
        Parameters result = Parameters.parse(local_full_jid, peer_full_jid, transport);
        result.local_candidates.add_all(get_local_candidates(stream));
        return result;
    }
}

public enum CandidateType {
    ASSISTED,
    DIRECT,
    PROXY,
    TUNNEL;

    public static CandidateType parse(string type) throws Jingle.IqError {
        switch (type) {
            case "assisted": return CandidateType.ASSISTED;
            case "direct": return CandidateType.DIRECT;
            case "proxy": return CandidateType.PROXY;
            case "tunnel": return CandidateType.TUNNEL;
        }
        throw new Jingle.IqError.BAD_REQUEST(@"unknown candidate type $(type)");
    }

    public string to_string() {
        switch (this) {
            case ASSISTED: return "assisted";
            case DIRECT: return "direct";
            case PROXY: return "proxy";
            case TUNNEL: return "tunnel";
        }
        assert_not_reached();
    }

    private int type_preference_impl() {
        switch (this) {
            case ASSISTED: return 120;
            case DIRECT: return 126;
            case PROXY: return 10;
            case TUNNEL: return 110;
        }
        assert_not_reached();
    }
    public int type_preference() {
        return type_preference_impl() << 16;
    }
}

public class Candidate : Socks5Bytestreams.Proxy {
    public string cid { get; private set; }
    public int priority { get; private set; }
    public CandidateType type_ { get; private set; }

    private Candidate(string cid, string host, Jid jid, int port, int priority, CandidateType type) {
        base(host, jid, port);
        this.cid = cid;
        this.priority = priority;
        this.type_ = type;
    }

    public Candidate.build(string cid, string host, Jid jid, int port, int local_priority, CandidateType type) {
        this(cid, host, jid, port, type.type_preference() + local_priority, type);
    }
    public Candidate.proxy(string cid, Socks5Bytestreams.Proxy proxy, int local_priority) {
        this.build(cid, proxy.host, proxy.jid, proxy.port, local_priority, CandidateType.PROXY);
    }

    public static Candidate parse(StanzaNode candidate) throws Jingle.IqError {
        string? cid = candidate.get_attribute("cid");
        string? host = candidate.get_attribute("host");
        string? jid_str = candidate.get_attribute("jid");
        Jid? jid = null;
        try {
            jid = new Jid(jid_str);
        } catch (InvalidJidError ignored) {
        }
        int port = candidate.get_attribute("port") != null ? candidate.get_attribute_int("port") : 1080;
        int priority = candidate.get_attribute_int("priority");
        string? type_str = candidate.get_attribute("type");
        CandidateType type = type_str != null ? CandidateType.parse(type_str) : CandidateType.DIRECT;

        if (cid == null || host == null || jid == null || port <= 0 || priority <= 0) {
            throw new Jingle.IqError.BAD_REQUEST("missing or invalid cid, host, jid or port");
        }

        return new Candidate(cid, host, jid, port, priority, type);
    }
    public StanzaNode to_xml() {
        return new StanzaNode.build("candidate", NS_URI)
            .put_attribute("cid", cid)
            .put_attribute("host", host)
            .put_attribute("jid", jid.to_string())
            .put_attribute("port", port.to_string())
            .put_attribute("priority", priority.to_string())
            .put_attribute("type", type_.to_string());
    }
}

bool bytes_equal(uint8[] a, uint8[] b) {
    if (a.length != b.length) {
        return false;
    }
    for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

class Parameters : Jingle.TransportParameters, Object {
    public Jingle.Role role { get; private set; }
    public string sid { get; private set; }
    public string remote_dstaddr { get; private set; }
    public string local_dstaddr { get; private set; }
    public Gee.List<Candidate> local_candidates = new ArrayList<Candidate>();
    public Gee.List<Candidate> remote_candidates = new ArrayList<Candidate>();

    Jid local_full_jid;
    Jid peer_full_jid;

    bool remote_sent_selected_candidate = false;
    Candidate? remote_selected_candidate = null;
    bool local_determined_selected_candidate = false;
    Candidate? local_selected_candidate = null;
    SocketConnection? local_selected_candidate_conn = null;
    weak Jingle.Session? session = null;
    XmppStream? hack = null;

    string? waiting_for_activation_cid = null;
    SourceFunc waiting_for_activation_callback;
    bool waiting_for_activation_error = false;

    private static string calculate_dstaddr(string sid, Jid first_jid, Jid second_jid) {
        string hashed = sid + first_jid.to_string() + second_jid.to_string();
        return Checksum.compute_for_string(ChecksumType.SHA1, hashed);
    }
    private Parameters(Jingle.Role role, string sid, Jid local_full_jid, Jid peer_full_jid, string? remote_dstaddr) {
        this.role = role;
        this.sid = sid;
        this.local_dstaddr = calculate_dstaddr(sid, local_full_jid, peer_full_jid);
        this.remote_dstaddr = remote_dstaddr ?? calculate_dstaddr(sid, peer_full_jid, local_full_jid);

        this.local_full_jid = local_full_jid;
        this.peer_full_jid = peer_full_jid;
    }
    public Parameters.create(Jid local_full_jid, Jid peer_full_jid, string sid) {
        this(Jingle.Role.INITIATOR, sid, local_full_jid, peer_full_jid, null);
    }
    public static Parameters parse(Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
        string? dstaddr = transport.get_attribute("dstaddr");
        string? mode = transport.get_attribute("mode");
        string? sid = transport.get_attribute("sid");
        if (mode != null && mode != "tcp") {
            throw new Jingle.IqError.BAD_REQUEST(@"unknown transport method $(mode)");
        }
        if (dstaddr != null && dstaddr.length > 255) {
            throw new Jingle.IqError.BAD_REQUEST("too long dstaddr");
        }
        Parameters result = new Parameters(Jingle.Role.RESPONDER, sid, local_full_jid, peer_full_jid, dstaddr);
        foreach (StanzaNode candidate in transport.get_subnodes("candidate", NS_URI)) {
            result.remote_candidates.add(Candidate.parse(candidate));
        }
        return result;
    }
    public string transport_ns_uri() {
        return NS_URI;
    }
    public StanzaNode to_transport_stanza_node() {
        StanzaNode transport = new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("dstaddr", local_dstaddr);

        if (role == Jingle.Role.INITIATOR) {
            // Must not be included by the responder according to XEP-0260.
            transport.put_attribute("mode", "tcp");
        }

        transport.put_attribute("sid", sid);
        foreach (Candidate candidate in local_candidates) {
            transport.put_node(candidate.to_xml());
        }
        return transport;
    }
    public void on_transport_accept(StanzaNode transport) throws Jingle.IqError {
        Parameters other = Parameters.parse(local_full_jid, peer_full_jid, transport);
        if (other.sid != sid) {
            throw new Jingle.IqError.BAD_REQUEST("invalid sid");
        }
        remote_candidates = other.remote_candidates;
        remote_dstaddr = other.remote_dstaddr;
    }
    public void on_transport_info(StanzaNode transport) throws Jingle.IqError {
        StanzaNode? candidate_error = transport.get_subnode("candidate-error", NS_URI);
        StanzaNode? candidate_used = transport.get_subnode("candidate-used", NS_URI);
        StanzaNode? activated = transport.get_subnode("activated", NS_URI);
        StanzaNode? proxy_error = transport.get_subnode("proxy-error", NS_URI);
        int num_children = 0;
        if (candidate_error != null) { num_children += 1; }
        if (candidate_used != null) { num_children += 1; }
        if (activated != null) { num_children += 1; }
        if (proxy_error != null) { num_children += 1; }
        if (num_children == 0) {
            throw new Jingle.IqError.UNSUPPORTED_INFO("unknown transport-info");
        } else if (num_children > 1) {
            throw new Jingle.IqError.BAD_REQUEST("transport-info with more than one child");
        }
        if (candidate_error != null) {
            handle_remote_candidate(null);
        }
        if (candidate_used != null) {
            string? cid = candidate_used.get_attribute("cid");
            if (cid == null) {
                throw new Jingle.IqError.BAD_REQUEST("missing cid");
            }
            handle_remote_candidate(cid);
        }
        if (activated != null) {
            string? cid = activated.get_attribute("cid");
            if (cid == null) {
                throw new Jingle.IqError.BAD_REQUEST("missing cid");
            }
            handle_activated(cid);
        }
        if (proxy_error != null) {
            handle_proxy_error();
        }
    }
    private void handle_remote_candidate(string? cid) throws Jingle.IqError {
        if (remote_sent_selected_candidate) {
            throw new Jingle.IqError.BAD_REQUEST("remote candidate already specified");
        }
        Candidate? candidate = null;
        if (cid != null) {
            foreach (Candidate c in local_candidates) {
                if (c.cid == cid) {
                    candidate = c;
                    break;
                }
            }
            if (candidate == null) {
                throw new Jingle.IqError.BAD_REQUEST("unknown cid");
            }
        }
        remote_sent_selected_candidate = true;
        remote_selected_candidate = candidate;
        debug("Remote selected candidate %s", candidate.cid);
        try_completing_negotiation();
    }
    private void handle_activated(string cid) throws Jingle.IqError {
        if (waiting_for_activation_cid == null || cid != waiting_for_activation_cid) {
            throw new Jingle.IqError.BAD_REQUEST("unexpected proxy activation message");
        }
        Idle.add((owned)waiting_for_activation_callback);
        waiting_for_activation_cid = null;
    }
    private void handle_proxy_error() throws Jingle.IqError {
        if (waiting_for_activation_cid == null) {
            throw new Jingle.IqError.BAD_REQUEST("unexpected proxy error message");
        }
        Idle.add((owned)waiting_for_activation_callback);
        waiting_for_activation_cid = null;
        waiting_for_activation_error = true;

    }
    private void try_completing_negotiation() {
        if (!remote_sent_selected_candidate || !local_determined_selected_candidate) {
            return;
        }

        Candidate? remote = remote_selected_candidate;
        Candidate? local = local_selected_candidate;

        int num_candidates = 0;
        if (remote != null) { num_candidates += 1; }
        if (local != null) { num_candidates += 1; }

        if (num_candidates == 0) {
            // Notify Jingle of the failed transport.
            session.set_transport_connection(hack, null);
            return;
        }

        bool remote_wins;
        if (num_candidates == 1) {
            remote_wins = remote != null;
        } else {
            if (local.priority < remote.priority) {
                remote_wins = true;
            } else if (local.priority > remote.priority) {
                remote_wins = false;
            } else {
                // equal priority -> XEP-0260 says that the candidate offered
                // by the initiator wins, so the one that the remote chose
                remote_wins = role == Jingle.Role.INITIATOR;
            }
        }

        if (!remote_wins) {
            if (local_selected_candidate.type_ != CandidateType.PROXY) {
                Jingle.Session? strong = session;
                if (strong == null) {
                    return;
                }
                strong.set_transport_connection(hack, local_selected_candidate_conn);
            } else {
                wait_for_remote_activation.begin(local_selected_candidate, local_selected_candidate_conn);
            }
        } else {
            connect_to_local_candidate.begin(remote_selected_candidate);
        }
    }
    public async void wait_for_remote_activation(Candidate candidate, SocketConnection conn) {
        debug("Waiting for remote activation of %s", candidate.cid);
        waiting_for_activation_cid = candidate.cid;
        waiting_for_activation_callback = wait_for_remote_activation.callback;
        yield;

        Jingle.Session? strong = session;
        if (strong == null) {
            return;
        }
        if (!waiting_for_activation_error) {
            strong.set_transport_connection(hack, conn);
        } else {
            strong.set_transport_connection(hack, null);
        }
    }
    public async void connect_to_local_candidate(Candidate candidate) {
        debug("Connecting to candidate %s", candidate.cid);
        try {
            SocketConnection conn = yield connect_to_socks5(candidate, local_dstaddr);

            bool activation_error = false;
            SourceFunc callback = connect_to_local_candidate.callback;
            StanzaNode query = new StanzaNode.build("query", Socks5Bytestreams.NS_URI)
                .add_self_xmlns()
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("activate", Socks5Bytestreams.NS_URI)
                    .put_node(new StanzaNode.text(peer_full_jid.to_string()))
                );
            Iq.Stanza iq = new Iq.Stanza.set(query) { to=candidate.jid };
            hack.get_module(Iq.Module.IDENTITY).send_iq(hack, iq, (stream, iq) => {
                activation_error = iq.is_error();
                Idle.add((owned)callback);
            });
            yield;

            if (activation_error) {
                throw new IOError.PROXY_FAILED("activation iq error");
            }

            Jingle.Session? strong = session;
            if (strong == null) {
                return;
            }
            strong.send_transport_info(hack, new StanzaNode.build("transport", NS_URI)
                .add_self_xmlns()
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("activated", NS_URI)
                    .put_attribute("cid", candidate.cid)
                )
            );

            strong.set_transport_connection(hack, conn);
        } catch (Error e) {
            Jingle.Session? strong = session;
            if (strong == null) {
                return;
            }
            strong.send_transport_info(hack, new StanzaNode.build("transport", NS_URI)
                .add_self_xmlns()
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("proxy-error", NS_URI))
            );
            strong.set_transport_connection(hack, null);
        }
    }
    public async SocketConnection connect_to_socks5(Candidate candidate, string dstaddr) throws Error {
        SocketClient socket_client = new SocketClient() { timeout=3 };

        string address = @"[$(candidate.host)]:$(candidate.port)";
        debug("Connecting to SOCKS5 server at %s", address);

        size_t written;
        size_t read;
        uint8[] read_buffer = new uint8[1024];
        ByteArray write_buffer = new ByteArray();

        SocketConnection conn = yield socket_client.connect_to_host_async(address, 0);

        // 05 SOCKS version 5
        // 01 number of authentication methods: 1
        // 00 nop authentication
        yield conn.output_stream.write_all_async({0x05, 0x01, 0x00}, GLib.Priority.DEFAULT, null, out written);

        yield conn.input_stream.read_all_async(read_buffer[0:2], GLib.Priority.DEFAULT, null, out read);
        // 05 SOCKS version 5
        // 01 success
        if (read_buffer[0] != 0x05 || read_buffer[1] != 0x00) {
            throw new IOError.PROXY_FAILED("wanted 05 00, got %02x %02x".printf(read_buffer[0], read_buffer[1]));
        }

        // 05 SOCKS version 5
        // 01 connect
        // 00 reserved
        // 03 address type: domain name
        // ?? length of the domain
        // .. domain
        // 00 port 0 (upper half)
        // 00 port 0 (lower half)
        write_buffer.append({0x05, 0x01, 0x00, 0x03});
        write_buffer.append({(uint8)dstaddr.length});
        write_buffer.append(dstaddr.data);
        write_buffer.append({0x00, 0x00});
        yield conn.output_stream.write_all_async(write_buffer.data, GLib.Priority.DEFAULT, null, out written);

        yield conn.input_stream.read_all_async(read_buffer[0:write_buffer.len], GLib.Priority.DEFAULT, null, out read);
        // 05 SOCKS version 5
        // 00 success
        // 00 reserved
        // 03 address type: domain name
        // ?? length of the domain
        // .. domain
        // 00 port 0 (upper half)
        // 00 port 0 (lower half)
        if (read_buffer[0] != 0x05 || read_buffer[1] != 0x00 || read_buffer[3] != 0x03) {
            throw new IOError.PROXY_FAILED("wanted 05 00 ?? 03, got %02x %02x %02x %02x".printf(read_buffer[0], read_buffer[1], read_buffer[2], read_buffer[3]));
        }
        if (read_buffer[4] != (uint8)dstaddr.length) {
            throw new IOError.PROXY_FAILED("wanted %02x for length, got %02x".printf(dstaddr.length, read_buffer[4]));
        }
        if (!bytes_equal(read_buffer[5:5+dstaddr.length], dstaddr.data)) {
            string repr = ((string)read_buffer[5:5+dstaddr.length]).escape(); // TODO call make_valid() once glib>=2.52 becomes widespread
            throw new IOError.PROXY_FAILED(@"wanted dstaddr $(dstaddr), got $(repr)");
        }
        if (read_buffer[5+dstaddr.length] != 0x00 || read_buffer[5+dstaddr.length+1] != 0x00) {
            throw new IOError.PROXY_FAILED("wanted port 00 00, got %02x %02x".printf(read_buffer[5+dstaddr.length], read_buffer[5+dstaddr.length+1]));
        }

        conn.get_socket().set_timeout(0);

        return conn;
    }
    public async void try_connecting_to_candidates(XmppStream stream, Jingle.Session session) throws Error {
        remote_candidates.sort((c1, c2) => {
            // sort from priorities from high to low
            if (c1.priority < c2.priority) { return 1; }
            if (c1.priority > c2.priority) { return -1; }
            return 0;
        });
        foreach (Candidate candidate in remote_candidates) {
            if (remote_selected_candidate != null && remote_selected_candidate.priority > candidate.priority) {
                // Don't try candidates with lower priority than the one the
                // peer already selected.
                break;
            }
            try {
                SocketConnection conn = yield connect_to_socks5(candidate, remote_dstaddr);

                local_determined_selected_candidate = true;
                local_selected_candidate = candidate;
                local_selected_candidate_conn = conn;
                debug("Selected candidate %s", candidate.cid);
                session.send_transport_info(stream, new StanzaNode.build("transport", NS_URI)
                    .add_self_xmlns()
                    .put_attribute("sid", sid)
                    .put_node(new StanzaNode.build("candidate-used", NS_URI)
                        .put_attribute("cid", candidate.cid)
                    )
                );
                try_completing_negotiation();
                return;
            } catch (Error e) {
                // An error in the connection establishment isn't fatal, just
                // try the next candidate or respond that none of the
                // candidates work.
            }
        }
        local_determined_selected_candidate = true;
        local_selected_candidate = null;
        session.send_transport_info(stream, new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid)
            .put_node(new StanzaNode.build("candidate-error", NS_URI))
        );
        // Try remote candidates
        try_completing_negotiation();
    }
    public void create_transport_connection(XmppStream stream, Jingle.Session session) {
        this.session = session;
        this.hack = stream;
        try_connecting_to_candidates.begin(stream, session);
    }
}

}
