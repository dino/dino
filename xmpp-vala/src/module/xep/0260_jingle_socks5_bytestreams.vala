using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleSocks5Bytestreams {

private const string NS_URI = "urn:xmpp:jingle:transports:s5b:1";
private const int NEGOTIATION_TIMEOUT = 3;

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

    public async bool is_transport_available(XmppStream stream, uint8 components, Jid full_jid) {
        return components == 1 && yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
    }

    public string ns_uri { get { return NS_URI; } }
    public Jingle.TransportType type_ { get { return Jingle.TransportType.STREAMING; } }
    public int priority { get { return 1; } }
    private Gee.List<Candidate> get_proxies(XmppStream stream) {
        Gee.List<Candidate> result = new ArrayList<Candidate>();
        int i = 1 << 15;
        foreach (Socks5Bytestreams.Proxy proxy in stream.get_module(Socks5Bytestreams.Module.IDENTITY).get_proxies(stream)) {
            result.add(new Candidate.proxy(random_uuid(), proxy, i));
            i -= 1;
        }
        return result;
    }
    private Gee.List<Candidate> start_local_listeners(XmppStream stream, Jid local_full_jid, string dstaddr, out LocalListener? local_listener) {
        Gee.List<Candidate> result = new ArrayList<Candidate>();
        SocketListener listener = new SocketListener();
        int i = 1 << 15;
        foreach (string ip_address in stream.get_module(Socks5Bytestreams.Module.IDENTITY).get_local_ip_addresses()) {
            InetSocketAddress addr = new InetSocketAddress.from_string(ip_address, 0);
            SocketAddress effective_any;
            string cid = random_uuid();
            try {
                listener.add_address(addr, SocketType.STREAM, SocketProtocol.DEFAULT, new StringWrapper(cid), out effective_any);
            } catch (Error e) {
                continue;
            }
            InetSocketAddress effective = (InetSocketAddress)effective_any;
            result.add(new Candidate.build(cid, ip_address, local_full_jid, (int)effective.port, i, CandidateType.DIRECT));
            i -= 1;
        }
        if (!result.is_empty) {
            local_listener = new LocalListener(listener, dstaddr);
            local_listener.start();
        } else {
            local_listener = new LocalListener.empty();
        }
        return result;
    }
    private void select_candidates(XmppStream stream, Jid local_full_jid, string dstaddr, Parameters result) {
        result.local_candidates.add_all(get_proxies(stream));
        //result.local_candidates.add_all(start_local_listeners(stream, local_full_jid, dstaddr, out result.listener));
        result.local_candidates.sort((c1, c2) => {
            if (c1.priority < c2.priority) { return 1; }
            if (c1.priority > c2.priority) { return -1; }
            return 0;
        });
    }
    public Jingle.TransportParameters create_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid) {
        assert(components == 1);
        Parameters result = new Parameters.create(local_full_jid, peer_full_jid, random_uuid());
        string dstaddr = calculate_dstaddr(result.sid, local_full_jid, peer_full_jid);
        select_candidates(stream, local_full_jid, dstaddr, result);
        return result;
    }
    public Jingle.TransportParameters parse_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
        Parameters result = Parameters.parse(local_full_jid, peer_full_jid, transport);
        string dstaddr = calculate_dstaddr(result.sid, local_full_jid, peer_full_jid);
        select_candidates(stream, local_full_jid, dstaddr, result);
        return result;
    }
}

