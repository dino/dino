using Xmpp;
using Gee;
using Dino.Entities;
using Gtk;

public class Dino.Ui.CallWindowController : Object {

    private CallWindow call_window;
    private Call call;
    private CallState call_state;
    private StreamInteractor stream_interactor;
    private Calls calls;
    private Plugins.VideoCallPlugin call_plugin = Dino.Application.get_default().plugin_registry.video_call_plugin;

    private Plugins.VideoCallWidget? own_video = null;
    private HashMap<string, Plugins.VideoCallWidget> participant_videos = new HashMap<string, Plugins.VideoCallWidget>();
    private HashMap<string, ParticipantWidget> participant_widgets = new HashMap<string, ParticipantWidget>();
    private HashMap<string, PeerState> peer_states = new HashMap<string, PeerState>();
    private int window_height = -1;
    private int window_width = -1;
    private bool window_size_changed = false;
    private ulong[] call_window_handler_ids = new ulong[0];
    private ulong[] bottom_bar_handler_ids = new ulong[0];
    private ulong[] invite_handler_ids = new ulong[0];

    public CallWindowController(CallWindow call_window, CallState call_state, StreamInteractor stream_interactor) {
        this.call_window = call_window;
        this.call = call_state.call;
        this.call_state = call_state;
        this.stream_interactor = stream_interactor;

        this.calls = stream_interactor.get_module(Calls.IDENTITY);
        this.own_video = call_plugin.create_widget(Plugins.WidgetType.GTK);

        call_window.set_default_size(704, 528); // 640x480 * 1.1

        this.call_window.bottom_bar.video_enabled = call_state.should_we_send_video();

        call_state.terminated.connect((who_terminated, reason_name, reason_text) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(who_terminated.bare_jid, call.account, Conversation.Type.CHAT);
            string display_name = conversation != null ? Util.get_conversation_display_name(stream_interactor, conversation) : who_terminated.bare_jid.to_string();

            call_window.show_counterpart_ended(display_name, reason_name, reason_text);
            Timeout.add_seconds(3, () => {
                call_window.close();
                call_window.destroy();

                return false;
            });
        });
        call_state.peer_joined.connect((jid, peer_state) => {
            connect_peer_signals(peer_state);
            add_new_participant(peer_state.internal_id, peer_state.jid);
        });
        call_state.peer_left.connect((jid, peer_state, reason_name, reason_text) => {
            remove_participant(peer_state.internal_id);
        });

        foreach (PeerState peer_state in call_state.peers.values) {
            connect_peer_signals(peer_state);
            add_new_participant(peer_state.internal_id, peer_state.jid);
        }

        // Call window signals

        bottom_bar_handler_ids += call_window.bottom_bar.hang_up.connect(() => {
            call_state.end();
            call_window.close();
            call_window.destroy();
            this.dispose();
        });
        call_window_handler_ids += call_window.destroy.connect(() => {
            call_state.end();
            this.dispose();
        });
        bottom_bar_handler_ids += call_window.bottom_bar.notify["audio-enabled"].connect(() => {
            call_state.mute_own_audio(!call_window.bottom_bar.audio_enabled);
        });
        bottom_bar_handler_ids += call_window.bottom_bar.notify["video-enabled"].connect(() => {
            call_state.mute_own_video(!call_window.bottom_bar.video_enabled);
            update_own_video();
        });
        call_window_handler_ids += call_window.configure_event.connect((event) => {
            if (window_width == -1 || window_height == -1) return false;
            int current_height = this.call_window.get_allocated_height();
            int current_width = this.call_window.get_allocated_width();
            if (window_width != current_width || window_height != current_height) {
                debug("Call window size changed by user. Disabling auto window-to-video size adaptation. %i->%i x %i->%i", window_width, current_width, window_height, current_height);
                window_size_changed = true;
            }
            return false;
        });
        call_window_handler_ids += call_window.realize.connect(() => {
            capture_window_size();
        });
        invite_handler_ids += call_window.invite_button.clicked.connect(() => {
            Gee.List<Account> acc_list = new ArrayList<Account>(Account.equals_func);
            acc_list.add(call.account);
            SelectContactDialog add_chat_dialog = new SelectContactDialog(stream_interactor, acc_list);
            add_chat_dialog.set_transient_for((Window) call_window.get_toplevel());
            add_chat_dialog.title = _("Invite to Call");
            add_chat_dialog.ok_button.label = _("Invite");
            add_chat_dialog.selected.connect((account, jid) => {
                call_state.invite_to_call.begin(jid);
            });
            add_chat_dialog.present();
        });

