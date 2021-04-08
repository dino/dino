using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

    public class Calls : StreamInteractionModule, Object {

        public signal void call_incoming(Call call, Conversation conversation, bool video);
        public signal void call_outgoing(Call call, Conversation conversation);

        public signal void call_terminated(Call call, string? reason_name, string? reason_text);
        public signal void counterpart_ringing(Call call);
        public signal void counterpart_sends_video_updated(Call call, bool mute);
        public signal void info_received(Call call, Xep.JingleRtp.CallSessionInfo session_info);
        public signal void encryption_updated(Call call, Xep.Jingle.ContentEncryption? encryption);

        public signal void stream_created(Call call, string media);

        public static ModuleIdentity<Calls> IDENTITY = new ModuleIdentity<Calls>("calls");
        public string id { get { return IDENTITY.id; } }

        private StreamInteractor stream_interactor;
        private Database db;

        private HashMap<Account, HashMap<Call, string>> sid_by_call = new HashMap<Account, HashMap<Call, string>>(Account.hash_func, Account.equals_func);
        private HashMap<Account, HashMap<string, Call>> call_by_sid = new HashMap<Account, HashMap<string, Call>>(Account.hash_func, Account.equals_func);
        public HashMap<Call, Xep.Jingle.Session> sessions = new HashMap<Call, Xep.Jingle.Session>(Call.hash_func, Call.equals_func);

        public HashMap<Account, Call> jmi_call = new HashMap<Account, Call>(Account.hash_func, Account.equals_func);
        public HashMap<Account, string> jmi_sid = new HashMap<Account, string>(Account.hash_func, Account.equals_func);
        public HashMap<Account, bool> jmi_video = new HashMap<Account, bool>(Account.hash_func, Account.equals_func);

        private HashMap<Call, bool> counterpart_sends_video = new HashMap<Call, bool>(Call.hash_func, Call.equals_func);
        private HashMap<Call, bool> we_should_send_video = new HashMap<Call, bool>(Call.hash_func, Call.equals_func);
        private HashMap<Call, bool> we_should_send_audio = new HashMap<Call, bool>(Call.hash_func, Call.equals_func);

        private HashMap<Call, Xep.JingleRtp.Parameters> audio_content_parameter = new HashMap<Call, Xep.JingleRtp.Parameters>(Call.hash_func, Call.equals_func);
        private HashMap<Call, Xep.JingleRtp.Parameters> video_content_parameter = new HashMap<Call, Xep.JingleRtp.Parameters>(Call.hash_func, Call.equals_func);
        private HashMap<Call, Xep.Jingle.Content> audio_content = new HashMap<Call, Xep.Jingle.Content>(Call.hash_func, Call.equals_func);
        private HashMap<Call, Xep.Jingle.Content> video_content = new HashMap<Call, Xep.Jingle.Content>(Call.hash_func, Call.equals_func);
        private HashMap<Call, Xep.Jingle.ContentEncryption> video_encryption = new HashMap<Call, Xep.Jingle.ContentEncryption>(Call.hash_func, Call.equals_func);
        private HashMap<Call, Xep.Jingle.ContentEncryption> audio_encryption = new HashMap<Call, Xep.Jingle.ContentEncryption>(Call.hash_func, Call.equals_func);

        public static void start(StreamInteractor stream_interactor, Database db) {
            Calls m = new Calls(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        private Calls(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;

            stream_interactor.account_added.connect(on_account_added);
        }

        public Xep.JingleRtp.Stream? get_video_stream(Call call) {
            if (video_content_parameter.has_key(call)) {
                return video_content_parameter[call].stream;
            }
            return null;
        }

        public Xep.JingleRtp.Stream? get_audio_stream(Call call) {
            if (audio_content_parameter.has_key(call)) {
                return audio_content_parameter[call].stream;
            }
            return null;
        }

        public async Call? initiate_call(Conversation conversation, bool video) {
            Call call = new Call();
            call.direction = Call.DIRECTION_OUTGOING;
            call.account = conversation.account;
            call.counterpart = conversation.counterpart;
            call.ourpart = conversation.account.full_jid;
            call.time = call.local_time = new DateTime.now_utc();
            call.state = Call.State.RINGING;

            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);

            we_should_send_video[call] = video;
            we_should_send_audio[call] = true;

            if (yield has_jmi_resources(conversation)) {
                XmppStream? stream = stream_interactor.get_stream(conversation.account);
                jmi_call[conversation.account] = call;
                jmi_video[conversation.account] = video;
                jmi_sid[conversation.account] = Xmpp.random_uuid();

                call_by_sid[call.account][jmi_sid[conversation.account]] = call;

                var descriptions = new ArrayList<StanzaNode>();
                descriptions.add(new StanzaNode.build("description", "urn:xmpp:jingle:apps:rtp:1").add_self_xmlns().put_attribute("media", "audio"));
                if (video) {
                    descriptions.add(new StanzaNode.build("description", "urn:xmpp:jingle:apps:rtp:1").add_self_xmlns().put_attribute("media", "video"));
                }

                stream.get_module(Xmpp.Xep.JingleMessageInitiation.Module.IDENTITY).send_session_propose_to_peer(stream, conversation.counterpart, jmi_sid[call.account], descriptions);
            } else {
                Gee.List<Jid> call_resources = yield get_call_resources(conversation);
                if (call_resources.size == 0) {
                    warning("No call resources");
                    return null;
                }
                yield call_resource(conversation.account, call_resources[0], call, video);
            }

            conversation.last_active = call.time;
            call_outgoing(call, conversation);

            return call;
        }

        private async void call_resource(Account account, Jid full_jid, Call call, bool video, string? sid = null) {
            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return;

            Xep.Jingle.Session session = yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).start_call(stream, full_jid, video, sid);
            sessions[call] = session;
            sid_by_call[call.account][call] = session.sid;

            connect_session_signals(call, session);
        }

        public void end_call(Conversation conversation, Call call) {
            XmppStream? stream = stream_interactor.get_stream(call.account);
            if (stream == null) return;

            if (call.state == Call.State.IN_PROGRESS || call.state == Call.State.ESTABLISHING) {
                sessions[call].terminate(Xep.Jingle.ReasonElement.SUCCESS, null, "success");
                call.state = Call.State.ENDED;
            } else if (call.state == Call.State.RINGING) {
                if (sessions.has_key(call)) {
                    sessions[call].terminate(Xep.Jingle.ReasonElement.CANCEL, null, "cancel");
                } else {
                    // Only a JMI so far
                }
                call.state = Call.State.MISSED;
            } else {
                return;
            }

            call.end_time = new DateTime.now_utc();

            remove_call_from_datastructures(call);
        }

        public void accept_call(Call call) {
            call.state = Call.State.ESTABLISHING;

            if (sessions.has_key(call)) {
                foreach (Xep.Jingle.Content content in sessions[call].contents) {
                    content.accept();
                }
            } else {
                // Only a JMI so far
                Account account = call.account;
                string sid = sid_by_call[call.account][call];
                XmppStream stream = stream_interactor.get_stream(account);
                if (stream == null) return;

                jmi_call[account] = call;
                jmi_sid[account] = sid;
                jmi_video[account] = we_should_send_video[call];

                stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_accept_to_self(stream, sid);
                stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_proceed_to_peer(stream, call.counterpart, sid);
            }
        }

        public void reject_call(Call call) {
            call.state = Call.State.DECLINED;

            if (sessions.has_key(call)) {
                foreach (Xep.Jingle.Content content in sessions[call].contents) {
                    content.reject();
                }
                remove_call_from_datastructures(call);
            } else {
                // Only a JMI so far
                XmppStream stream = stream_interactor.get_stream(call.account);
                if (stream == null) return;

                string sid = sid_by_call[call.account][call];
                stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_reject_to_self(stream, sid);
                stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_reject_to_peer(stream, call.counterpart, sid);
                remove_call_from_datastructures(call);
            }
        }

        public void mute_own_audio(Call call, bool mute) {
            we_should_send_audio[call] = !mute;

            Xep.JingleRtp.Stream stream = audio_content_parameter[call].stream;
            // The user might mute audio before a feed was created. The feed will be muted as soon as it has been created.
            if (stream == null) return;

            // Inform our counterpart that we (un)muted our audio
            stream_interactor.module_manager.get_module(call.account, Xep.JingleRtp.Module.IDENTITY).session_info_type.send_mute(sessions[call], mute, "audio");

            // Start/Stop sending audio data
            Application.get_default().plugin_registry.video_call_plugin.set_pause(stream, mute);
        }

        public void mute_own_video(Call call, bool mute) {
            we_should_send_video[call] = !mute;

            Xep.JingleRtp.Module rtp_module = stream_interactor.module_manager.get_module(call.account, Xep.JingleRtp.Module.IDENTITY);

            if (video_content_parameter.has_key(call) &&
                    video_content_parameter[call].stream != null &&
                    sessions[call].senders_include_us(video_content[call].senders)) {
                // A video feed has already been established

                // Start/Stop sending video data
                Xep.JingleRtp.Stream stream = video_content_parameter[call].stream;
                if (stream != null) {
                    // TODO maybe the user muted video before the feed was created...
                    Application.get_default().plugin_registry.video_call_plugin.set_pause(stream, mute);
                }

                // Inform our counterpart that we started/stopped our video
                rtp_module.session_info_type.send_mute(sessions[call], mute, "video");
            } else if (!mute) {
                // Need to start a new video feed
                XmppStream stream = stream_interactor.get_stream(call.account);
                rtp_module.add_outgoing_video_content.begin(stream, sessions[call], (_, res) => {
                    if (video_content_parameter[call] == null) {
                        Xep.Jingle.Content content = rtp_module.add_outgoing_video_content.end(res);
                        Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                        if (rtp_content_parameter != null) {
                            connect_content_signals(call, content, rtp_content_parameter);
                        }
                    }
                });
            }
            // If video_feed == null && !mute we're trying to mute a non-existant feed. It will be muted as soon as it is created.
        }

        public async bool can_do_calls(Conversation conversation) {
            return (yield get_call_resources(conversation)).size > 0 || yield has_jmi_resources(conversation);
        }

        private async Gee.List<Jid> get_call_resources(Conversation conversation) {
            ArrayList<Jid> ret = new ArrayList<Jid>();

            XmppStream? stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) return ret;

            Gee.List<Jid>? full_jids = stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart);
            if (full_jids == null) return ret;

            foreach (Jid full_jid in full_jids) {
                bool supports_rtc = yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).is_available(stream, full_jid);
                if (!supports_rtc) continue;
                ret.add(full_jid);
            }
            return ret;
        }

        private async bool has_jmi_resources(Conversation conversation) {
            int64 jmi_resources = db.entity.select()
                    .with(db.entity.jid_id, "=", db.get_jid_id(conversation.counterpart))
                    .join_with(db.entity_feature, db.entity.caps_hash, db.entity_feature.entity)
                    .with(db.entity_feature.feature, "=", Xep.JingleMessageInitiation.NS_URI)
                    .count();
            return jmi_resources > 0;
        }

        public bool should_we_send_video(Call call) {
            return we_should_send_video[call];
        }

        public Jid? is_call_in_progress() {
            foreach (Call call in sessions.keys) {
                if (call.state == Call.State.IN_PROGRESS || call.state == Call.State.RINGING || call.state == Call.State.ESTABLISHING) {
                    return call.counterpart;
                }
            }
            return null;
        }

        private void on_incoming_call(Account account, Xep.Jingle.Session session) {
            bool counterpart_wants_video = false;
            foreach (Xep.Jingle.Content content in session.contents) {
                Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                if (rtp_content_parameter == null) continue;
                if (rtp_content_parameter.media == "video" && session.senders_include_us(content.senders)) {
                    counterpart_wants_video = true;
                }
            }

            // Session might have already been accepted via Jingle Message Initiation
            bool already_accepted = jmi_sid.has_key(account) &&
                    jmi_sid[account] == session.sid && jmi_call[account].account.equals(account) &&
                    jmi_call[account].counterpart.equals_bare(session.peer_full_jid) &&
                    jmi_video[account] == counterpart_wants_video;

            Call? call = null;
            if (already_accepted) {
                call = jmi_call[account];
            } else {
                call = create_received_call(account, session.peer_full_jid, account.full_jid, counterpart_wants_video);
            }
            sessions[call] = session;

            call_by_sid[account][session.sid] = call;
            sid_by_call[account][call] = session.sid;

            connect_session_signals(call, session);

            if (already_accepted) {
                accept_call(call);
            } else {
                stream_interactor.module_manager.get_module(account, Xep.JingleRtp.Module.IDENTITY).session_info_type.send_ringing(session);
            }
        }

        private Call create_received_call(Account account, Jid from, Jid to, bool video_requested) {
            Call call = new Call();
            if (from.equals_bare(account.bare_jid)) {
                // Call requested by another of our devices
                call.direction = Call.DIRECTION_OUTGOING;
                call.ourpart = from;
                call.counterpart = to;
            } else {
                call.direction = Call.DIRECTION_INCOMING;
                call.ourpart = account.full_jid;
                call.counterpart = from;
            }
            call.account = account;
            call.time = call.local_time = new DateTime.now_utc();
            call.state = Call.State.RINGING;

            Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(call.counterpart.bare_jid, account, Conversation.Type.CHAT);

            stream_interactor.get_module(CallStore.IDENTITY).add_call(call, conversation);

            conversation.last_active = call.time;

            we_should_send_video[call] = video_requested;
            we_should_send_audio[call] = true;

            if (call.direction == Call.DIRECTION_INCOMING) {
                call_incoming(call, conversation, video_requested);
            } else {
                call_outgoing(call, conversation);
            }

            return call;
        }

        private void on_incoming_content_add(XmppStream stream, Call call, Xep.Jingle.Session session, Xep.Jingle.Content content) {
            Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;

            if (rtp_content_parameter == null || session.senders_include_us(content.senders)) {
                content.reject();
                return;
            }

            connect_content_signals(call, content, rtp_content_parameter);
            content.accept();
        }

        private void on_connection_ready(Call call) {
            if (call.state == Call.State.RINGING || call.state == Call.State.ESTABLISHING) {
                call.state = Call.State.IN_PROGRESS;
            }
            update_call_encryption(call);
        }

        private void on_call_terminated(Call call, bool we_terminated, string? reason_name, string? reason_text) {
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

            call_terminated(call, reason_name, reason_text);
            remove_call_from_datastructures(call);
        }

        private void on_stream_created(Call call, string media, Xep.JingleRtp.Stream stream) {
            if (media == "video" && stream.receiving) {
                counterpart_sends_video[call] = true;
                video_content_parameter[call].connection_ready.connect((status) => {
                    counterpart_sends_video_updated(call, false);
                });
            }
            stream_created(call, media);

            // Outgoing audio/video might have been muted in the meanwhile.
            if (media == "video" && !we_should_send_video[call]) {
                mute_own_video(call, true);
            } else if (media == "audio" && !we_should_send_audio[call]) {
                mute_own_audio(call, true);
            }
        }

        private void on_counterpart_mute_update(Call call, bool mute, string? media) {
            if (!call.equals(call)) return;

            if (media == "video") {
                counterpart_sends_video[call] = !mute;
                counterpart_sends_video_updated(call, mute);
            }
        }

        private void connect_session_signals(Call call, Xep.Jingle.Session session) {
            session.terminated.connect((stream, we_terminated, reason_name, reason_text) =>
                on_call_terminated(call, we_terminated, reason_name, reason_text)
            );
            session.additional_content_add_incoming.connect((session,stream, content) =>
                on_incoming_content_add(stream, call, session, content)
            );

            foreach (Xep.Jingle.Content content in session.contents) {
                Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                if (rtp_content_parameter == null) continue;

                connect_content_signals(call, content, rtp_content_parameter);
            }
        }

        private void connect_content_signals(Call call, Xep.Jingle.Content content, Xep.JingleRtp.Parameters rtp_content_parameter) {
            if (rtp_content_parameter.media == "audio") {
                audio_content[call] = content;
                audio_content_parameter[call] = rtp_content_parameter;
            } else if (rtp_content_parameter.media == "video") {
                video_content[call] = content;
                video_content_parameter[call] = rtp_content_parameter;
            }

            rtp_content_parameter.stream_created.connect((stream) => on_stream_created(call, rtp_content_parameter.media, stream));
            rtp_content_parameter.connection_ready.connect((status) => on_connection_ready(call));

            content.senders_modify_incoming.connect((content, proposed_senders) => {
                if (content.session.senders_include_us(content.senders) != content.session.senders_include_us(proposed_senders)) {
                    warning("counterpart set us to (not)sending %s. ignoring", content.content_name);
                    return;
                }

                if (!content.session.senders_include_counterpart(content.senders) && content.session.senders_include_counterpart(proposed_senders)) {
                    // Counterpart wants to start sending. Ok.
                    content.accept_content_modify(proposed_senders);
                    on_counterpart_mute_update(call, false, "video");
                }
            });

            content.notify["encryption"].connect((obj, _) => {
                if (rtp_content_parameter.media == "audio") {
                    audio_encryption[call] = ((Xep.Jingle.Content) obj).encryption;
                } else if (rtp_content_parameter.media == "video") {
                    video_encryption[call] = ((Xep.Jingle.Content) obj).encryption;
                }
            });
        }

        private void update_call_encryption(Call call) {
            if (audio_encryption[call] == null) {
                call.encryption = Encryption.NONE;
                encryption_updated(call, null);
                return;
            }

            bool consistent_encryption = video_encryption[call] != null && audio_encryption[call].encryption_ns == video_encryption[call].encryption_ns;

            if (video_content[call] == null || consistent_encryption) {
                if (audio_encryption[call].encryption_ns == Xep.JingleIceUdp.DTLS_NS_URI) {
                    call.encryption = Encryption.DTLS_SRTP;
                } else if (audio_encryption[call].encryption_name == "SRTP") {
                    call.encryption = Encryption.SRTP;
                }
                encryption_updated(call, audio_encryption[call]);
            } else {
                call.encryption = Encryption.NONE;
                encryption_updated(call, null);
            }
        }

        private void remove_call_from_datastructures(Call call) {
            string? sid = sid_by_call[call.account][call];
            sid_by_call[call.account].unset(call);
            if (sid != null) call_by_sid[call.account].unset(sid);

            sessions.unset(call);

            counterpart_sends_video.unset(call);
            we_should_send_video.unset(call);
            we_should_send_audio.unset(call);

            audio_content_parameter.unset(call);
            video_content_parameter.unset(call);
            audio_content.unset(call);
            video_content.unset(call);
            audio_encryption.unset(call);
            video_encryption.unset(call);
        }

        private void on_account_added(Account account) {
            call_by_sid[account] = new HashMap<string, Call>();
            sid_by_call[account] = new HashMap<Call, string>();

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

            var session_info_type = stream_interactor.module_manager.get_module(account, Xep.JingleRtp.Module.IDENTITY).session_info_type;
            session_info_type.mute_update_received.connect((session,mute, name) => {
                if (!call_by_sid[account].has_key(session.sid)) return;
                Call call = call_by_sid[account][session.sid];

                foreach (Xep.Jingle.Content content in session.contents) {
                    if (name == null || content.content_name == name) {
                        Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                        if (rtp_content_parameter != null) {
                            on_counterpart_mute_update(call, mute, rtp_content_parameter.media);
                        }
                    }
                }
            });
            session_info_type.info_received.connect((session, session_info) => {
                if (!call_by_sid[account].has_key(session.sid)) return;
                Call call = call_by_sid[account][session.sid];

                info_received(call, session_info);
            });

            Xep.JingleMessageInitiation.Module mi_module = stream_interactor.module_manager.get_module(account, Xep.JingleMessageInitiation.Module.IDENTITY);
            mi_module.session_proposed.connect((from, to, sid, descriptions) => {
                bool audio_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "audio");
                bool video_requested = descriptions.any_match((description) => description.ns_uri == Xep.JingleRtp.NS_URI && description.get_attribute("media") == "video");
                if (!audio_requested && !video_requested) return;
                Call call = create_received_call(account, from, to, video_requested);
                call_by_sid[account][sid] = call;
                sid_by_call[account][call] = sid;
            });
            mi_module.session_accepted.connect((from, sid) => {
                if (!call_by_sid[account].has_key(sid)) return;

                if (from.equals_bare(account.bare_jid)) { // Carboned message from our account
                    // Ignore carbon from ourselves
                    if (from.equals(account.full_jid)) return;

                    Call call = call_by_sid[account][sid];
                    call.state = Call.State.OTHER_DEVICE_ACCEPTED;
                    remove_call_from_datastructures(call);
                } else if (from.equals_bare(call_by_sid[account][sid].counterpart)) { // Message from our peer
                    // We proposed the call
                    if (jmi_sid.has_key(account) && jmi_sid[account] == sid) {
                        call_resource.begin(account, from, jmi_call[account], jmi_video[account], jmi_sid[account]);
                        jmi_call.unset(account);
                        jmi_sid.unset(account);
                        jmi_video.unset(account);
                    }
                }
            });
            mi_module.session_rejected.connect((from, to, sid) => {
                if (!call_by_sid[account].has_key(sid)) return;
                Call call = call_by_sid[account][sid];
                call.state = Call.State.DECLINED;
                remove_call_from_datastructures(call);
                call_terminated(call, null, null);
            });
            mi_module.session_retracted.connect((from, to, sid) => {
                if (!call_by_sid[account].has_key(sid)) return;
                Call call = call_by_sid[account][sid];
                call.state = Call.State.MISSED;
                remove_call_from_datastructures(call);
                call_terminated(call, null, null);
            });
        }
    }
}