using Dino.Entities;
using Gee;
using Xmpp;

public class Dino.CallState : Object {

    public signal void terminated(Jid who_terminated, string? reason_name, string? reason_text);
    public signal void peer_joined(Jid jid, PeerState peer_state);
    public signal void peer_left(Jid jid, PeerState peer_state, string? reason_name, string? reason_text);

    public StreamInteractor stream_interactor;
    public Call call;
    public Xep.Muji.GroupCall? group_call { get; set; }
    public Jid? parent_muc { get; set; }
    public Jid? invited_to_group_call = null;
    public Jid? group_call_inviter = null;
    public bool accepted { get; private set; default=false; }

    public bool we_should_send_audio { get; set; default=false; }
    public bool we_should_send_video { get; set; default=false; }
    public HashMap<Jid, PeerState> peers = new HashMap<Jid, PeerState>(Jid.hash_func, Jid.equals_func);

    private string message_type = Xmpp.MessageStanza.TYPE_CHAT;

    public CallState(Call call, StreamInteractor stream_interactor) {
        this.call = call;
        this.stream_interactor = stream_interactor;

        if (call.direction == Call.DIRECTION_OUTGOING) {
            accepted = true;

            Timeout.add_seconds(30, () => {
                if (this == null) return false; // TODO enough?
                if (call.state == Call.State.ESTABLISHING) {
                    call.state = Call.State.MISSED;
                    terminated(call.account.bare_jid, null, null);
                }
                return false;
            });
        }
    }

    internal async void initiate_groupchat_call(Jid muc) {
        parent_muc = muc;
        message_type = Xmpp.MessageStanza.TYPE_GROUPCHAT;

        if (this.group_call == null) yield convert_into_group_call();
        if (this.group_call == null) return;
        // The user might have retracted the call in the meanwhile
        if (this.call.state != Call.State.RINGING) return;

        XmppStream stream = stream_interactor.get_stream(call.account);
        if (stream == null) return;

        Gee.List<Jid> occupants = stream_interactor.get_module(MucManager.IDENTITY).get_other_occupants(muc, call.account);
        foreach (Jid occupant in occupants) {
            Jid? real_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(occupant, call.account);
            if (real_jid == null) continue;
            debug(@"Adding MUC member as MUJI MUC owner %s", real_jid.bare_jid.to_string());
            yield stream.get_module(Xep.Muc.Module.IDENTITY).change_affiliation(stream, group_call.muc_jid, real_jid.bare_jid, null, "owner");
        }

        stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite(stream, muc, group_call.muc_jid, we_should_send_video, message_type);
    }

    internal PeerState set_first_peer(Jid peer) {
        var peer_state = new PeerState(peer, call, stream_interactor);
        peer_state.first_peer = true;
        add_peer(peer_state);
        return peer_state;
    }

    internal void add_peer(PeerState peer) {
        call.add_peer(peer.jid.bare_jid);
        connect_peer_signals(peer);
        peer_joined(peer.jid, peer);
    }

    public void accept() {
        accepted = true;
        call.state = Call.State.ESTABLISHING;

        if (invited_to_group_call != null) {
            XmppStream stream = stream_interactor.get_stream(call.account);
            if (stream == null) return;
            stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite_accept_to_peer(stream, group_call_inviter, invited_to_group_call, message_type);
            join_group_call.begin(invited_to_group_call);
        } else {
            foreach (PeerState peer in peers.values) {
                peer.accept();
            }
        }
    }

    public void reject() {
        call.state = Call.State.DECLINED;

        if (invited_to_group_call != null) {
            XmppStream stream = stream_interactor.get_stream(call.account);
            if (stream == null) return;
            stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite_reject_to_self(stream, invited_to_group_call);
            stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite_reject_to_peer(stream, group_call_inviter, invited_to_group_call, message_type);
        }
        var peers_cpy = new ArrayList<PeerState>();
        peers_cpy.add_all(peers.values);
        foreach (PeerState peer in peers_cpy) {
            peer.reject();
        }
        terminated(call.account.bare_jid, null, null);
    }

