using Gee;
using Xmpp;
using Xmpp.Xep;


public class Dino.Plugins.Ice.TransportParameters : JingleIceUdp.IceUdpTransportParameters {
    private Nice.Agent agent;
    private uint stream_id;
    private bool we_want_connection;
    private bool remote_credentials_set;
    private Map<uint8, DatagramConnection> connections = new HashMap<uint8, DatagramConnection>();
    private DtlsSrtp.Handler? dtls_srtp_handler;
    private MainContext thread_context;
    private MainLoop thread_loop;

    private class DatagramConnection : Jingle.DatagramConnection {
        private Nice.Agent agent;
        private DtlsSrtp.Handler? dtls_srtp_handler;
        private uint stream_id;
        private string? error;
        private ulong datagram_received_id;

        public DatagramConnection(Nice.Agent agent, DtlsSrtp.Handler? dtls_srtp_handler, uint stream_id, uint8 component_id) {
            this.agent = agent;
            this.dtls_srtp_handler = dtls_srtp_handler;
            this.stream_id = stream_id;
            this.component_id = component_id;
            this.datagram_received_id = this.datagram_received.connect((datagram) => {
                bytes_received += datagram.length;
            });
        }

        public override async void terminate(bool we_terminated, string? reason_string = null, string? reason_text = null) {
            yield base.terminate(we_terminated, reason_string, reason_text);
            this.disconnect(datagram_received_id);
            agent = null;
            dtls_srtp_handler = null;
        }

        public override void send_datagram(Bytes datagram) {
            if (this.agent != null && is_component_ready(agent, stream_id, component_id)) {
                try {
                    if (dtls_srtp_handler != null) {
                        uint8[] encrypted_data = dtls_srtp_handler.process_outgoing_data(component_id, datagram.get_data());
                        if (encrypted_data == null) return;
                        GLib.OutputVector vector = { encrypted_data, encrypted_data.length };
                        GLib.OutputVector[] vectors = { vector };
                        Nice.OutputMessage message = { vectors };
                        Nice.OutputMessage[] messages = { message };
                        agent.send_messages_nonblocking(stream_id, component_id, messages);
                    } else {
                        GLib.OutputVector vector = { datagram.get_data(), datagram.get_size() };
                        GLib.OutputVector[] vectors = { vector };
                        Nice.OutputMessage message = { vectors };
                        Nice.OutputMessage[] messages = { message };
                        agent.send_messages_nonblocking(stream_id, component_id, messages);
                    }
                    bytes_sent += datagram.length;
                } catch (GLib.Error e) {
                    warning("%s while send_datagram stream %u component %u", e.message, stream_id, component_id);
                }
            }
        }
    }

    public TransportParameters(Nice.Agent agent, DtlsSrtp.CredentialsCapsule? credentials, Xep.ExternalServiceDiscovery.Service? turn_service, string? turn_ip, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode? node = null) {
        base(components, local_full_jid, peer_full_jid, node);
        this.we_want_connection = (node == null);
        this.agent = agent;

        if (this.peer_fingerprint != null || !incoming) {
            dtls_srtp_handler = setup_dtls(this, credentials);
            own_fingerprint = dtls_srtp_handler.own_fingerprint;
            if (incoming) {
                own_setup = "active";
                dtls_srtp_handler.mode = DtlsSrtp.Mode.CLIENT;
                dtls_srtp_handler.peer_fingerprint = peer_fingerprint;
                dtls_srtp_handler.peer_fp_algo = peer_fp_algo;
            } else {
                own_setup = "actpass";
                dtls_srtp_handler.mode = DtlsSrtp.Mode.SERVER;
                dtls_srtp_handler.setup_dtls_connection.begin((_, res) => {
                    var content_encryption = dtls_srtp_handler.setup_dtls_connection.end(res);
                    if (content_encryption != null) {
                        this.content.encryptions[content_encryption.encryption_ns] = content_encryption;
                    }
                });
            }
        }

        agent.candidate_gathering_done.connect(on_candidate_gathering_done);
        agent.initial_binding_request_received.connect(on_initial_binding_request_received);
        agent.component_state_changed.connect(on_component_state_changed);
        agent.new_selected_pair_full.connect(on_new_selected_pair_full);
        agent.new_candidate_full.connect(on_new_candidate);

        agent.controlling_mode = !incoming;
        stream_id = agent.add_stream(components);
        thread_context = new MainContext();
        new Thread<void*>(@"ice-thread-$stream_id", () => {
            thread_context.push_thread_default();
            thread_loop = new MainLoop(thread_context, false);
            thread_loop.run();
            thread_context.pop_thread_default();
            return null;
        });

        if (turn_ip != null) {
            for (uint8 component_id = 1; component_id <= components; component_id++) {
                agent.set_relay_info(stream_id, component_id, turn_ip, turn_service.port, turn_service.username, turn_service.password, Nice.RelayType.UDP);
                debug("TURN info (component %i) %s:%u", component_id, turn_ip, turn_service.port);
            }
        }
        string ufrag;
        string pwd;
        agent.get_local_credentials(stream_id, out ufrag, out pwd);
        init(ufrag, pwd);

        for (uint8 component_id = 1; component_id <= components; component_id++) {
            // We don't properly get local candidates before this call
            agent.attach_recv(stream_id, component_id, thread_context, on_recv);
        }

        agent.gather_candidates(stream_id);
    }

