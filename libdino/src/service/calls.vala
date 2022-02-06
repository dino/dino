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

//        public HashMap<Account, CallState> current_jmi_request_call = new HashMap<Account, CallState>(Account.hash_func, Account.equals_func);
        public HashMap<Call, PeerState> jmi_request_peer = new HashMap<Call, PeerState>(Call.hash_func, Call.equals_func);
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
            call.counterpart = conversation.counterpart;
            call.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.full_jid;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.encryption = Encryption.UNKNOWN;
            call.state = Call.State.RINGING;

            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);

            var call_state = new CallState(call, stream_interactor);
            call_state.we_should_send_video = video;
            call_state.we_should_send_audio = true;
            connect_call_state_signals(call_state);

            if (conversation.type_ == Conversation.Type.CHAT) {
                call.add_peer(conversation.counterpart);
                PeerState peer_state = call_state.set_first_peer(conversation.counterpart);
                jmi_request_peer[call] = peer_state;
                yield peer_state.initiate_call(conversation.counterpart);
            } else {
                call_state.initiate_groupchat_call.begin(conversation.counterpart);
            }

            conversation.last_active = call.time;

            call_outgoing(call, call_state, conversation);

            return call_state;
        }

        public bool can_we_do_calls(Account account) {
            Plugins.VideoCallPlugin? plugin = Application.get_default().plugin_registry.video_call_plugin;
            if (plugin == null) return false;

            return plugin.supports(null);
        }

        public async bool can_conversation_do_calls(Conversation conversation) {
            if (conversation.type_ == Conversation.Type.CHAT) {
                return (yield get_call_resources(conversation.account, conversation.counterpart)).size > 0 || has_jmi_resources(conversation.counterpart);
            } else {
                bool is_private = stream_interactor.get_module(MucManager.IDENTITY).is_private_room(conversation.account, conversation.counterpart);
                EntityInfo entity_info = stream_interactor.get_module(EntityInfo.IDENTITY);
                bool supports_ussid = yield entity_info.has_feature(conversation.account, conversation.counterpart.bare_jid, Xep.UniqueStableStanzaIDs.NS_URI);
                bool supports_mam = yield entity_info.has_feature(conversation.account, conversation.counterpart.bare_jid, Xep.MessageArchiveManagement.NS_URI_2);
                return is_private && (supports_ussid || supports_mam) && can_initiate_groupcall(conversation.account);
            }
        }

        public bool can_initiate_groupcall(Account account) {
            return stream_interactor.get_module(MucManager.IDENTITY).default_muc_server[account] != null;
        }

        public async Gee.List<Jid> get_call_resources(Account account, Jid counterpart) {
            ArrayList<Jid> ret = new ArrayList<Jid>();

            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return ret;

            Presence.Flag? presence_flag = stream.get_flag(Presence.Flag.IDENTITY);
            if (presence_flag == null) return ret;

            Gee.List<Jid>? full_jids = presence_flag.get_resources(counterpart);
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
                            debug("[%s] Incoming call, we know the peer. Expected %s", account.bare_jid.to_string(), peer_state.waiting_for_inbound_muji_connection.to_string());
                            if (!peer_state.waiting_for_inbound_muji_connection) return;

                            peer_state.set_session(session);
                            debug(@"[%s] Accepting incoming MUJI call from %s", account.bare_jid.to_string(), session.peer_full_jid.to_string());
                            peer_state.accept();
                        } else {
                            debug(@"[%s] Incoming call, but didn't see peer in MUC yet", account.bare_jid.to_string());
                            PeerState peer_state = new PeerState(session.peer_full_jid, call_state.call, call_state, stream_interactor);
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
            Call? call = null;
            foreach (PeerState peer_state in jmi_request_peer.values) {
                CallState call_state = call_states[peer_state.call];
                if (peer_state.sid == session.sid &&
                        call_state.call.account.equals(account) &&
                        peer_state.jid.equals_bare(session.peer_full_jid) &&
                        call_state.we_should_send_video == counterpart_wants_video &&
                        call_state.accepted) {
                    call = peer_state.call;
                    break;
                }
            }
            if (call != null) {
                jmi_request_peer[call].set_session(session);
                jmi_request_peer[call].accept();
                jmi_request_peer.unset(call);
                return;
            }

            // This is a direct call without prior JMI. Ask user.
            PeerState peer_state = create_received_call(account, session.peer_full_jid, account.full_jid, counterpart_wants_video);
            peer_state.set_session(session);
            stream_interactor.module_manager.get_module(account, Xep.JingleRtp.Module.IDENTITY).session_info_type.send_ringing(session);
        }

        private PeerState create_received_call(Account account, Jid from, Jid to, bool video_requested) {
            Call call = new Call();
            if (from.equals_bare(account.bare_jid)) {
                // Call requested by another of our devices
                call.direction = Call.DIRECTION_OUTGOING;
                call.ourpart = from;
                call.state = Call.State.OTHER_DEVICE;
                call.counterpart = to;
            } else {
                call.direction = Call.DIRECTION_INCOMING;
                call.ourpart = account.full_jid;
                call.state = Call.State.RINGING;
                call.counterpart = from;
            }
            call.add_peer(call.counterpart);
            call.account = account;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.encryption = Encryption.UNKNOWN;

            Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(call.counterpart.bare_jid, account, Conversation.Type.CHAT);
            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);
            conversation.last_active = call.time;

            var call_state = new CallState(call, stream_interactor);
            connect_call_state_signals(call_state);
            PeerState peer_state = call_state.set_first_peer(call.counterpart);
            call_state.we_should_send_video = video_requested;
            call_state.we_should_send_audio = true;

            if (call.direction == Call.DIRECTION_INCOMING) {
                call_incoming(call, call_state, conversation, video_requested);
            } else {
                call_outgoing(call, call_state, conversation);
            }

            return peer_state;
        }

        private CallState? get_call_state_by_invite_id(Account account, string invite_id, Jid jid1, Jid jid2) {
            Jid relevant_jid = jid1.equals_bare(account.bare_jid) ? jid2 : jid1;

            foreach (CallState call_state in call_states.values) {
                if (!call_state.call.account.equals(account)) continue;

                if (call_state.cim_invite_id == invite_id) {
                    foreach (Jid jid in call_state.peers.keys) {
                        if (jid.equals_bare(relevant_jid)) {
                            return call_state;
                        }
                    }
                }
                if (call_state.invited_to_group_call != null && call_state.invited_to_group_call.equals(relevant_jid)) return call_state;
            }
            return null;
        }

        private PeerState? get_peer_by_sid(Account account, string sid, Jid jid1, Jid jid2) {
            Jid relevant_jid = jid1.equals_bare(account.bare_jid) ? jid2 : jid1;

            foreach (CallState call_state in call_states.values) {
                if (!call_state.call.account.equals(account)) continue;

                foreach (PeerState peer_state in call_state.peers.values) {
                    if (peer_state.sid != sid) continue;
                    if (peer_state.jid.equals_bare(relevant_jid)) {
                        return peer_state;
                    }
                }
            }
            return null;
        }

        private CallState? create_recv_muji_call(Account account, Jid inviter_jid, Jid muc_jid, string invite_id, string message_type) {
            debug("[%s] Muji call received from %s for MUC %s, type %s", account.bare_jid.to_string(), inviter_jid.to_string(), muc_jid.to_string(), message_type);

            foreach (Call call in call_states.keys) {
                if (!call.account.equals(account)) return null;

                CallState call_state = call_states[call];

                // If this is a MUC reflection of our own invite, store the sid assigned by the MUC
                if (call_state.parent_muc != null && call_state.parent_muc.equals_bare(inviter_jid)) {
                    call_state.cim_invite_id = invite_id;
                    return null;
                }

                if (call.counterparts.contains(inviter_jid) && call_state.accepted) {
                    // A call is converted into a group call.
                    call_state.join_group_call.begin(muc_jid);
                    return null;
                }
            }

            Call call = new Call();
            call.direction = Call.DIRECTION_INCOMING;
            call.ourpart = account.full_jid;
            call.counterpart = inviter_jid;
            call.account = account;
            call.time = call.local_time = call.end_time = new DateTime.now_utc();
            call.encryption = Encryption.UNKNOWN;
            call.state = Call.State.RINGING;

            // TODO create conv
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(inviter_jid.bare_jid, account);
            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);
            conversation.last_active = call.time;

            CallState call_state = new CallState(call, stream_interactor);
            connect_call_state_signals(call_state);
            call_state.invited_to_group_call = muc_jid;
            call_state.parent_muc = inviter_jid.bare_jid;

            debug("[%s] on_muji_call_received accepting", account.bare_jid.to_string());

            return call_state;
        }

        private void remove_call_from_datastructures(Call call) {
            jmi_request_peer.unset(call);
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
                bool audio_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "audio");
                bool video_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "video");
                if (!audio_requested && !video_requested) return;

                PeerState peer_state = create_received_call(account, from, to, video_requested);
                peer_state.sid = sid;

                CallState call_state = call_states[peer_state.call];
                call_state.we_should_send_audio = true;
                call_state.we_should_send_video = video_requested;

                jmi_request_peer[call_state.call] = peer_state;
            });
            mi_module.session_accepted.connect((from, to, sid) => {
                PeerState? peer_state = get_peer_by_sid(account, sid, from, to);
                if (peer_state == null) return;
                Call call = peer_state.call;

                if (from.equals_bare(account.bare_jid)) { // Carboned message from our account
                    // Ignore carbon from ourselves
                    if (from.equals(account.full_jid)) return;

                    call.ourpart = from;
                    call.state = Call.State.OTHER_DEVICE;
                    remove_call_from_datastructures(call);
                } else if (from.equals_bare(peer_state.jid) && to.equals(account.full_jid)) { // Message from our peer
                    // We proposed the call
                    // We know the full jid of our peer now
                    call_states[call].rename_peer(jmi_request_peer[call].jid, from);
                    jmi_request_peer[call].call_resource.begin(from);
                }
            });
            mi_module.session_rejected.connect((from, to, sid) => {
                PeerState? peer_state = get_peer_by_sid(account, sid, from, to);
                if (peer_state == null) return;
                Call call = peer_state.call;

                bool outgoing_reject = call.direction == Call.DIRECTION_OUTGOING && from.equals_bare(call.counterparts[0]);
                bool incoming_reject = call.direction == Call.DIRECTION_INCOMING && from.equals_bare(account.bare_jid);
                if (!outgoing_reject && !incoming_reject) return;

                // We don't care if a single person in a group call rejected the call
                if (incoming_reject && call_states[call].group_call != null) return;

                call.state = Call.State.DECLINED;
                call_states[call].terminated(from, Xep.Jingle.ReasonElement.DECLINE, "JMI reject");
                remove_call_from_datastructures(call);
            });
            mi_module.session_retracted.connect((from, to, sid) => {
                PeerState? peer_state = get_peer_by_sid(account, sid, from, to);
                if (peer_state == null) return;
                Call call = peer_state.call;

                bool outgoing_retract = call.direction == Call.DIRECTION_OUTGOING && from.equals_bare(account.bare_jid);
                bool incoming_retract = call.direction == Call.DIRECTION_INCOMING && from.equals_bare(call.counterpart);
                if (!(outgoing_retract || incoming_retract)) return;

                call.state = Call.State.MISSED;
                call_states[call].terminated(from, Xep.Jingle.ReasonElement.CANCEL, "JMI retract");
                remove_call_from_datastructures(call);
            });

            Xep.CallInvites.Module call_invites_module = stream_interactor.module_manager.get_module(account, Xep.CallInvites.Module.IDENTITY);
            call_invites_module.call_proposed.connect((from_jid, to_jid, video_requested, join_methods, message_stanza) => {
                if (from_jid.equals_bare(account.bare_jid)) return;

                string? invite_id = null;
                if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
                    invite_id = Xep.UniqueStableStanzaIDs.get_stanza_id(message_stanza, from_jid.bare_jid);
                } else {
                    invite_id = message_stanza.id;
                }
                if (invite_id == null) {
                    warning("Got call invite without ID");
                    return;
                }

                CallState? call_state = null;

                foreach (StanzaNode join_method_node in join_methods) {
                    if (join_method_node.name == "muji" && join_method_node.ns_uri == Xep.Muji.NS_URI) {

                        // This is a MUJI invite
                        string? room_jid_str = join_method_node.get_attribute("room");
                        if (room_jid_str == null) return;
                        Jid room_jid = new Jid(room_jid_str);
                        call_state = create_recv_muji_call(account, from_jid, room_jid, invite_id, message_stanza.type_);
                        break;

                    } else if (join_method_node.name == "jingle" && join_method_node.ns_uri == Xep.CallInvites.NS_URI) {

                        // This is an invite for a direct Jingle session
                        if (message_stanza.type_ != Xmpp.MessageStanza.TYPE_CHAT) return;

                        string? sid = join_method_node.get_attribute("sid");
                        if (sid == null) return;

                        PeerState peer_state = create_received_call(account, from_jid, to_jid, video_requested);
                        peer_state.sid = sid;

                        call_state = call_states[peer_state.call];

                        jmi_request_peer[call_state.call] = peer_state;
                        break;
                    }
                }


                if (call_state == null) return;

                call_state.we_should_send_audio = true;
                call_state.we_should_send_video = video_requested;

                call_state.use_cim = true;
                call_state.cim_invite_id = invite_id;
                call_state.cim_counterpart = message_stanza.type_ == MessageStanza.TYPE_GROUPCHAT ? from_jid.bare_jid : from_jid;
                call_state.cim_message_type = message_stanza.type_;

                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).approx_conversation_for_stanza(from_jid, to_jid, account, message_stanza.type_);
                conversation.last_active = call_state.call.time;
                if (conversation == null) return;

                call_incoming(call_state.call, call_state, conversation, video_requested);
            });
            call_invites_module.call_accepted.connect((from_jid, to_jid, invite_id, message_type) => {
                CallState? call_state = get_call_state_by_invite_id(account, invite_id, from_jid, to_jid);
                if (call_state == null) return;
                Call call = call_state.call;

                if (from_jid.equals_bare(account.bare_jid)) { // Carboned message from our account
                    // Ignore carbon from ourselves
                    if (from_jid.equals(account.full_jid)) return;

                    // We accepted the call from another device
                    call.ourpart = from_jid;
                    call.state = Call.State.OTHER_DEVICE;
                    remove_call_from_datastructures(call);
                } else if (to_jid.equals(account.full_jid)) { // Message from our peer
                    // We proposed the call
                    // We know the full jid of our peer now
                    call_states[call].rename_peer(jmi_request_peer[call].jid, from_jid);
                    jmi_request_peer[call].call_resource.begin(from_jid);
                }
            });
            call_invites_module.call_retracted.connect((from_jid, to_jid, invite_id, message_type) => {
                if (from_jid.equals_bare(account.bare_jid)) return;

                // The call was retracted by the counterpart
                CallState? call_state = get_call_state_by_invite_id(account, invite_id, from_jid, to_jid);
                if (call_state == null) return;

                if (call_state.call.state != Call.State.RINGING) {
                    debug("%s tried to retract a call that's in state %s. Ignoring.", from_jid.to_string(), call_state.call.state.to_string());
                    return;
                }

                // TODO prevent other MUC occupants from retracting a call

                call_state.call.state = Call.State.MISSED;
                remove_call_from_datastructures(call_state.call);
            });
            call_invites_module.call_rejected.connect((from_jid, to_jid, muc_jid, message_type) => {
                if (from_jid.equals_bare(account.bare_jid)) return;
                debug(@"[%s] %s rejected our MUJI invite to %s", account.bare_jid.to_string(), from_jid.to_string(), muc_jid.to_string());
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