    public void end() {
        var peers_cpy = new ArrayList<PeerState>();
        peers_cpy.add_all(peers.values);

        if (group_call != null) {
            stream_interactor.get_module(MucManager.IDENTITY).part(call.account, group_call.muc_jid);
        }

        if (call.state == Call.State.IN_PROGRESS || call.state == Call.State.ESTABLISHING) {
            foreach (PeerState peer in peers_cpy) {
                peer.end(Xep.Jingle.ReasonElement.SUCCESS);
            }
            call.state = Call.State.ENDED;
        } else if (call.state == Call.State.RINGING) {
            foreach (PeerState peer in peers_cpy) {
                peer.end(Xep.Jingle.ReasonElement.CANCEL);
            }
            if (parent_muc != null) {
                XmppStream stream = stream_interactor.get_stream(call.account);
                if (stream == null) return;
                stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite_retract_to_peer(stream, parent_muc, group_call.muc_jid, message_type);
            }
            call.state = Call.State.MISSED;
        } else {
            return;
        }

        call.end_time = new DateTime.now_utc();

        terminated(call.account.bare_jid, null, null);
    }

    public void mute_own_audio(bool mute) {
        we_should_send_audio = !mute;
        foreach (PeerState peer in peers.values) {
            peer.mute_own_audio(mute);
        }
    }

    public void mute_own_video(bool mute) {
        we_should_send_video = !mute;
        foreach (PeerState peer in peers.values) {
            peer.mute_own_video(mute);
        }
    }

    public bool should_we_send_video() {
        return we_should_send_video;
    }

    public async void invite_to_call(Jid invitee) {
        if (this.group_call == null) yield convert_into_group_call();
        if (this.group_call == null) return;

        XmppStream stream = stream_interactor.get_stream(call.account);
        if (stream == null) return;

        debug("[%s] Inviting to muji call %s", call.account.bare_jid.to_string(), invitee.to_string());
        yield stream.get_module(Xep.Muc.Module.IDENTITY).change_affiliation(stream, group_call.muc_jid, invitee, null, "owner");
        stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite(stream, invitee, group_call.muc_jid, we_should_send_video);

        // If the peer hasn't accepted within a minute, retract the invite
        Timeout.add_seconds(60, () => {
            if (this == null) return false;

            bool contains_peer = false;
            foreach (Jid peer in peers.keys) {
                if (peer.equals_bare(invitee)) {
                    contains_peer = true;
                }
            }

            if (!contains_peer) {
                debug("[%s] Retracting invite to %s from %s", call.account.bare_jid.to_string(), group_call.muc_jid.to_string(), invitee.to_string());
                stream.get_module(Xep.MujiMeta.Module.IDENTITY).send_invite_retract_to_peer(stream, invitee, group_call.muc_jid);
                stream.get_module(Xep.Muc.Module.IDENTITY).change_affiliation.begin(stream, group_call.muc_jid, invitee, null, "none");
            }
            return false;
        });
    }

    internal void rename_peer(Jid from_jid, Jid to_jid) {
        debug("[%s] Renaming %s to %s exists %b", call.account.bare_jid.to_string(), from_jid.to_string(), to_jid.to_string(), peers.has_key(from_jid));
        PeerState? peer_state = peers[from_jid];
        if (peer_state == null) return;

        // Adjust the internal mapping of this `PeerState` object
        peers.unset(from_jid);
        peers[to_jid] = peer_state;
        peer_state.jid = to_jid;
    }

    private void on_call_terminated(Jid who_terminated, bool we_terminated, string? reason_name, string? reason_text) {
        if (call.state == Call.State.RINGING || call.state == Call.State.IN_PROGRESS || call.state == Call.State.ESTABLISHING) {
            call.end_time = new DateTime.now_utc();
        }
        if (call.state == Call.State.IN_PROGRESS) {
            call.state = Call.State.ENDED;
        } else if (call.state == Call.State.RINGING || call.state == Call.State.ESTABLISHING) {
            if (reason_name == Xep.Jingle.ReasonElement.DECLINE) {
                call.state = Call.State.DECLINED;
            } else {
                call.state = Call.State.FAILED;
            }
        }

        terminated(who_terminated, reason_name, reason_text);
    }