    private static DtlsSrtp.Handler setup_dtls(TransportParameters tp, DtlsSrtp.CredentialsCapsule credentials) {
        var weak_self = WeakRef(tp);
        DtlsSrtp.Handler dtls_srtp = new DtlsSrtp.Handler.with_cert(credentials);
        dtls_srtp.send_data.connect((data) => {
            TransportParameters self = (TransportParameters) weak_self.get();
            if (self != null) self.agent.send(self.stream_id, 1, data);
        });
        return dtls_srtp;
    }

    private void on_candidate_gathering_done(uint stream_id) {
        if (stream_id != this.stream_id) return;
        debug("on_candidate_gathering_done in %u", stream_id);

        for (uint8 i = 1; i <= components; i++) {
            foreach (unowned Nice.Candidate nc in agent.get_local_candidates(stream_id, i)) {
                if (nc.transport == Nice.CandidateTransport.UDP) {
                    JingleIceUdp.Candidate? candidate = candidate_to_jingle(nc);
                    if (candidate == null) continue;
                    debug("Local candidate summary: %s", agent.generate_local_candidate_sdp(nc));
                }
            }
        }
    }

    private void on_new_candidate(Nice.Candidate nc) {
        if (nc.stream_id != stream_id) return;
        JingleIceUdp.Candidate? candidate = candidate_to_jingle(nc);
        if (candidate == null) return;

        if (nc.transport == Nice.CandidateTransport.UDP) {
            // Execution was in the agent thread before
            add_local_candidate_threadsafe(candidate);
        }
    }

    public override void handle_transport_accept(StanzaNode transport) throws Jingle.IqError {
        debug("on_transport_accept from %s", peer_full_jid.to_string());
        base.handle_transport_accept(transport);

        if (dtls_srtp_handler != null && peer_fingerprint != null) {
            dtls_srtp_handler.peer_fingerprint = peer_fingerprint;
            dtls_srtp_handler.peer_fp_algo = peer_fp_algo;
            if (peer_setup == "passive") {
                dtls_srtp_handler.mode = DtlsSrtp.Mode.CLIENT;
                dtls_srtp_handler.stop_dtls_connection();
                dtls_srtp_handler.setup_dtls_connection.begin((_, res) => {
                    var content_encryption = dtls_srtp_handler.setup_dtls_connection.end(res);
                    if (content_encryption != null) {
                        this.content.encryptions[content_encryption.encryption_ns] = content_encryption;
                    }
                });
            }
        } else {
            dtls_srtp_handler = null;
        }
    }

