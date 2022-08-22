using Dino.Entities;
using Gee;
using Xmpp;

public class Dino.PeerState : Object {
    public signal void stream_created(string media);
    public signal void counterpart_sends_video_updated(bool mute);
    public signal void info_received(Xep.JingleRtp.CallSessionInfo session_info);

    public signal void connection_ready();
    public signal void session_terminated(bool we_terminated, string? reason_name, string? reason_text);
    public signal void encryption_updated(Xep.Jingle.ContentEncryption? audio_encryption, Xep.Jingle.ContentEncryption? video_encryption, bool same);

    public StreamInteractor stream_interactor;
    public CallState call_state;
    public Calls calls;
    public Call call;
    public Jid jid;
    public Xep.Jingle.Session session;
    public string sid;
    public string internal_id = Xmpp.random_uuid();

    public Xep.JingleRtp.Parameters? audio_content_parameter = null;
    public Xep.JingleRtp.Parameters? video_content_parameter = null;
    public Xep.Jingle.Content? audio_content = null;
    public Xep.Jingle.Content? video_content = null;
    public Xep.Jingle.ContentEncryption? video_encryption = null;
    public Xep.Jingle.ContentEncryption? audio_encryption = null;
    public bool encryption_keys_same = false;
    public HashMap<string, Xep.Jingle.ContentEncryption>? video_encryptions = null;
    public HashMap<string, Xep.Jingle.ContentEncryption>? audio_encryptions = null;

    public bool first_peer = false;
    public bool waiting_for_inbound_muji_connection = false;
    public Xep.Muji.GroupCall? group_call { get; set; }

    public bool counterpart_sends_video = false;
    public bool we_should_send_audio { get; set; default=false; }
    public bool we_should_send_video { get; set; default=false; }

    public PeerState(Jid jid, Call call, CallState call_state, StreamInteractor stream_interactor) {
        this.jid = jid;
        this.call = call;
        this.call_state = call_state;
        this.stream_interactor = stream_interactor;
        this.calls = stream_interactor.get_module(Calls.IDENTITY);

        Xep.JingleRtp.Module jinglertp_module = stream_interactor.module_manager.get_module(call.account, Xep.JingleRtp.Module.IDENTITY);
        if (jinglertp_module == null) return;

        var session_info_type = jinglertp_module.session_info_type;
        session_info_type.mute_update_received.connect((session,mute, name) => {
            if (this.sid != session.sid) return;

            foreach (Xep.Jingle.Content content in session.contents) {
                if (name == null || content.content_name == name) {
                    Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                    if (rtp_content_parameter != null) {
                        on_counterpart_mute_update(mute, rtp_content_parameter.media);
                    }
                }
            }
        });
        session_info_type.info_received.connect((session, session_info) => {
            if (this.sid != session.sid) return;

            info_received(session_info);
        });
    }

    public async void initiate_call(Jid counterpart) {
        Gee.List<Jid> call_resources = yield calls.get_call_resources(call.account, counterpart);

        bool do_jmi = false;
        Jid? jid_for_direct = null;
        if (yield calls.contains_jmi_resources(call.account, call_resources)) {
            do_jmi = true;
        } else if (!call_resources.is_empty) {
            jid_for_direct = call_resources[0];
        } else if (calls.has_jmi_resources(jid)) {
            do_jmi = true;
        }

        sid = Xmpp.random_uuid();

        if (do_jmi) {
            XmppStream? stream = stream_interactor.get_stream(call.account);

            var descriptions = new ArrayList<StanzaNode>();
            descriptions.add(new StanzaNode.build("description", Xep.JingleRtp.NS_URI).add_self_xmlns().put_attribute("media", "audio"));
            if (we_should_send_video) {
                descriptions.add(new StanzaNode.build("description", Xep.JingleRtp.NS_URI).add_self_xmlns().put_attribute("media", "video"));
            }

            stream.get_module(Xmpp.Xep.JingleMessageInitiation.Module.IDENTITY).send_session_propose_to_peer(stream, jid, sid, descriptions);

//            Uncomment this use CIM instead of JMI
//            call_state.cim_call_id = sid;
//            stream.get_module(Xmpp.Xep.CallInvites.Module.IDENTITY).send_jingle_propose(stream, call_state.cim_call_id, jid, sid, we_should_send_video);
        } else if (jid_for_direct != null) {
            yield call_resource(jid_for_direct);
        }
    }

