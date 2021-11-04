using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

    public class Calls : StreamInteractionModule, Object {

        public signal void call_incoming(Call call, CallState state, Conversation conversation, bool video);
        public signal void call_outgoing(Call call, CallState state, Conversation conversation);

        public signal void call_terminated(Call call, string? reason_name, string? reason_text);
        public signal void conference_info_received(Call call, Xep.Coin.ConferenceInfo conference_info);

        public static ModuleIdentity<Calls> IDENTITY = new ModuleIdentity<Calls>("calls");
        public string id { get { return IDENTITY.id; } }

        private StreamInteractor stream_interactor;
        private Database db;

        public HashMap<Account, CallState> current_jmi_request_call = new HashMap<Account, CallState>(Account.hash_func, Account.equals_func);
        public HashMap<Account, PeerState> current_jmi_request_peer = new HashMap<Account, PeerState>(Account.hash_func, Account.equals_func);
        public HashMap<Call, CallState> call_states = new HashMap<Call, CallState>(Call.hash_func, Call.equals_func);

        public static void start(StreamInteractor stream_interactor, Database db) {
            Calls m = new Calls(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        private Calls(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;

            stream_interactor.account_added.connect(on_account_added);
        }

        public async CallState? initiate_call(Conversation conversation, bool video) {
            Call call = new Call();
            call.direction = Call.DIRECTION_OUTGOING;
            call.account = conversation.account;
            call.add_peer(conversation.counterpart);
            call.ourpart = conversation.account.full_jid;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.state = Call.State.RINGING;

            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);

            var call_state = new CallState(call, stream_interactor);
            call_state.we_should_send_video = video;
            call_state.we_should_send_audio = true;
            connect_call_state_signals(call_state);
            PeerState peer_state = call_state.set_first_peer(conversation.counterpart);

            yield peer_state.initiate_call(conversation.counterpart);

            conversation.last_active = call.time;

            call_outgoing(call, call_state, conversation);

            return call_state;
        }

        public async bool can_do_audio_calls_async(Conversation conversation) {
            if (!can_do_audio_calls()) return false;
            return (yield get_call_resources(conversation.account, conversation.counterpart)).size > 0 || has_jmi_resources(conversation.counterpart);
        }

        private bool can_do_audio_calls() {
            Plugins.VideoCallPlugin? plugin = Application.get_default().plugin_registry.video_call_plugin;
            if (plugin == null) return false;

            return plugin.supports("audio");
        }

        public async bool can_do_video_calls_async(Conversation conversation) {
            if (!can_do_video_calls()) return false;
            return (yield get_call_resources(conversation.account, conversation.counterpart)).size > 0 || has_jmi_resources(conversation.counterpart);
        }

        private bool can_do_video_calls() {
            Plugins.VideoCallPlugin? plugin = Application.get_default().plugin_registry.video_call_plugin;
            if (plugin == null) return false;

            return plugin.supports("video");
        }

        public async Gee.List<Jid> get_call_resources(Account account, Jid counterpart) {
            ArrayList<Jid> ret = new ArrayList<Jid>();

            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return ret;

            Gee.List<Jid>? full_jids = stream.get_flag(Presence.Flag.IDENTITY).get_resources(counterpart);
            if (full_jids == null) return ret;

            foreach (Jid full_jid in full_jids) {
                bool supports_rtc = yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).is_available(stream, full_jid);
                if (!supports_rtc) continue;
                ret.add(full_jid);
            }
            return ret;
        }

        public async bool contains_jmi_resources(Account account, Gee.List<Jid> full_jids) {
            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return false;

            foreach (Jid full_jid in full_jids) {
                bool does_jmi = yield stream_interactor.get_module(EntityInfo.IDENTITY).has_feature(account, full_jid, Xep.JingleMessageInitiation.NS_URI);
                if (does_jmi) return true;
            }
            return false;
        }

        public bool has_jmi_resources(Jid counterpart) {
            int64 jmi_resources = db.entity.select()
                    .with(db.entity.jid_id, "=", db.get_jid_id(counterpart))
                    .join_with(db.entity_feature, db.entity.caps_hash, db.entity_feature.entity)
                    .with(db.entity_feature.feature, "=", Xep.JingleMessageInitiation.NS_URI)
                    .count();
            return jmi_resources > 0;
        }

        public bool is_call_in_progress() {
            foreach (Call call in call_states.keys) {
                if (call.state == Call.State.IN_PROGRESS || call.state == Call.State.RINGING || call.state == Call.State.ESTABLISHING) {
                    return true;
                }
            }
            return false;
        }

        private void on_incoming_call(Account account, Xep.Jingle.Session session) {
            if (!can_do_audio_calls()) {
                warning("Incoming call but no call support detected. Ignoring.");
                return;
            }

            Jid? muji_muc = null;
            bool counterpart_wants_video = false;
            foreach (Xep.Jingle.Content content in session.contents) {
                Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                if (rtp_content_parameter == null) continue;
                muji_muc = rtp_content_parameter.muji_muc;
                if (rtp_content_parameter.media == "video" && session.senders_include_us(content.senders)) {
                    counterpart_wants_video = true;
                }
            }

            // Check if this comes from a MUJI MUC => accept
            if (muji_muc != null) {
                debug("[%s] Incoming call from %s from MUJI muc %s", account.bare_jid.to_string(), session.peer_full_jid.to_string(), muji_muc.to_string());

                foreach (CallState call_state in call_states.values) {
                    if (call_state.group_call != null && call_state.group_call.muc_jid.equals(muji_muc)) {
                        if (call_state.peers.keys.contains(session.peer_full_jid)) {
                            PeerState peer_state = call_state.peers[session.peer_full_jid];
                            debug("[%s] Incoming call, we know the peer. Expected %b", account.bare_jid.to_string(), peer_state.waiting_for_inbound_muji_connection);
                            if (!peer_state.waiting_for_inbound_muji_connection) return;

                            peer_state.set_session(session);
                            debug(@"[%s] Accepting incoming MUJI call from %s", account.bare_jid.to_string(), session.peer_full_jid.to_string());
                            peer_state.accept();
                        } else {
                            debug(@"[%s] Incoming call, but didn't see peer in MUC yet", account.bare_jid.to_string());
                            PeerState peer_state = new PeerState(session.peer_full_jid, call_state.call, stream_interactor);
                            peer_state.set_session(session);
                            call_state.add_peer(peer_state);
                        }
                        return;
                    }
                }
                return;
            }

            debug(@"[%s] Incoming call from %s", account.bare_jid.to_string(), session.peer_full_jid.to_string());

            // Check if we already accepted this call via Jingle Message Initiation => accept
            if (current_jmi_request_call.has_key(account) &&
                    current_jmi_request_peer[account].sid == session.sid &&
                    current_jmi_request_peer[account].we_should_send_video == counterpart_wants_video &&
                    current_jmi_request_peer[account].accepted_jmi) {
                current_jmi_request_peer[account].set_session(session);
                current_jmi_request_call[account].accept();

                current_jmi_request_peer.unset(account);
                current_jmi_request_call.unset(account);
                return;
            }

            // This is a direct call without prior JMI. Ask user.
            PeerState peer_state = create_received_call(account, session.peer_full_jid, account.full_jid, counterpart_wants_video);
            peer_state.set_session(session);
            stream_interactor.module_manager.get_module(account, Xep.JingleRtp.Module.IDENTITY).session_info_type.send_ringing(session);
        }

        private PeerState create_received_call(Account account, Jid from, Jid to, bool video_requested) {
            Call call = new Call();
            Jid counterpart = null;
            if (from.equals_bare(account.bare_jid)) {
                // Call requested by another of our devices
                call.direction = Call.DIRECTION_OUTGOING;
                call.ourpart = from;
                counterpart = to;
            } else {
                call.direction = Call.DIRECTION_INCOMING;
                call.ourpart = account.full_jid;
                counterpart = from;
            }
            call.add_peer(counterpart);
            call.account = account;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.state = Call.State.RINGING;

            Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(counterpart.bare_jid, account, Conversation.Type.CHAT);

            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);

            conversation.last_active = call.time;

            var call_state = new CallState(call, stream_interactor);
            connect_call_state_signals(call_state);
            PeerState peer_state = call_state.set_first_peer(counterpart);
            call_state.we_should_send_video = video_requested;
            call_state.we_should_send_audio = true;

            if (call.direction == Call.DIRECTION_INCOMING) {
                call_incoming(call, call_state, conversation, video_requested);
            } else {
                call_outgoing(call, call_state, conversation);
            }

            return peer_state;
        }

        private CallState? get_call_state_for_groupcall(Account account, Jid muc_jid) {
            foreach (CallState call_state in call_states.values) {
                if (call_state.group_call != null && call_state.call.account.equals(account) && call_state.group_call.muc_jid.equals(muc_jid)) {
                    return call_state;
                }
            }
            return null;
        }

        private async void on_muji_call_received(Account account, Jid inviter_jid, Jid muc_jid, Gee.List<StanzaNode> descriptions) {
            debug("[%s] on_muji_call_received", account.bare_jid.to_string());
            foreach (Call call in call_states.keys) {
                if (call.account.equals(account) && call.counterparts.contains(inviter_jid) && call_states[call].accepted) {
                    // A call is converted into a group call.
                    yield call_states[call].join_group_call(muc_jid);
                    return;
                }
            }

            bool audio_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "audio");
            bool video_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "video");

            Call call = new Call();
            call.direction = Call.DIRECTION_INCOMING;
            call.ourpart = account.full_jid;
            call.add_peer(inviter_jid); // not rly
            call.account = account;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.state = Call.State.RINGING;

            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(inviter_jid.bare_jid, account);
            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);
            conversation.last_active = call.time;

            CallState call_state = new CallState(call, stream_interactor);
            connect_call_state_signals(call_state);
            call_state.we_should_send_audio = true;
            call_state.we_should_send_video = video_requested;
            call_state.invited_to_group_call = muc_jid;
            call_state.group_call_inviter = inviter_jid;

            debug("[%s] on_muji_call_received accepting", account.bare_jid.to_string());
            call_incoming(call_state.call, call_state, conversation, video_requested);
        }

        private void remove_call_from_datastructures(Call call) {
            if (current_jmi_request_call.has_key(call.account) && current_jmi_request_call[call.account].call.equals(call)) {
                current_jmi_request_call.unset(call.account);
                current_jmi_request_peer.unset(call.account);
            }
            call_states.unset(call);
        }

        private void connect_call_state_signals(CallState call_state) {
            call_states[call_state.call] = call_state;

            ulong terminated_handler_id = -1;
            terminated_handler_id = call_state.terminated.connect((who_terminated, reason_name, reason_text) => {
                remove_call_from_datastructures(call_state.call);
                call_terminated(call_state.call, reason_name, reason_text);
                call_state.disconnect(terminated_handler_id);
            });
        }

        private void on_account_added(Account account) {
            Xep.Jingle.Module jingle_module = stream_interactor.module_manager.get_module(account, Xep.Jingle.Module.IDENTITY);
            jingle_module.session_initiate_received.connect((stream, session) => {
                foreach (Xep.Jingle.Content content in session.contents) {
                    Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                    if (rtp_content_parameter != null) {
                        on_incoming_call(account, session);
                        break;
                    }
                }
            });

            Xep.JingleMessageInitiation.Module mi_module = stream_interactor.module_manager.get_module(account, Xep.JingleMessageInitiation.Module.IDENTITY);
            mi_module.session_proposed.connect((from, to, sid, descriptions) => {
                if (!can_do_audio_calls()) {
                    warning("Incoming call but no call support detected. Ignoring.");
                    return;
                }

                bool audio_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "audio");
                bool video_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "video");
                if (!audio_requested && !video_requested) return;

                PeerState peer_state = create_received_call(account, from, to, video_requested);
                peer_state.sid = sid;
                peer_state.we_should_send_audio = true;
                peer_state.we_should_send_video = video_requested;

                current_jmi_request_peer[account] = peer_state;
                current_jmi_request_call[account] = call_states[peer_state.call];
            });
            mi_module.session_accepted.connect((from, sid) => {
                if (!current_jmi_request_peer.has_key(account) || current_jmi_request_peer[account].sid != sid) return;

                if (from.equals_bare(account.bare_jid)) { // Carboned message from our account
                    // Ignore carbon from ourselves
                    if (from.equals(account.full_jid)) return;

                    Call call = current_jmi_request_peer[account].call;
                    call.state = Call.State.OTHER_DEVICE_ACCEPTED;
                    remove_call_from_datastructures(call);
                } else if (from.equals_bare(current_jmi_request_peer[account].jid)) { // Message from our peer
                    // We proposed the call
                    // We know the full jid of our peer now
                    current_jmi_request_call[account].rename_peer(current_jmi_request_peer[account].jid, from);
                    current_jmi_request_peer[account].call_resource(from);
                }
            });
            mi_module.session_rejected.connect((from, to, sid) => {
                if (!current_jmi_request_peer.has_key(account) || current_jmi_request_peer[account].sid != sid) return;
                Call call = current_jmi_request_peer[account].call;

                bool outgoing_reject = call.direction == Call.DIRECTION_OUTGOING && from.equals_bare(call.counterparts[0]);
                bool incoming_reject = call.direction == Call.DIRECTION_INCOMING && from.equals_bare(account.bare_jid);
                if (!outgoing_reject && !incoming_reject) return;

                call.state = Call.State.DECLINED;
                call_states[call].terminated(from, Xep.Jingle.ReasonElement.DECLINE, "JMI reject");
                remove_call_from_datastructures(call);
            });
            mi_module.session_retracted.connect((from, to, sid) => {
                if (!current_jmi_request_peer.has_key(account) || current_jmi_request_peer[account].sid != sid) return;
                Call call = current_jmi_request_peer[account].call;

                bool outgoing_retract = call.direction == Call.DIRECTION_OUTGOING && from.equals_bare(account.bare_jid);
                bool incoming_retract = call.direction == Call.DIRECTION_INCOMING && from.equals_bare(call.counterparts[0]);
                if (!(outgoing_retract || incoming_retract)) return;

                call.state = Call.State.MISSED;
                call_states[call].terminated(from, Xep.Jingle.ReasonElement.CANCEL, "JMI retract");
                remove_call_from_datastructures(call);
            });

            Xep.MujiMeta.Module muji_meta_module = stream_interactor.module_manager.get_module(account, Xep.MujiMeta.Module.IDENTITY);
            muji_meta_module.call_proposed.connect((inviter_jid, to, muc_jid, descriptions) => {
                if (inviter_jid.equals_bare(account.bare_jid)) return;
                on_muji_call_received.begin(account, inviter_jid, muc_jid, descriptions);
            });
            muji_meta_module.call_accepted.connect((from_jid, muc_jid) => {
                if (!from_jid.equals_bare(account.bare_jid)) return;

                // We accepted the call from another device
                CallState? call_state = get_call_state_for_groupcall(account, muc_jid);
                if (call_state == null) return;

                call_state.call.state = Call.State.OTHER_DEVICE_ACCEPTED;
                remove_call_from_datastructures(call_state.call);
            });
            muji_meta_module.call_retracted.connect((from_jid, muc_jid) => {
                if (from_jid.equals_bare(account.bare_jid)) return;

                // The call was retracted by the counterpart
                CallState? call_state = get_call_state_for_groupcall(account, muc_jid);
                if (call_state == null) return;

                call_state.call.state = Call.State.MISSED;
                remove_call_from_datastructures(call_state.call);
            });
            muji_meta_module.call_rejected.connect((from_jid, to_jid, muc_jid) => {
                if (from_jid.equals_bare(account.bare_jid)) return;
                debug(@"[%s] rejected our MUJI invite to %s", account.bare_jid.to_string(), from_jid.to_string(), muc_jid.to_string());
            });

            stream_interactor.module_manager.get_module(account, Xep.Coin.Module.IDENTITY).coin_info_received.connect((jid, info) => {
                foreach (Call call in call_states.keys) {
                    if (call.counterparts[0].equals_bare(jid)) {
                        conference_info_received(call, info);
                        return;
                    }
                }
            });
        }
    }
}