    public override void handle_transport_info(StanzaNode transport) throws Jingle.IqError {
        debug("on_transport_info from %s", peer_full_jid.to_string());
        base.handle_transport_info(transport);

        if (!we_want_connection) return;

        if (remote_ufrag != null && remote_pwd != null && !remote_credentials_set) {
            agent.set_remote_credentials(stream_id, remote_ufrag, remote_pwd);
            remote_credentials_set = true;
        }
        for (uint8 i = 1; i <= components; i++) {
            SList<Nice.Candidate> candidates = new SList<Nice.Candidate>();
            foreach (JingleIceUdp.Candidate candidate in remote_candidates) {
                if (candidate.component == i) {
                    candidates.append(candidate_to_nice(candidate));
                }
            }
            int new_candidates = agent.set_remote_candidates(stream_id, i, candidates);
            debug("Updated to %i remote candidates for candidate %u via transport info", new_candidates, i);
        }
    }

    public override void create_transport_connection(XmppStream stream, Jingle.Content content) {
        debug("create_transport_connection: %s", content.session.sid);
        debug("local_credentials: %s %s", local_ufrag, local_pwd);
        debug("remote_credentials: %s %s", remote_ufrag, remote_pwd);
        debug("expected incoming credentials: %s %s", local_ufrag + ":" + remote_ufrag, local_pwd);
        debug("expected outgoing credentials: %s %s", remote_ufrag + ":" + local_ufrag, remote_pwd);

        we_want_connection = true;

        if (remote_ufrag != null && remote_pwd != null && !remote_credentials_set) {
            agent.set_remote_credentials(stream_id, remote_ufrag, remote_pwd);
            remote_credentials_set = true;
        }
        for (uint8 i = 1; i <= components; i++) {
            SList<Nice.Candidate> candidates = new SList<Nice.Candidate>();
            foreach (JingleIceUdp.Candidate candidate in remote_candidates) {
                if (candidate.ip.has_prefix("fe80::")) continue;
                if (candidate.component == i) {
                    candidates.append(candidate_to_nice(candidate));
                    debug("remote candidate: %s", agent.generate_local_candidate_sdp(candidate_to_nice(candidate)));
                }
            }
            int new_candidates = agent.set_remote_candidates(stream_id, i, candidates);
            debug("Initiated component %u with %i remote candidates", i, new_candidates);

            connections[i] = new DatagramConnection(agent, dtls_srtp_handler, stream_id, i);
            content.set_transport_connection(connections[i], i);
        }

        base.create_transport_connection(stream, content);
    }

    private void on_component_state_changed(uint stream_id, uint component_id, uint state) {
        if (stream_id != this.stream_id) return;
        debug("stream %u component %u state changed to %s", stream_id, component_id, agent.get_component_state(stream_id, component_id).to_string());
        may_consider_ready(stream_id, component_id);
        if (incoming && dtls_srtp_handler != null && !dtls_srtp_handler.ready && is_component_ready(agent, stream_id, component_id) && dtls_srtp_handler.mode == DtlsSrtp.Mode.CLIENT) {
            dtls_srtp_handler.setup_dtls_connection.begin((_, res) => {
                Jingle.ContentEncryption? encryption = dtls_srtp_handler.setup_dtls_connection.end(res);
                if (encryption != null) {
                    this.content.encryptions[encryption.encryption_ns] = encryption;
                }
            });
        }
    }

    private void may_consider_ready(uint stream_id, uint component_id) {
        if (stream_id != this.stream_id) return;
        if (connections.has_key((uint8) component_id) && !connections[(uint8)component_id].ready && is_component_ready(agent, stream_id, component_id) && (dtls_srtp_handler == null || dtls_srtp_handler.ready)) {
            connections[(uint8)component_id].ready = true;
        }
    }

    private void on_initial_binding_request_received(uint stream_id) {
        if (stream_id != this.stream_id) return;
        debug("initial_binding_request_received");
    }

    private void on_new_selected_pair_full(uint stream_id, uint component_id, Nice.Candidate p1, Nice.Candidate p2) {
        if (stream_id != this.stream_id) return;
        debug("new_selected_pair_full %u [%s, %s]", component_id, agent.generate_local_candidate_sdp(p1), agent.generate_local_candidate_sdp(p2));
    }