private string calculate_dstaddr(string sid, Jid first_jid, Jid second_jid) {
    string hashed = sid + first_jid.to_string() + second_jid.to_string();
    return Checksum.compute_for_string(ChecksumType.SHA1, hashed);
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

class StringWrapper : GLib.Object {
    public string str { get; set; }

    public StringWrapper(string str) {
        this.str = str;
    }
}

class LocalListener {
    SocketListener? inner;
    string dstaddr;
    HashMap<string, SocketConnection> connections = new HashMap<string, SocketConnection>();

    public LocalListener(SocketListener inner, string dstaddr) {
        this.inner = inner;
        this.dstaddr = dstaddr;
    }
    public LocalListener.empty() {
        this.inner = null;
        this.dstaddr = "";
    }

    public void start() {
        if (inner == null) {
            return;
        }
        run.begin();
    }
    async void run() {
        while (true) {
            Object cid;
            SocketConnection conn;
            try {
                conn = yield inner.accept_async(null, out cid);
            } catch (Error e) {
                break;
            }
            handle_conn.begin(((StringWrapper)cid).str, conn);
        }
    }
    async void handle_conn(string cid, SocketConnection conn) {
        conn.socket.timeout = NEGOTIATION_TIMEOUT;
        size_t read;
        size_t written;
        uint8[] read_buffer = new uint8[1024];
        ByteArray write_buffer = new ByteArray();

        try {
            // 05 SOCKS version 5
            // ?? number of authentication methods
            yield conn.input_stream.read_all_async(read_buffer[0:2], GLib.Priority.DEFAULT, null, out read);
            if (read != 2) {
                throw new IOError.PROXY_FAILED("wanted client hello message consisting of 2 bytes, only got %d bytes".printf((int)read));
            }
            if (read_buffer[0] != 0x05 || read_buffer[1] == 0) {
                throw new IOError.PROXY_FAILED("wanted 05 xx, got %02x %02x".printf(read_buffer[0], read_buffer[1]));
            }
            int num_auth_methods = read_buffer[1];
            // ?? authentication method (num_auth_methods times)
            yield conn.input_stream.read_all_async(read_buffer[0:num_auth_methods], GLib.Priority.DEFAULT, null, out read);
            bool found_null_auth = false;
            for (int i = 0; i < read; i++) {
                if (read_buffer[i] == 0x00) {
                    found_null_auth = true;
                    break;
                }
            }
            if (read != num_auth_methods || !found_null_auth) {
                throw new IOError.PROXY_FAILED("peer didn't offer null auth");
            }
            // 05 SOCKS version 5
            // 00 nop authentication
            yield conn.output_stream.write_all_async({0x05, 0x00}, GLib.Priority.DEFAULT, null, out written);

            // 05 SOCKS version 5
            // 01 connect
            // 00 reserved
            // 03 address type: domain name
            // ?? length of the domain
            // .. domain
            // 00 port 0 (upper half)
            // 00 port 0 (lower half)
            yield conn.input_stream.read_all_async(read_buffer[0:4], GLib.Priority.DEFAULT, null, out read);
            if (read != 4) {
                throw new IOError.PROXY_FAILED("wanted connect message consisting of 4 bytes, only got %d bytes".printf((int)read));
            }
            if (read_buffer[0] != 0x05 || read_buffer[1] != 0x01 || read_buffer[3] != 0x03) {
                throw new IOError.PROXY_FAILED("wanted 05 00 ?? 03, got %02x %02x %02x %02x".printf(read_buffer[0], read_buffer[1], read_buffer[2], read_buffer[3]));
            }
            yield conn.input_stream.read_all_async(read_buffer[0:1], GLib.Priority.DEFAULT, null, out read);
            if (read != 1) {
                throw new IOError.PROXY_FAILED("wanted length of dstaddr consisting of 1 byte, only got %d bytes".printf((int)read));
            }
            int dstaddr_len = read_buffer[0];
            yield conn.input_stream.read_all_async(read_buffer[0:dstaddr_len+2], GLib.Priority.DEFAULT, null, out read);
            if (read != dstaddr_len + 2) {
                throw new IOError.PROXY_FAILED("wanted dstaddr and port consisting of %d bytes, got %d bytes".printf(dstaddr_len + 2, (int)read));
            }
            if (!bytes_equal(read_buffer[0:dstaddr_len], dstaddr.data)) {
                string repr = ((string)read_buffer[0:dstaddr.length]).make_valid().escape();
                throw new IOError.PROXY_FAILED(@"wanted dstaddr $(dstaddr), got $(repr)");
            }
            if (read_buffer[dstaddr_len] != 0x00 || read_buffer[dstaddr_len + 1] != 0x00) {
                throw new IOError.PROXY_FAILED("wanted 00 00, got %02x %02x".printf(read_buffer[dstaddr_len], read_buffer[dstaddr_len + 1]));
            }

            // 05 SOCKS version 5
            // 00 success
            // 00 reserved
            // 03 address type: domain name
            // ?? length of the domain
            // .. domain
            // 00 port 0 (upper half)
            // 00 port 0 (lower half)
            write_buffer.append({0x05, 0x00, 0x00, 0x03});
            write_buffer.append({(uint8)dstaddr.length});
            write_buffer.append(dstaddr.data);
            write_buffer.append({0x00, 0x00});
            yield conn.output_stream.write_all_async(write_buffer.data, GLib.Priority.DEFAULT, null, out written);

            conn.socket.timeout = 0;
            if (!connections.has_key(cid)) {
                connections[cid] = conn;
            }
        } catch (Error e) {
        }
    }

    public SocketConnection? get_connection(string cid) {
        if (!connections.has_key(cid)) {
            return null;
        }
        return connections[cid];
    }
}

class Parameters : Jingle.TransportParameters, Object {
    public string ns_uri { get { return NS_URI; } }
    public uint8 components { get { return 1; } }
    public Jingle.Role role { get; private set; }
    public string sid { get; private set; }
    public string remote_dstaddr { get; private set; }
    public string local_dstaddr { get; private set; }
    public Gee.List<Candidate> local_candidates = new ArrayList<Candidate>();
    public Gee.List<Candidate> remote_candidates = new ArrayList<Candidate>();
    public LocalListener? listener = null;

    Jid local_full_jid;
    Jid peer_full_jid;

    bool remote_sent_selected_candidate = false;
    Candidate? remote_selected_candidate = null;
    bool local_determined_selected_candidate = false;
    Candidate? local_selected_candidate = null;
    SocketConnection? local_selected_candidate_conn = null;
    weak Jingle.Session? session = null;
    weak Jingle.Content? content = null;
    XmppStream? hack = null;

    string? waiting_for_activation_cid = null;
    SourceFunc waiting_for_activation_callback;
    bool waiting_for_activation_error = false;

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

    public void set_content(Jingle.Content content) {

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

    public void handle_transport_accept(StanzaNode transport) throws Jingle.IqError {
        Parameters other = Parameters.parse(local_full_jid, peer_full_jid, transport);
        if (other.sid != sid) {
            throw new Jingle.IqError.BAD_REQUEST("invalid sid");
        }
        remote_candidates = other.remote_candidates;
        remote_dstaddr = other.remote_dstaddr;
    }

    public void handle_transport_info(StanzaNode transport) throws Jingle.IqError {
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
        debug("Remote selected candidate %s", candidate != null ? candidate.cid : "(null)");
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
            content_set_transport_connection(null);
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
                content_set_transport_connection(local_selected_candidate_conn);
            } else {
                wait_for_remote_activation.begin(local_selected_candidate, local_selected_candidate_conn);
            }
        } else {
            if (remote_selected_candidate.type_ == CandidateType.DIRECT) {
                Jingle.Session? strong = session;
                if (strong == null) {
                    return;
                }
                SocketConnection? conn = listener.get_connection(remote_selected_candidate.cid);
                if (conn == null) {
                    // Remote hasn't actually connected to us?!
                    content_set_transport_connection(null);
                    return;
                }
                content_set_transport_connection(conn);
            } else {
                connect_to_local_candidate.begin(remote_selected_candidate);
            }
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
            content_set_transport_connection(conn);
        } else {
            content_set_transport_connection(null);
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

            Jingle.Content? strong_content = content;
            if (strong_content == null) {
                return;
            }
            strong_content.send_transport_info(new StanzaNode.build("transport", NS_URI)
                .add_self_xmlns()
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("activated", NS_URI)
                    .put_attribute("cid", candidate.cid)
                )
            );

            content_set_transport_connection(conn);
        } catch (Error e) {
            Jingle.Content? strong_content = content;
            if (strong_content == null) {
                return;
            }
            strong_content.send_transport_info(new StanzaNode.build("transport", NS_URI)
                .add_self_xmlns()
                .put_attribute("sid", sid)
                .put_node(new StanzaNode.build("proxy-error", NS_URI))
            );
            content_set_transport_connection(null);
        }
    }

    public async SocketConnection connect_to_socks5(Candidate candidate, string dstaddr) throws Error {
        SocketClient socket_client = new SocketClient() { timeout=NEGOTIATION_TIMEOUT };

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
        // 00 nop authentication
        if (read != 2) {
            throw new IOError.PROXY_FAILED("wanted 05 00, only got %d bytes".printf((int)read));
        }
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
        if (read != write_buffer.len) {
            throw new IOError.PROXY_FAILED("wanted server success response consisting of %d bytes, only got %d bytes".printf((int)write_buffer.len, (int)read));
        }
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

        conn.socket.timeout = 0;

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
                content.send_transport_info(new StanzaNode.build("transport", NS_URI)
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
        content.send_transport_info(new StanzaNode.build("transport", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid)
            .put_node(new StanzaNode.build("candidate-error", NS_URI))
        );
        // Try remote candidates
        try_completing_negotiation();
    }

    private Jingle.StreamingConnection connection = new Jingle.StreamingConnection();

    private void content_set_transport_connection(IOStream? ios) {
        IOStream? iostream = ios;
        Jingle.Content? strong_content = content;
        if (strong_content == null) return;

        if (strong_content.security_params != null) {
            iostream = strong_content.security_params.wrap_stream(iostream);
        }
        connection.init.begin(iostream);
    }

    public void create_transport_connection(XmppStream stream, Jingle.Content content) {
        this.session = content.session;
        this.content = content;
        this.hack = stream;
        try_connecting_to_candidates.begin(stream, session);
        this.content.set_transport_connection(connection, 1);
    }
}

}
