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
    private HashMap<string, ulong> invite_handler_ids = new HashMap<string, ulong>();
    private int window_height = -1;
    private int window_width = -1;
    private bool window_size_changed = false;
    private ulong[] call_window_handler_ids = new ulong[0];
    private ulong[] bottom_bar_handler_ids = new ulong[0];
    private uint inhibit_cookie;

    public CallWindowController(CallWindow call_window, CallState call_state, StreamInteractor stream_interactor) {
        this.call_window = call_window;
        this.call = call_state.call;
        this.call_state = call_state;
        this.stream_interactor = stream_interactor;

        this.calls = stream_interactor.get_module(Calls.IDENTITY);
        this.own_video = call_plugin.create_widget(Plugins.WidgetType.GTK4);

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
        call_window_handler_ids += call_window.close_request.connect(() => {
            call_state.end();
            this.dispose();
            return false;
        });
        bottom_bar_handler_ids += call_window.bottom_bar.notify["audio-enabled"].connect(() => {
            call_state.mute_own_audio(!call_window.bottom_bar.audio_enabled);
        });
        bottom_bar_handler_ids += call_window.bottom_bar.notify["video-enabled"].connect(() => {
            call_state.mute_own_video(!call_window.bottom_bar.video_enabled);
            update_own_video();
        });
        call_window_handler_ids += call_window.notify["default-width"].connect((event) => {
            if (call_window.default_width == -1) return;
            int current_width = this.call_window.get_allocated_width();
            if (window_width != current_width) {
                debug("Call window size changed by user. Disabling auto window-to-video size adaptation. Width %i->%i", window_width, current_width);
                window_size_changed = true;
            }
        });
        call_window_handler_ids += call_window.notify["default-height"].connect((event) => {
            if (call_window.default_height == -1) return;
            int current_height = this.call_window.get_allocated_height();
            if (window_height != current_height) {
                debug("Call window size changed by user. Disabling auto window-to-video size adaptation. Height %i->%i", window_height, current_height);
                window_size_changed = true;
            }
        });
        call_window_handler_ids += ((Widget)call_window).realize.connect(() => {
            capture_window_size();
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

        update_audio_device_choices();
        update_video_device_choices();

        var app = GLib.Application.get_default() as Application;
        inhibit_cookie = app.inhibit(call_window, IDLE | SUSPEND, "Ongoing call");

        if (inhibit_cookie == 0) {
            warning("suspend inhibit request failed or unsupported");
        }

        call_window.close_request.connect(() => {
            if (inhibit_cookie != 0) {
                app.uninhibit(inhibit_cookie);
            }
            return false;
        });
    }

    private void invite_button_clicked() {
        Gee.List<Account> acc_list = new ArrayList<Account>(Account.equals_func);
        acc_list.add(call.account);
        SelectContactDialog add_chat_dialog = new SelectContactDialog(stream_interactor, acc_list);
        add_chat_dialog.set_transient_for((Window) call_window.get_root());
        add_chat_dialog.title = _("Invite to Call");
        add_chat_dialog.ok_button.label = _("Invite");
        add_chat_dialog.selected.connect((account, jid) => {
            call_state.invite_to_call.begin(jid);
        });
        add_chat_dialog.present();
    }

    private void connect_peer_signals(PeerState peer_state) {
        string peer_id = peer_state.internal_id;
        Jid peer_jid = peer_state.jid;
        peer_states[peer_id] = peer_state;

        peer_state.connection_ready.connect(() => {
            call_window.set_status(peer_id, "");
            if (participant_widgets.size == 1) {
                // This is the first peer.
                // If it can do MUJI, show invite button.

                call_state.can_convert_into_groupcall.begin((_, res) => {
                    bool can_convert = call_state.can_convert_into_groupcall.end(res);
                    participant_widgets[peer_id].may_show_invite_button = can_convert;
                });

                call_plugin.devices_changed.connect((media, incoming) => {
                    if (media == "audio") update_audio_device_choices();
                    if (media == "video") update_video_device_choices();
                });

                update_audio_device_choices();
                update_video_device_choices();
            } else if (participant_widgets.size > 1) {
                participant_widgets.values.@foreach((widget) => widget.may_show_invite_button = true);
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
                participant_videos[peer_id].display_stream(peer_state.get_video_stream(), peer_jid);
            }
        });
        peer_state.info_received.connect((session_info) => {
            if (session_info == Xmpp.Xep.JingleRtp.CallSessionInfo.RINGING) {
                call_window.set_status(peer_id, "ringing");
            }
        });
        peer_state.encryption_updated.connect((state, audio_encryption,  video_encryption) => {
            update_encryption_indicator(participant_widgets[peer_id].encryption_button_controller, peer_states[peer_id].audio_content != null, audio_encryption, peer_states[peer_id].video_content != null, video_encryption);
        });
    }

    private void update_encryption_indicator(CallEncryptionButtonController encryption_button, bool has_audio, Xep.Jingle.ContentEncryption? audio_encryption, bool has_video, Xep.Jingle.ContentEncryption? video_encryption) {
        string? title = null;
        string? icon_name = null;
        bool show_keys = true;
        Plugins.Registry registry = Dino.Application.get_default().plugin_registry;
        if (((has_audio && audio_encryption != null) || (has_video && video_encryption != null)) && (!has_audio || !has_video || (audio_encryption != null && video_encryption != null && audio_encryption.encryption_ns == video_encryption.encryption_ns))) {
            Plugins.CallEncryptionEntry? encryption_entry = audio_encryption != null ? registry.call_encryption_entries[audio_encryption.encryption_ns] : null;
            if (encryption_entry != null) {
                Plugins.CallEncryptionWidget? audio_encryption_widgets = encryption_entry.get_widget(call.account, audio_encryption);
                Plugins.CallEncryptionWidget? video_encryption_widgets = encryption_entry.get_widget(call.account, video_encryption);
                if (audio_encryption_widgets != null && video_encryption_widgets != null) {
                    if (audio_encryption_widgets.get_title() == video_encryption_widgets.get_title())
                        title = audio_encryption_widgets.get_title();
                    if (audio_encryption_widgets.get_icon_name() == video_encryption_widgets.get_icon_name())
                        icon_name = audio_encryption_widgets.get_icon_name();
                    if (audio_encryption_widgets.show_keys() == video_encryption_widgets.show_keys())
                        show_keys = audio_encryption_widgets.show_keys();
                }
            }
        }

        encryption_button.set_info(title, show_keys, has_audio, audio_encryption, has_video, video_encryption);
        encryption_button.set_icon((!has_audio || audio_encryption != null) && (!has_video || video_encryption != null), icon_name);
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
        participant_widget.may_show_invite_button = !participant_widgets.is_empty;
        participant_widget.debug_information_clicked.connect(() => {
            var conn_details_window = new CallConnectionDetailsWindow() { title=participant_name };
            conn_details_window.update_content(peer_states[participant_id].get_info());
            uint timeout_handle_id = Timeout.add_seconds(1, () => {
                conn_details_window.update_content(peer_states[participant_id].get_info());
                return true;
            });
            conn_details_window.set_transient_for(call_window);
            conn_details_window.close_request.connect(() => { Source.remove(timeout_handle_id); return false; });
            conn_details_window.present();
            this.call_window.close_request.connect(() => { conn_details_window.close(); return false; });
        });
        invite_handler_ids[participant_id] += participant_widget.invite_button_clicked.connect(() => invite_button_clicked());
        participant_widgets[participant_id] = participant_widget;

        call_window.add_participant(participant_id, participant_widget);

        participant_videos[participant_id] = call_plugin.create_widget(Plugins.WidgetType.GTK4);

        participant_videos[participant_id].resolution_changed.connect((width, height) => {
            if (window_size_changed || participant_widgets.size > 1) return;
            if (width == 0 || height == 0) return;
            if (width > height) {
                call_window.default_width = 704;
                call_window.default_height = (int) (height * 704 / width);
            } else {
                call_window.default_width = (int) (width * 704 / height);
                call_window.default_height = 704;
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
        participant_widgets[participant_id].disconnect(invite_handler_ids[participant_id]);
        participant_widgets.unset(participant_id);
        invite_handler_ids.unset(participant_id);
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
        } else if (call_plugin.get_devices("audio", true).size == 1 && call_plugin.get_devices("audio", false).size == 1) {
            call_window.bottom_bar.show_audio_device_choices(false);
            return;
        }

        AudioSettingsPopover? audio_settings_popover = call_window.bottom_bar.show_audio_device_choices(true);
        update_current_audio_device(audio_settings_popover);

        audio_settings_popover.microphone_selected.connect((device) => {
            call_state.set_audio_device(device);
            update_current_audio_device(audio_settings_popover);
        });
        audio_settings_popover.speaker_selected.connect((device) => {
            call_state.set_audio_device(device);
            update_current_audio_device(audio_settings_popover);
        });
    }

    private void update_current_audio_device(AudioSettingsPopover audio_settings_popover) {
        audio_settings_popover.current_microphone_device = call_state.get_microphone_device();
        audio_settings_popover.current_speaker_device = call_state.get_speaker_device();
    }

    private void update_video_device_choices() {
        int device_count = call_plugin.get_devices("video", false).size;

        if (device_count == 0) {
            call_window.bottom_bar.show_video_device_error();
        } else if (device_count == 1 || call_state.get_video_device() == null) {
            call_window.bottom_bar.show_video_device_choices(false);
            return;
        }

        VideoSettingsPopover? video_settings_popover = call_window.bottom_bar.show_video_device_choices(true);
        update_current_video_device(video_settings_popover);

        video_settings_popover.camera_selected.connect((device) => {
            call_state.set_video_device(device);
            update_current_video_device(video_settings_popover);
            own_video.display_device(device);
        });
    }

    private void update_current_video_device(VideoSettingsPopover video_settings_popover) {
        video_settings_popover.current_device = call_state.get_video_device();
    }

    private void update_own_video() {
        if (this.call_window.bottom_bar.video_enabled) {
            Gee.List<Plugins.MediaDevice> devices = call_plugin.get_devices("video", false);
            if (!(own_video is Widget) || devices.is_empty) {
                call_window.set_own_video(null);
            } else {
                Widget widget = (Widget) own_video;
                call_window.set_own_video(widget);
                own_video.display_device(call_state.get_video_device());
            }
        } else {
            own_video.detach();
            call_window.unset_own_video();
        }
    }

    public override void dispose() {
        foreach (ulong handler_id in call_window_handler_ids) call_window.disconnect(handler_id);
        foreach (ulong handler_id in bottom_bar_handler_ids) call_window.bottom_bar.disconnect(handler_id);

        var participant_ids = new ArrayList<string>();
        participant_ids.add_all(participant_widgets.keys);
        foreach (string participant_id in participant_ids) {
            remove_participant(participant_id);
        }

        call_window_handler_ids = bottom_bar_handler_ids = new ulong[0];
        own_video.detach();
        base.dispose();
    }
}