        calls.conference_info_received.connect((call, conference_info) => {
            if (!this.call.equals(call)) return;

            var participants = new ArrayList<string>();
            participants.add_all(participant_videos.keys);
            foreach (string participant in participants) {
                remove_participant(participant);
            }
            foreach (Jid participant in conference_info.users.keys) {
                add_new_participant(participant.to_string(), participant);
            }
        });

        own_video.resolution_changed.connect((width, height) => {
            if (width == 0 || height == 0) return;
            call_window.set_own_video_ratio((int)width, (int)height);
        });

        call_window.menu_dump_dot.connect(() => { call_plugin.dump_dot(); });

        update_own_video();
    }

    private void connect_peer_signals(PeerState peer_state) {
        string peer_id = peer_state.internal_id;
        Jid peer_jid = peer_state.jid;
        peer_states[peer_id] = peer_state;

        peer_state.connection_ready.connect(() => {
            call_window.set_status(peer_state.internal_id, "");
            if (participant_widgets.size == 1) {
                // This is the first peer.
                // If it can do MUJI, show invite button.
                call_window.invite_button_revealer.visible = true;
//                stream_interactor.get_module(EntityInfo.IDENTITY).has_feature.begin(call.account, peer_state.jid, Xep.Muji.NS_URI, (_, res) => {
//                    bool has_feature = stream_interactor.get_module(EntityInfo.IDENTITY).has_feature.end(res);
//                    call_window.invite_button_revealer.visible = has_feature;
//                });

                call_plugin.devices_changed.connect((media, incoming) => {
                    if (media == "audio") update_audio_device_choices();
                    if (media == "video") update_video_device_choices();
                });

                update_audio_device_choices();
                update_video_device_choices();
            } else if (participant_widgets.size >= 1) {
                call_window.invite_button_revealer.visible = true;
            }
        });
        peer_state.counterpart_sends_video_updated.connect((mute) => {
            if (mute) {
                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(peer_jid.bare_jid, call.account, Conversation.Type.CHAT);
                call_window.set_placeholder(peer_id, conversation, stream_interactor);
                participant_videos[peer_id].detach();
            } else {
                if (!(participant_videos[peer_id] is Widget)) return;
                Widget widget = (Widget) participant_videos[peer_id];
                call_window.set_video(peer_id, widget);
                participant_videos[peer_id].display_stream(peer_state.get_video_stream(call), peer_jid);
            }
        });
        peer_state.info_received.connect((session_info) => {
            if (session_info == Xmpp.Xep.JingleRtp.CallSessionInfo.RINGING) {
                call_window.set_status(peer_state.internal_id, "ringing");
            }
        });
        peer_state.encryption_updated.connect((audio_encryption, video_encryption, same) => {
            update_encryption_indicator(participant_widgets[peer_id].encryption_button, audio_encryption, video_encryption, same);
        });
    }

    private void update_encryption_indicator(CallEncryptionButton encryption_button, Xep.Jingle.ContentEncryption? audio_encryption, Xep.Jingle.ContentEncryption? video_encryption, bool same) {
        string? title = null;
        string? icon_name = null;
        bool show_keys = true;
        Plugins.Registry registry = Dino.Application.get_default().plugin_registry;
        Plugins.CallEncryptionEntry? encryption_entry = audio_encryption != null ? registry.call_encryption_entries[audio_encryption.encryption_ns] : null;
        if (encryption_entry != null) {
            Plugins.CallEncryptionWidget? encryption_widgets = encryption_entry.get_widget(call.account, audio_encryption);
            if (encryption_widgets != null) {
                title = encryption_widgets.get_title();
                icon_name = encryption_widgets.get_icon_name();
                show_keys = encryption_widgets.show_keys();
            }
        }

        encryption_button.set_info(title, show_keys, audio_encryption, same ? null : video_encryption);
        encryption_button.set_icon(audio_encryption != null, icon_name);
    }

    private void add_new_participant(string participant_id, Jid jid) {
        if (participant_widgets.has_key(participant_id)) {
            warning("[%s] Attempted to add same participant twice: %s", call.account.bare_jid.to_string(), jid.to_string());
            return;
        }
        debug("[%s] Call window controller | Add participant: %s", call.account.bare_jid.to_string(), jid.to_string());

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid.bare_jid, call.account, Conversation.Type.CHAT);
        string participant_name = conversation != null ? Util.get_conversation_display_name(stream_interactor, conversation) : jid.bare_jid.to_string();

        ParticipantWidget participant_widget = new ParticipantWidget(participant_name);
        participant_widget.menu_button.clicked.connect((event) => {
            var conn_details_window = new CallConnectionDetailsWindow() { title=participant_name, visible=true };
            conn_details_window.update_content(peer_states[participant_id].get_info());
            uint timeout_handle_id = Timeout.add_seconds(1, () => {
                conn_details_window.update_content(peer_states[participant_id].get_info());
                return true;
            });
            conn_details_window.set_transient_for(call_window);
            conn_details_window.destroy.connect(() => Source.remove(timeout_handle_id));
            conn_details_window.present();
            this.call_window.destroy.connect(() => conn_details_window.close() );
        });
        participant_widgets[participant_id] = participant_widget;

        call_window.add_participant(participant_id, participant_widget);

        participant_videos[participant_id] = call_plugin.create_widget(Plugins.WidgetType.GTK);

        participant_videos[participant_id].resolution_changed.connect((width, height) => {
            if (window_size_changed || participant_widgets.size > 1) return;
            if (width == 0 || height == 0) return;
            if (width > height) {
                call_window.resize(704, (int) (height * 704 / width));
            } else {
                call_window.resize((int) (width * 704 / height), 704);
            }
            capture_window_size();
        });

        participant_widget.set_placeholder(conversation, stream_interactor);
        if (call.direction == Call.DIRECTION_INCOMING) {
            call_window.set_status(participant_id, "establishing");
        } else {
            call_window.set_status(participant_id, "requested");
        }
    }

    private void remove_participant(string participant_id) {
        if (peer_states.has_key(participant_id)) debug(@"[%s] Call window controller | Remove participant: %s", call.account.bare_jid.to_string(), peer_states[participant_id].jid.to_string());

        participant_videos.unset(participant_id);
        participant_widgets.unset(participant_id);
        peer_states.unset(participant_id);
        call_window.remove_participant(participant_id);
    }

    private void capture_window_size() {
        Allocation allocation;
        this.call_window.get_allocation(out allocation);
        this.window_height = this.call_window.get_allocated_height();
        this.window_width = this.call_window.get_allocated_width();
    }

    private void update_audio_device_choices() {
        if (call_plugin.get_devices("audio", true).size == 0 || call_plugin.get_devices("audio", false).size == 0) {
            call_window.bottom_bar.show_audio_device_error();
        } /*else if (call_plugin.get_devices("audio", true).size == 1 && call_plugin.get_devices("audio", false).size == 1) {
            call_window.bottom_bar.show_audio_device_choices(false);
            return;
        }

        AudioSettingsPopover? audio_settings_popover = call_window.bottom_bar.show_audio_device_choices(true);
        update_current_audio_device(audio_settings_popover);

        audio_settings_popover.microphone_selected.connect((device) => {
            call_plugin.set_device(calls.get_audio_stream(call), device);
            update_current_audio_device(audio_settings_popover);
        });
        audio_settings_popover.speaker_selected.connect((device) => {
            call_plugin.set_device(calls.get_audio_stream(call), device);
            update_current_audio_device(audio_settings_popover);
        });
        calls.stream_created.connect((call, media) => {
            if (media == "audio") {
                update_current_audio_device(audio_settings_popover);
            }
        });*/
    }

    /*private void update_current_audio_device(AudioSettingsPopover audio_settings_popover) {
        Xmpp.Xep.JingleRtp.Stream stream = calls.get_audio_stream(call);
        if (stream != null) {
            audio_settings_popover.current_microphone_device = call_plugin.get_device(stream, false);
            audio_settings_popover.current_speaker_device = call_plugin.get_device(stream, true);
        }
    }*/

    private void update_video_device_choices() {
        int device_count = call_plugin.get_devices("video", false).size;

        if (device_count == 0) {
            call_window.bottom_bar.show_video_device_error();
        } /*else if (device_count == 1 || calls.get_video_stream(call) == null) {
            call_window.bottom_bar.show_video_device_choices(false);
            return;
        }

        VideoSettingsPopover? video_settings_popover = call_window.bottom_bar.show_video_device_choices(true);
        update_current_video_device(video_settings_popover);

        video_settings_popover.camera_selected.connect((device) => {
            call_plugin.set_device(calls.get_video_stream(call), device);
            update_current_video_device(video_settings_popover);
            own_video.display_device(device);
        });
        calls.stream_created.connect((call, media) => {
            if (media == "video") {
                update_current_video_device(video_settings_popover);
            }
        });*/
    }

    public void add_test_video() {
        var pipeline = new Gst.Pipeline(null);
        var src = Gst.ElementFactory.make("videotestsrc", null);
        pipeline.add(src);
        Gst.Video.Sink sink = (Gst.Video.Sink) Gst.ElementFactory.make("gtksink", null);
        Gtk.Widget widget;
        sink.get("widget", out widget);
        widget.unparent();
        pipeline.add(sink);
        src.link(sink);
        widget.visible = true;

        pipeline.set_state(Gst.State.PLAYING);

        sink.get_static_pad("sink").notify["caps"].connect(() => {
            int width, height;
            sink.get_static_pad("sink").caps.get_structure(0).get_int("width", out width);
            sink.get_static_pad("sink").caps.get_structure(0).get_int("height", out height);
            widget.width_request = width;
            widget.height_request = height;
        });

//        call_window.set_participant_video(Xmpp.random_uuid(), widget);
    }

    /*private void update_current_video_device(VideoSettingsPopover video_settings_popover) {
        Xmpp.Xep.JingleRtp.Stream stream = calls.get_video_stream(call);
        if (stream != null) {
            video_settings_popover.current_device = call_plugin.get_device(stream, false);
        }
    }*/

    private void update_own_video() {
        if (this.call_window.bottom_bar.video_enabled) {
            Gee.List<Plugins.MediaDevice> devices = call_plugin.get_devices("video", false);
            if (!(own_video is Widget) || devices.is_empty) {
                call_window.set_own_video(null);
            } else {
                Widget widget = (Widget) own_video;
                call_window.set_own_video(widget);
                own_video.display_device(devices.first());
            }
        } else {
            own_video.detach();
            call_window.unset_own_video();
        }
    }

    public override void dispose() {
        foreach (ulong handler_id in call_window_handler_ids) call_window.disconnect(handler_id);
        foreach (ulong handler_id in bottom_bar_handler_ids) call_window.bottom_bar.disconnect(handler_id);
        foreach (ulong handler_id in invite_handler_ids) call_window.invite_button.disconnect(handler_id);

        call_window_handler_ids = bottom_bar_handler_ids = invite_handler_ids = new ulong[0];

        base.dispose();
    }
}