    public async void call_resource(Jid full_jid) {
        if (!call_state.accepted) {
            warning("Tried to call resource in an unaccepted call?!");
            return;
        }
        XmppStream? stream = stream_interactor.get_stream(call.account);
        if (stream == null) return;

        if (sid == null) sid = Xmpp.random_uuid();

        Xep.Jingle.Session session = yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).start_call(stream, full_jid, we_should_send_video, sid, group_call != null ? group_call.muc_jid : null);
        set_session(session);
    }

    public void accept() {
        if (!call_state.accepted) {
            critical("Tried to accept peer in unaccepted call?! Something's fishy. Abort.");
            return;
        }

        if (session != null) {
            foreach (Xep.Jingle.Content content in session.contents) {
                Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                if (rtp_content_parameter != null && rtp_content_parameter.media == "video") {
                    // We didn't accept video but our peer wants to negotiate that content
                    if (!we_should_send_video && session.senders_include_us(content.senders)) {
                        if (session.senders_include_counterpart(content.senders)) {
                            // If our peer wants to send, let them
                            content.modify(session.we_initiated ? Xep.Jingle.Senders.RESPONDER : Xep.Jingle.Senders.INITIATOR);
                        } else {
                            // If only we're supposed to send, reject
                            content.reject();
                            continue;
                        }
                    }
                }
                content.accept();
            }
        } else {
            // Only a JMI so far
            XmppStream stream = stream_interactor.get_stream(call.account);
            if (stream == null) return;

            stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_accept_to_self(stream, sid);
            stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_proceed_to_peer(stream, jid, sid);
        }
    }

    public void reject() {
        if (session != null) {
            foreach (Xep.Jingle.Content content in session.contents) {
                content.reject();
            }
        } else {
            // Only a JMI so far
            XmppStream stream = stream_interactor.get_stream(call.account);
            if (stream == null) return;

            stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_reject_to_peer(stream, jid, sid);
            stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_reject_to_self(stream, sid);
        }
    }

    public void end(string terminate_reason, string? reason_text = null) {
        switch (terminate_reason) {
            case Xep.Jingle.ReasonElement.SUCCESS:
                if (session != null) {
                    session.terminate(terminate_reason, reason_text, "success");
                }
                break;
            case Xep.Jingle.ReasonElement.CANCEL:
                if (session != null) {
                    session.terminate(terminate_reason, reason_text, "cancel");
                } else if (group_call != null) {
                    // We don't have to do anything (?)
                } else {
                    // Only a JMI so far
                    XmppStream? stream = stream_interactor.get_stream(call.account);
                    if (stream == null) return;
                    stream.get_module(Xep.JingleMessageInitiation.Module.IDENTITY).send_session_retract_to_peer(stream, jid, sid);
                }
                break;
        }
    }

    internal void mute_own_audio(bool mute) {
        // Call isn't fully established yet. Audio will be muted once the stream is created.
        if (session == null || audio_content_parameter == null || audio_content_parameter.stream == null) return;

        Xep.JingleRtp.Stream stream = audio_content_parameter.stream;

        // Inform our counterpart that we (un)muted our audio
        stream_interactor.module_manager.get_module(call.account, Xep.JingleRtp.Module.IDENTITY).session_info_type.send_mute(session, mute, "audio");

        // Start/Stop sending audio data
        Application.get_default().plugin_registry.video_call_plugin.set_pause(stream, mute);
    }

    internal void mute_own_video(bool mute) {

        if (session == null) {
            // Call hasn't been established yet
            return;
        }

        Xep.JingleRtp.Module rtp_module = stream_interactor.module_manager.get_module(call.account, Xep.JingleRtp.Module.IDENTITY);

        if (video_content_parameter != null &&
                video_content_parameter.stream != null &&
                session.senders_include_us(video_content.senders)) {
            // A video content already exists

            // Start/Stop sending video data
            Xep.JingleRtp.Stream stream = video_content_parameter.stream;
            if (stream != null) {
                Application.get_default().plugin_registry.video_call_plugin.set_pause(stream, mute);
            }

            // Inform our counterpart that we started/stopped our video
            rtp_module.session_info_type.send_mute(session, mute, "video");
        } else if (!mute) {
            // Add a new video content
            XmppStream stream = stream_interactor.get_stream(call.account);
            rtp_module.add_outgoing_video_content.begin(stream, session, group_call != null ? group_call.muc_jid : null, (_, res) => {
                if (video_content_parameter == null) {
                    Xep.Jingle.Content content = rtp_module.add_outgoing_video_content.end(res);
                    Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
                    if (rtp_content_parameter != null) {
                        connect_content_signals(content, rtp_content_parameter);
                    }
                }
            });
        }
        // If video_content_parameter == null && !mute we're trying to mute a non-existant feed. It will be muted as soon as it is created.
    }

    public Xep.JingleRtp.Stream? get_video_stream() {
        if (video_content_parameter != null) {
            return video_content_parameter.stream;
        }
        return null;
    }

    public Xep.JingleRtp.Stream? get_audio_stream() {
        if (audio_content_parameter != null) {
            return audio_content_parameter.stream;
        }
        return null;
    }

    internal void set_session(Xep.Jingle.Session session) {
        this.session = session;
        this.sid = session.sid;

        session.terminated.connect((stream, we_terminated, reason_name, reason_text) =>
            session_terminated(we_terminated, reason_name, reason_text)
        );
        session.additional_content_add_incoming.connect((stream, content) =>
            on_incoming_content_add(stream, content.session, content)
        );

        foreach (Xep.Jingle.Content content in session.contents) {
            Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;
            if (rtp_content_parameter == null) continue;

            connect_content_signals(content, rtp_content_parameter);
        }
    }

    public PeerInfo get_info() {
        var ret = new PeerInfo();
        if (audio_content != null || audio_content_parameter != null) {
            ret.audio = get_content_info(audio_content, audio_content_parameter);
        }
        if (video_content != null || video_content_parameter != null) {
            ret.video = get_content_info(video_content, video_content_parameter);
        }
        return ret;
    }

    private PeerContentInfo get_content_info(Xep.Jingle.Content? content, Xep.JingleRtp.Parameters? parameter) {
        PeerContentInfo ret = new PeerContentInfo();
        if (parameter != null) {
            ret.rtcp_ready = parameter.rtcp_ready;
            ret.rtp_ready = parameter.rtp_ready;

            if (parameter.agreed_payload_type != null) {
                ret.codec = parameter.agreed_payload_type.name;
                ret.clockrate = parameter.agreed_payload_type.clockrate;
            }
            if (parameter.stream != null && parameter.stream.remb_enabled) {
                ret.target_receive_bytes = parameter.stream.target_receive_bitrate;
                ret.target_send_bytes = parameter.stream.target_send_bitrate;
            }
        }

        if (content != null) {
            Xmpp.Xep.Jingle.ComponentConnection? component0 = content.get_transport_connection(1);
            if (component0 != null) {
                ret.bytes_received = component0.bytes_received;
                ret.bytes_sent = component0.bytes_sent;
            }
        }
        return ret;
    }



    private void connect_content_signals(Xep.Jingle.Content content, Xep.JingleRtp.Parameters rtp_content_parameter) {
        if (rtp_content_parameter.media == "audio") {
            audio_content = content;
            audio_content_parameter = rtp_content_parameter;
        } else if (rtp_content_parameter.media == "video") {
            video_content = content;
            video_content_parameter = rtp_content_parameter;
        }

        debug(@"[%s] %s connecting content signals %s", call.account.bare_jid.to_string(), jid.to_string(), rtp_content_parameter.media);
        rtp_content_parameter.stream_created.connect((stream) => on_stream_created(rtp_content_parameter.media, stream));
        rtp_content_parameter.connection_ready.connect((status) => {
            Idle.add(() => {
                on_connection_ready(content, rtp_content_parameter.media);
                return false;
            });
        });

        content.senders_modify_incoming.connect((content, proposed_senders) => {
            if (content.session.senders_include_us(content.senders) != content.session.senders_include_us(proposed_senders)) {
                warning("counterpart set us to (not)sending %s. ignoring", content.content_name);
                return;
            }

            if (!content.session.senders_include_counterpart(content.senders) && content.session.senders_include_counterpart(proposed_senders)) {
                // Counterpart wants to start sending. Ok.
                content.accept_content_modify(proposed_senders);
                on_counterpart_mute_update(false, "video");
            }
        });
    }

    private void on_incoming_content_add(XmppStream stream, Xep.Jingle.Session session, Xep.Jingle.Content content) {
        Xep.JingleRtp.Parameters? rtp_content_parameter = content.content_params as Xep.JingleRtp.Parameters;

        if (rtp_content_parameter == null) {
            content.reject();
            return;
        }

        // Our peer shouldn't tell us to start sending, that's for us to initiate
        if (session.senders_include_us(content.senders)) {
            if (session.senders_include_counterpart(content.senders)) {
                // If our peer wants to send, let them
                content.modify(session.we_initiated ? Xep.Jingle.Senders.RESPONDER : Xep.Jingle.Senders.INITIATOR);
            } else {
                // If only we're supposed to send, reject
                content.reject();
            }
        }

        connect_content_signals(content, rtp_content_parameter);
        content.accept();
    }

    private void on_stream_created(string media, Xep.JingleRtp.Stream stream) {
        if (media == "video" && stream.receiving) {
            counterpart_sends_video = true;
            video_content_parameter.connection_ready.connect((status) => {
                Idle.add(() => {
                    counterpart_sends_video_updated(false);
                    return false;
                });
            });
        }

        // Outgoing audio/video might have been muted in the meanwhile.
        if (media == "video" && !we_should_send_video) {
            mute_own_video(true);
        } else if (media == "audio" && !we_should_send_audio) {
            mute_own_audio(true);
        }

        stream_created(media);
    }

    private void on_counterpart_mute_update(bool mute, string? media) {
        if (!call.equals(call)) return;

        if (media == "video") {
            counterpart_sends_video = !mute;
            debug(@"[%s] %s video muted %s", call.account.bare_jid.to_string(), jid.to_string(), mute.to_string());
            counterpart_sends_video_updated(mute);
        }
    }

    private void on_connection_ready(Xep.Jingle.Content content, string media) {
        debug("[%s] %s on_connection_ready", call.account.bare_jid.to_string(), jid.to_string());
        connection_ready();

        if (call.state == Call.State.RINGING || call.state == Call.State.ESTABLISHING) {
            call.state = Call.State.IN_PROGRESS;
        }

        if (media == "audio") {
            audio_encryptions = content.encryptions;
        } else if (media == "video") {
            video_encryptions = content.encryptions;
        }

        if ((audio_encryptions != null && audio_encryptions.is_empty) || (video_encryptions != null && video_encryptions.is_empty)) {
            call.encryption = Encryption.NONE;
            encryption_updated(null, null, true);
            return;
        }

        HashMap<string, Xep.Jingle.ContentEncryption> encryptions = audio_encryptions ?? video_encryptions;

        Xep.Jingle.ContentEncryption? omemo_encryption = null, dtls_encryption = null, srtp_encryption = null;
        foreach (string encr_name in encryptions.keys) {
            if (video_encryptions != null && !video_encryptions.has_key(encr_name)) continue;

            var encryption = encryptions[encr_name];
            if (encryption.encryption_ns == "http://gultsch.de/xmpp/drafts/omemo/dlts-srtp-verification") {
                omemo_encryption = encryption;
            } else if (encryption.encryption_ns == Xep.JingleIceUdp.DTLS_NS_URI) {
                dtls_encryption = encryption;
            } else if (encryption.encryption_name == "SRTP") {
                srtp_encryption = encryption;
            }
        }

        if (omemo_encryption != null && dtls_encryption != null) {
            call.encryption = Encryption.OMEMO;
            omemo_encryption.peer_key = dtls_encryption.peer_key;
            omemo_encryption.our_key = dtls_encryption.our_key;
            audio_encryption = omemo_encryption;
            encryption_keys_same = true;
            video_encryption = video_encryptions != null ? video_encryptions["http://gultsch.de/xmpp/drafts/omemo/dlts-srtp-verification"] : null;
        } else if (dtls_encryption != null) {
            call.encryption = Encryption.DTLS_SRTP;
            audio_encryption = dtls_encryption;
            video_encryption = video_encryptions != null ? video_encryptions[Xep.JingleIceUdp.DTLS_NS_URI] : null;
            encryption_keys_same = true;
            if (video_encryption != null && dtls_encryption.peer_key.length == video_encryption.peer_key.length) {
                for (int i = 0; i < dtls_encryption.peer_key.length; i++) {
                    if (dtls_encryption.peer_key[i] != video_encryption.peer_key[i]) {
                        encryption_keys_same = false;
                        break;
                    }
                }
            }
        } else if (srtp_encryption != null) {
            call.encryption = Encryption.SRTP;
            audio_encryption = srtp_encryption;
            video_encryption = video_encryptions != null ? video_encryptions["SRTP"] : null;
            encryption_keys_same = false;
        } else {
            call.encryption = Encryption.NONE;
            encryption_keys_same = true;
        }

        encryption_updated(audio_encryption, video_encryption, encryption_keys_same);
    }
}

public class Dino.PeerContentInfo {
    public bool rtp_ready { get; set; }
    public bool rtcp_ready { get; set; }
    public ulong? bytes_sent { get; set; default=0; }
    public ulong? bytes_received { get; set; default=0; }
    public string? codec { get; set; }
    public uint32 clockrate { get; set; }
    public uint target_receive_bytes { get; set; default=-1; }
    public uint target_send_bytes { get; set; default=-1; }
}

public class Dino.PeerInfo {
    public PeerContentInfo? audio = null;
    public PeerContentInfo? video = null;
}