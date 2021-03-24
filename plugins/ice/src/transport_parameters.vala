using Gee;
using Xmpp;
using Xmpp.Xep;


public class Dino.Plugins.Ice.TransportParameters : JingleIceUdp.IceUdpTransportParameters {
    private Nice.Agent agent;
    private uint stream_id;
    private bool we_want_connection;
    private bool remote_credentials_set;
    private Map<uint8, DatagramConnection> connections = new HashMap<uint8, DatagramConnection>();
    private DtlsSrtp? dtls_srtp;

    private class DatagramConnection : Jingle.DatagramConnection {
        private Nice.Agent agent;
        private DtlsSrtp? dtls_srtp;
        private uint stream_id;
        private string? error;
        private ulong sent;
        private ulong sent_reported;
        private ulong recv;
        private ulong recv_reported;
        private ulong datagram_received_id;

        public DatagramConnection(Nice.Agent agent, DtlsSrtp? dtls_srtp, uint stream_id, uint8 component_id) {
            this.agent = agent;
            this.dtls_srtp = dtls_srtp;
            this.stream_id = stream_id;
            this.component_id = component_id;
            this.datagram_received_id = this.datagram_received.connect((datagram) => {
                recv += datagram.length;
                if (recv > recv_reported + 100000) {
                    debug("Received %lu bytes via stream %u component %u", recv, stream_id, component_id);
                    recv_reported = recv;
                }
            });
        }

        public override async void terminate(bool we_terminated, string? reason_string = null, string? reason_text = null) {
            yield base.terminate(we_terminated, reason_string, reason_text);
            this.disconnect(datagram_received_id);
            agent = null;
        }

        public override void send_datagram(Bytes datagram) {
            if (this.agent != null && is_component_ready(agent, stream_id, component_id)) {
                uint8[] encrypted_data = null;
                if (dtls_srtp != null) {
                    encrypted_data = dtls_srtp.process_outgoing_data(component_id, datagram.get_data());
                    if (encrypted_data == null) return;
                }
                agent.send(stream_id, component_id, encrypted_data ?? datagram.get_data());
                sent += datagram.length;
                if (sent > sent_reported + 100000) {
                    debug("Sent %lu bytes via stream %u component %u", sent, stream_id, component_id);
                    sent_reported = sent;
                }
            }
        }
    }

    public TransportParameters(Nice.Agent agent, Xep.ExternalServiceDiscovery.Service? turn_service, string? turn_ip, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode? node = null) {
        base(components, local_full_jid, peer_full_jid, node);
        this.we_want_connection = (node == null);
        this.agent = agent;

        if (this.peer_fingerprint != null || !incoming) {
            dtls_srtp = DtlsSrtp.setup();
            dtls_srtp.send_data.connect((data) => {
                agent.send(stream_id, 1, data);
            });
            this.own_fingerprint = dtls_srtp.get_own_fingerprint(GnuTLS.DigestAlgorithm.SHA256);
            if (incoming) {
                dtls_srtp.set_peer_fingerprint(this.peer_fingerprint);
            } else {
                dtls_srtp.setup_dtls_connection(true);
            }
        }

        agent.candidate_gathering_done.connect(on_candidate_gathering_done);
        agent.initial_binding_request_received.connect(on_initial_binding_request_received);
        agent.component_state_changed.connect(on_component_state_changed);
        agent.new_selected_pair_full.connect(on_new_selected_pair_full);
        agent.new_candidate_full.connect(on_new_candidate);

        agent.controlling_mode = !incoming;
        stream_id = agent.add_stream(components);

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
            agent.attach_recv(stream_id, component_id, MainContext.@default(), on_recv);
        }

        agent.gather_candidates(stream_id);
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

        if (dtls_srtp != null && peer_fingerprint != null) {
            dtls_srtp.set_peer_fingerprint(this.peer_fingerprint);
        } else {
            dtls_srtp = null;
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
                    Nice.Candidate nc = candidate_to_nice(candidate);
                    candidates.append(nc);
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
                    Nice.Candidate nc = candidate_to_nice(candidate);
                    candidates.append(nc);
                    debug("remote candidate: %s", agent.generate_local_candidate_sdp(nc));
                }
            }
            int new_candidates = agent.set_remote_candidates(stream_id, i, candidates);
            debug("Initiated component %u with %i remote candidates", i, new_candidates);

            connections[i] = new DatagramConnection(agent, dtls_srtp, stream_id, i);
            content.set_transport_connection(connections[i], i);
        }

        if (incoming && dtls_srtp != null) {
            Jingle.DatagramConnection rtp_datagram = (Jingle.DatagramConnection) content.get_transport_connection(1);
            rtp_datagram.notify["ready"].connect(() => {
                dtls_srtp.setup_dtls_connection(false);
            });
        }
        base.create_transport_connection(stream, content);
    }

    private void on_component_state_changed(uint stream_id, uint component_id, uint state) {
        if (stream_id != this.stream_id) return;
        debug("stream %u component %u state changed to %s", stream_id, component_id, agent.get_component_state(stream_id, component_id).to_string());
        may_consider_ready(stream_id, component_id);
    }

    private void may_consider_ready(uint stream_id, uint component_id) {
        if (stream_id != this.stream_id) return;
        if (connections.has_key((uint8) component_id) && is_component_ready(agent, stream_id, component_id) && connections.has_key((uint8) component_id) && !connections[(uint8)component_id].ready) {
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
        if (dtls_srtp != null) {
            decrypt_data = dtls_srtp.process_incoming_data(component_id, data);
            if (decrypt_data == null) return;
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
}