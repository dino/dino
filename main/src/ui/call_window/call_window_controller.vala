using Dino.Entities;
using Gtk;

public class Dino.Ui.CallWindowController : Object {

    public signal void terminated();

    private CallWindow call_window;
    private Call call;
    private Conversation conversation;
    private StreamInteractor stream_interactor;
    private Calls calls;
    private Plugins.VideoCallPlugin call_plugin = Dino.Application.get_default().plugin_registry.video_call_plugin;

    private Plugins.VideoCallWidget? own_video = null;
    private Plugins.VideoCallWidget? counterpart_video = null;

    public CallWindowController(CallWindow call_window, Call call, StreamInteractor stream_interactor) {
        this.call_window = call_window;
        this.call = call;
        this.stream_interactor = stream_interactor;

        this.calls = stream_interactor.get_module(Calls.IDENTITY);
        this.conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(call.counterpart.bare_jid, call.account, Conversation.Type.CHAT);
        this.own_video = call_plugin.create_widget(Plugins.WidgetType.GTK);
        this.counterpart_video = call_plugin.create_widget(Plugins.WidgetType.GTK);

        call_window.counterpart_display_name = Util.get_conversation_display_name(stream_interactor, conversation);
        call_window.set_default_size(640, 480);
        call_window.set_video_fallback(stream_interactor, conversation);

        this.call_window.bottom_bar.video_enabled = calls.should_we_send_video(call);

        if (call.direction == Call.DIRECTION_INCOMING) {
            call_window.set_status("establishing");
        } else {
            call_window.set_status("requested");
        }

        call_window.bottom_bar.hang_up.connect(end_call);
        call_window.destroy.connect(end_call);

        call_window.bottom_bar.notify["audio-enabled"].connect(() => {
            calls.mute_own_audio(call, !call_window.bottom_bar.audio_enabled);
        });
        call_window.bottom_bar.notify["video-enabled"].connect(() => {
            calls.mute_own_video(call, !call_window.bottom_bar.video_enabled);
            update_own_video();
        });

        calls.counterpart_sends_video_updated.connect((call, mute) => {
            if (!this.call.equals(call)) return;

            if (mute) {
                call_window.set_video_fallback(stream_interactor, conversation);
                counterpart_video.detach();
            } else {
                if (!(counterpart_video is Widget)) return;
                Widget widget = (Widget) counterpart_video;
                call_window.set_video(widget);
                counterpart_video.display_stream(calls.get_video_stream(call));
            }
        });
        calls.info_received.connect((call, session_info) => {
            if (!this.call.equals(call)) return;
            if (session_info == Xmpp.Xep.JingleRtp.CallSessionInfo.RINGING) {
                call_window.set_status("ringing");
            }
        });

        own_video.resolution_changed.connect((width, height) => {
            if (width == 0 || height == 0) return;
            call_window.set_own_video_ratio((int)width, (int)height);
        });
        counterpart_video.resolution_changed.connect((width, height) => {
            if (width == 0 || height == 0) return;
            if (width / height > 640 / 480) {
                call_window.resize(640, (int) (height * 640 / width));
            } else {
                call_window.resize((int) (width * 480 / height), 480);
            }
        });

        call.notify["state"].connect(on_call_state_changed);
        calls.call_terminated.connect(on_call_terminated);

        update_own_video();
    }

    private void end_call() {
        call.notify["state"].disconnect(on_call_state_changed);
        calls.call_terminated.disconnect(on_call_terminated);

        calls.end_call(conversation, call);
        call_window.close();
        call_window.destroy();
        terminated();
    }

    private void on_call_state_changed() {
        if (call.state == Call.State.IN_PROGRESS) {
            call_window.set_status("");
            call_plugin.devices_changed.connect((media, incoming) => {
                if (media == "audio") update_audio_device_choices();
                if (media == "video") update_video_device_choices();
            });

            update_audio_device_choices();
            update_video_device_choices();
        }
    }

    private void on_call_terminated(Call call, string? reason_name, string? reason_text) {
        call_window.show_counterpart_ended(reason_name, reason_text);
        Timeout.add_seconds(3, () => {
            call.notify["state"].disconnect(on_call_state_changed);
            calls.call_terminated.disconnect(on_call_terminated);


            call_window.close();
            call_window.destroy();

            return false;
        });
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

    private void update_current_audio_device(AudioSettingsPopover audio_settings_popover) {
        Xmpp.Xep.JingleRtp.Stream stream = calls.get_audio_stream(call);
        if (stream != null) {
            audio_settings_popover.current_microphone_device = call_plugin.get_device(stream, false);
            audio_settings_popover.current_speaker_device = call_plugin.get_device(stream, true);
        }
    }

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

    private void update_current_video_device(VideoSettingsPopover video_settings_popover) {
        Xmpp.Xep.JingleRtp.Stream stream = calls.get_video_stream(call);
        if (stream != null) {
            video_settings_popover.current_device = call_plugin.get_device(stream, false);
        }
    }

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
}