    private void connect_peer_signals(PeerState peer_state) {
        peers[peer_state.jid] = peer_state;

        this.bind_property("we-should-send-audio", peer_state, "we-should-send-audio", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        this.bind_property("we-should-send-video", peer_state, "we-should-send-video", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        this.bind_property("group-call", peer_state, "group-call", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        peer_state.session_terminated.connect((we_terminated, reason_name, reason_text) => {
            peers.unset(peer_state.jid);
            debug("[%s] Peer left %s left %i", call.account.bare_jid.to_string(), peer_state.jid.to_string(), peers.size);

            if (peers.is_empty) {
                if (group_call != null) group_call.leave(stream_interactor.get_stream(call.account));
                on_call_terminated(peer_state.jid, we_terminated, reason_name, reason_text);
            } else {
                peer_left(peer_state.jid, peer_state, reason_name, reason_text);
            }
        });
    }

    public async void convert_into_group_call() {
        XmppStream stream = stream_interactor.get_stream(call.account);
        if (stream == null) return;

        Jid muc_jid = stream_interactor.get_module(MucManager.IDENTITY).default_muc_server[call.account] ?? new Jid("chat.jabberfr.org");
        muc_jid = new Jid("%08x@".printf(Random.next_int()) + muc_jid.to_string()); // TODO longer?

        debug("[%s] Converting call to groupcall %s", call.account.bare_jid.to_string(), muc_jid.to_string());
        yield join_group_call(muc_jid);

        Xep.DataForms.DataForm? data_form = yield stream_interactor.get_module(MucManager.IDENTITY).get_config_form(call.account, muc_jid);
        if (data_form == null) return;

        foreach (Xep.DataForms.DataForm.Field field in data_form.fields) {
            switch (field.var) {
                case "muc#roomconfig_allowinvites":
                    if (field.type_ == Xep.DataForms.DataForm.Type.BOOLEAN) {
                        ((Xep.DataForms.DataForm.BooleanField) field).value = true;
                    }
                    break;
                case "muc#roomconfig_persistentroom":
                    if (field.type_ == Xep.DataForms.DataForm.Type.BOOLEAN) {
                        ((Xep.DataForms.DataForm.BooleanField) field).value = false;
                    }
                    break;
                case "muc#roomconfig_membersonly":
                    if (field.type_ == Xep.DataForms.DataForm.Type.BOOLEAN) {
                        ((Xep.DataForms.DataForm.BooleanField) field).value = true;
                    }
                    break;
                case "muc#roomconfig_whois":
                    if (field.type_ == Xep.DataForms.DataForm.Type.LIST_SINGLE) {
                        ((Xep.DataForms.DataForm.ListSingleField) field).value = "anyone";
                    }
                    break;
            }
        }
        yield stream_interactor.get_module(MucManager.IDENTITY).set_config_form(call.account, muc_jid, data_form);

        foreach (Jid peer_jid in peers.keys) {
            debug("[%s] Group call inviting %s", call.account.bare_jid.to_string(), peer_jid.to_string());
            yield invite_to_call(peer_jid);
        }
    }

    public async void join_group_call(Jid muc_jid) {
        debug("[%s] Joining group call %s", call.account.bare_jid.to_string(), muc_jid.to_string());
        XmppStream stream = stream_interactor.get_stream(call.account);
        if (stream == null) return;

        this.group_call = yield stream.get_module(Xep.Muji.Module.IDENTITY).join_call(stream, muc_jid, we_should_send_video);
        if (this.group_call == null) {
            warning("[%s] Couldn't join MUJI MUC", call.account.bare_jid.to_string());
            return;
        }

        this.group_call.peer_joined.connect((jid) => {
            debug("[%s] Group call peer joined: %s", call.account.bare_jid.to_string(), jid.to_string());

            // Newly joined peers have to call us, not the other way round
            // Maybe they called us already. Accept the call.
            // (Except for the first peer, we already have a connection to that one.)
            if (peers.has_key(jid)) {
                if (!peers[jid].first_peer) {
                    peers[jid].accept();
                }
                // else: Connection to first peer already active
            } else {
                var peer_state = new PeerState(jid, call, stream_interactor);
                peer_state.waiting_for_inbound_muji_connection = true;
                debug("[%s] Waiting for call from %s", call.account.bare_jid.to_string(), jid.to_string());
                add_peer(peer_state);
            }
        });

        this.group_call.peer_left.connect((jid) => {
            debug("[%s] Group call peer left: %s", call.account.bare_jid.to_string(), jid.to_string());
            if (!peers.has_key(jid)) return;
            // end() will in the end cause a `peer_left` signal and removal from `peers`
            peers[jid].end(Xep.Jingle.ReasonElement.CANCEL, "Peer left the MUJI MUC");
        });

        // Call all peers that are in the room already
        foreach (Jid peer_jid in group_call.peers_to_connect_to) {
            // Don't establish connection if we have one already (the person that invited us to the call)
            if (peers.has_key(peer_jid)) continue;

            debug("[%s] Calling %s because they were in the MUC already", call.account.bare_jid.to_string(), peer_jid.to_string());

            PeerState peer_state = new PeerState(peer_jid, call, stream_interactor);
            add_peer(peer_state);
            peer_state.call_resource.begin(peer_jid);
        }

        debug("[%s] Finished joining MUJI muc %s", call.account.bare_jid.to_string(), muc_jid.to_string());
    }
}