    private void on_recv(Nice.Agent agent, uint stream_id, uint component_id, uint8[] data) {
        if (stream_id != this.stream_id) return;
        uint8[] decrypt_data = null;
        if (dtls_srtp_handler != null) {
            try {
                decrypt_data = dtls_srtp_handler.process_incoming_data(component_id, data);
                if (decrypt_data == null) return;
            } catch (Crypto.Error e) {
                warning("%s while on_recv stream %u component %u", e.message, stream_id, component_id);
                return;
            }
        }
        may_consider_ready(stream_id, component_id);
        if (connections.has_key((uint8) component_id)) {
            if (!connections[(uint8) component_id].ready) {
                debug("on_recv stream %u component %u when state %s", stream_id, component_id, agent.get_component_state(stream_id, component_id).to_string());
            }
            connections[(uint8) component_id].datagram_received(new Bytes(decrypt_data ?? data));
        } else {
            debug("on_recv stream %u component %u length %u", stream_id, component_id, data.length);
        }
    }

    private static Nice.Candidate candidate_to_nice(JingleIceUdp.Candidate c) {
        Nice.CandidateType type;
        switch (c.type_) {
            case JingleIceUdp.Candidate.Type.HOST: type = Nice.CandidateType.HOST; break;
            case JingleIceUdp.Candidate.Type.PRFLX: type = Nice.CandidateType.PEER_REFLEXIVE; break;
            case JingleIceUdp.Candidate.Type.RELAY: type = Nice.CandidateType.RELAYED; break;
            case JingleIceUdp.Candidate.Type.SRFLX: type = Nice.CandidateType.SERVER_REFLEXIVE; break;
            default: assert_not_reached();
        }

        Nice.Candidate candidate = new Nice.Candidate(type);
        candidate.component_id = c.component;
        char[] foundation = new char[Nice.CANDIDATE_MAX_FOUNDATION];
        Memory.copy(foundation, c.foundation.data, size_t.min(c.foundation.length, Nice.CANDIDATE_MAX_FOUNDATION - 1));
        candidate.foundation = foundation;
        candidate.addr = Nice.Address();
        candidate.addr.init();
        candidate.addr.set_from_string(c.ip);
        candidate.addr.set_port(c.port);
        candidate.priority = c.priority;
        if (c.rel_addr != null) {
            candidate.base_addr = Nice.Address();
            candidate.base_addr.init();
            candidate.base_addr.set_from_string(c.rel_addr);
            candidate.base_addr.set_port(c.rel_port);
        }
        candidate.transport = Nice.CandidateTransport.UDP;
        return candidate;
    }

    private static JingleIceUdp.Candidate? candidate_to_jingle(Nice.Candidate nc) {
        JingleIceUdp.Candidate candidate = new JingleIceUdp.Candidate();
        switch (nc.type) {
            case Nice.CandidateType.HOST: candidate.type_ = JingleIceUdp.Candidate.Type.HOST; break;
            case Nice.CandidateType.PEER_REFLEXIVE: candidate.type_ = JingleIceUdp.Candidate.Type.PRFLX; break;
            case Nice.CandidateType.RELAYED: candidate.type_ = JingleIceUdp.Candidate.Type.RELAY; break;
            case Nice.CandidateType.SERVER_REFLEXIVE: candidate.type_ = JingleIceUdp.Candidate.Type.SRFLX; break;
            default: assert_not_reached();
        }
        candidate.component = (uint8) nc.component_id;
        candidate.foundation = ((string)nc.foundation).dup();
        candidate.generation = 0;
        candidate.id = Random.next_int().to_string("%08x"); // TODO

        char[] res = new char[NICE_ADDRESS_STRING_LEN];
        nc.addr.to_string(res);
        candidate.ip = (string) res;
        candidate.network = 0; // TODO
        candidate.port = (uint16) nc.addr.get_port();
        candidate.priority = nc.priority;
        candidate.protocol = "udp";
        if (nc.base_addr.is_valid() && !nc.base_addr.equal(nc.addr)) {
            res = new char[NICE_ADDRESS_STRING_LEN];
            nc.base_addr.to_string(res);
            candidate.rel_addr = (string) res;
            candidate.rel_port = (uint16) nc.base_addr.get_port();
        }
        if (candidate.ip.has_prefix("fe80::")) return null;

        return candidate;
    }

    public override void dispose() {
        base.dispose();
        agent = null;
        dtls_srtp_handler = null;
        connections.clear();
        if (thread_loop != null) {
            thread_loop.quit();
        }
    }
}
