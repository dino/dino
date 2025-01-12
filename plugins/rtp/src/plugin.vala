using Gee;
using Xmpp;
using Xmpp.Xep;

public class Dino.Plugins.Rtp.Plugin : RootInterface, VideoCallPlugin, Object {
    public Dino.Application app { get; private set; }
    public CodecUtil codec_util { get; private set; }
    public Gst.DeviceMonitor? device_monitor { get; private set; }
    public Gst.Pipeline? pipe { get; private set; }
    public Gst.Bin? rtpbin { get; private set; }
    public Gst.Element? echoprobe { get; private set; }

    private Gee.List<Stream> streams = new ArrayList<Stream>();
    private Gee.List<Device> devices = new ArrayList<Device>();
    //    private Gee.List<Participant> participants = new ArrayList<Participant>();

    public void registered(Dino.Application app) {
        this.app = app;
        this.codec_util = new CodecUtil();
        app.startup.connect(startup);
        app.add_option_group(Gst.init_get_option_group());
        app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
            list.add(new Module(this));
        });
        app.plugin_registry.video_call_plugin = this;
    }

    private int pause_count = 0;
    public void pause() {
//        if (pause_count == 0) {
//            debug("Pausing pipe for modifications");
//            pipe.set_state(Gst.State.PAUSED);
//        }
        pause_count++;
    }
    public void unpause() {
        pause_count--;
        if (pause_count == 0) {
            debug("Continue pipe after modifications");
            pipe.set_state(Gst.State.PLAYING);
        }
        if (pause_count < 0) warning("Pause count below zero!");
    }

    private void init_device_monitor() {
        if (device_monitor != null) return;
        device_monitor = new Gst.DeviceMonitor();
        device_monitor.show_all = true;
        device_monitor.get_bus().add_watch(Priority.DEFAULT, on_device_monitor_message);
        device_monitor.start();
        foreach (Gst.Device device in device_monitor.get_devices()) {
            if (device.properties.has_name("pipewire-proplist") && device.has_classes("Audio")) continue;
            if (device.properties.get_string("device.class") == "monitor") continue;
            if (devices.any_match((it) => it.matches(device))) continue;
            devices.add(new Device(this, device));
        }
    }

    private void init_call_pipe() {
        if (pipe != null) return;
        pipe = new Gst.Pipeline(null);

        // RTP
        rtpbin = Gst.ElementFactory.make("rtpbin", null) as Gst.Bin;
        if (rtpbin == null) {
            warning("RTP not supported");
            pipe = null;
            return;
        }
        rtpbin.pad_added.connect(on_rtp_pad_added);
        rtpbin.@set("latency", 100);
        rtpbin.@set("do-lost", true);
//        rtpbin.@set("do-sync-event", true);
        rtpbin.@set("drop-on-latency", true);
        rtpbin.connect("signal::request-pt-map", request_pt_map, this);
        pipe.add(rtpbin);

#if WITH_VOICE_PROCESSOR
        // Audio echo probe
        echoprobe = new EchoProbe();
        if (echoprobe != null) pipe.add(echoprobe);
#endif

        // Pipeline
        pipe.auto_flush_bus = true;
        pipe.bus.add_watch(GLib.Priority.DEFAULT, (_, message) => {
            on_pipe_bus_message(message);
            return true;
        });
        pipe.set_state(Gst.State.PLAYING);
    }

    private void destroy_call_pipe() {
        if (pipe == null) return;
        pipe.set_state(Gst.State.NULL);
        rtpbin = null;
#if WITH_VOICE_PROCESSOR
        echoprobe = null;
#endif
        pipe = null;
    }

    public void startup() {
        init_device_monitor();
    }

    private static Gst.Caps? request_pt_map(Gst.Element rtpbin, uint session, uint pt, Plugin plugin) {
        debug("request-pt-map");
        return null;
    }

    private void on_rtp_pad_added(Gst.Pad pad) {
        debug("pad added: %s", pad.name);
        if (pad.name.has_prefix("recv_rtp_src_")) {
            string[] split = pad.name.split("_");
            uint8 rtpid = (uint8)int.parse(split[3]);
            foreach (Stream stream in streams) {
                if (stream.rtpid == rtpid) {
                    stream.on_ssrc_pad_added((uint32) split[4].to_uint64(), pad);
                }
            }
        }
        if (pad.name.has_prefix("send_rtp_src_")) {
            string[] split = pad.name.split("_");
            uint8 rtpid = (uint8)int.parse(split[3]);
            debug("pad %s for stream %hhu", pad.name, rtpid);
            foreach (Stream stream in streams) {
                if (stream.rtpid == rtpid) {
                    stream.on_send_rtp_src_added(pad);
                }
            }
        }
    }

    private void on_pipe_bus_message(Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.ERROR:
                Error error;
                string str;
                message.parse_error(out error, out str);
                warning("Error in pipeline: %s", error.message);
                debug(str);
                break;
            case Gst.MessageType.WARNING:
                Error error;
                string str;
                message.parse_warning(out error, out str);
                warning("Warning in pipeline: %s", error.message);
                debug(str);
                break;
            case Gst.MessageType.CLOCK_LOST:
                debug("Clock lost. Restarting");
                pipe.set_state(Gst.State.READY);
                pipe.set_state(Gst.State.PLAYING);
                break;
            case Gst.MessageType.STATE_CHANGED:
                // Ignore
                break;
            case Gst.MessageType.STREAM_STATUS:
                Gst.StreamStatusType status;
                Gst.Element owner;
                message.parse_stream_status(out status, out owner);
                if (owner != null) {
                    debug("%s stream changed status to %s", owner.name, status.to_string());
                }
                break;
            case Gst.MessageType.ELEMENT:
                unowned Gst.Structure struc = message.get_structure();
                if (struc != null && message.src is Gst.Element) {
                    debug("Message from %s in pipeline: %s", ((Gst.Element)message.src).name, struc.to_string());
                }
                break;
            case Gst.MessageType.NEW_CLOCK:
                debug("New clock.");
                break;
            case Gst.MessageType.TAG:
                // Ignore
                break;
            case Gst.MessageType.QOS:
                // Ignore
                break;
            case Gst.MessageType.LATENCY:
                if (message.src != null && message.src.name != null && message.src is Gst.Element) {
                    Gst.Query latency_query = new Gst.Query.latency();
                    if (((Gst.Element)message.src).query(latency_query)) {
                        bool live;
                        Gst.ClockTime min_latency, max_latency;
                        latency_query.parse_latency(out live, out min_latency, out max_latency);
                        debug("Latency message from %s: live=%s, min_latency=%s, max_latency=%s", message.src.name, live.to_string(), min_latency.to_string(), max_latency.to_string());
                    }
                }
                break;
            default:
                debug("Pipe bus message: %s", message.type.to_string());
                break;
        }
    }

    private bool on_device_monitor_message(Gst.Bus bus, Gst.Message message) {
        Gst.Device? old_gst_device = null;
        Gst.Device? gst_device = null;
        Device? device = null;
        switch (message.type) {
            case Gst.MessageType.DEVICE_ADDED:
                message.parse_device_added(out gst_device);
                if (devices.any_match((it) => it.matches(gst_device))) return Source.CONTINUE;
                device = new Device(this, gst_device);
                devices.add(device);
                break;
#if GST_1_16
            case Gst.MessageType.DEVICE_CHANGED:
                message.parse_device_changed(out gst_device, out old_gst_device);
                device = devices.first_match((it) => it.matches(old_gst_device));
                if (device != null) device.update(gst_device);
                break;
#endif
            case Gst.MessageType.DEVICE_REMOVED:
                message.parse_device_removed(out gst_device);
                device = devices.first_match((it) => it.matches(gst_device));
                if (device != null) devices.remove(device);
                break;
            default:
                break;
        }
        if (device != null) {
            devices_changed(device.media, device.is_sink);
        }
        return Source.CONTINUE;
    }

    public uint8 next_free_id() {
        uint8 rtpid = 0;
        while (streams.size < 100 && streams.any_match((stream) => stream.rtpid == rtpid)) {
            rtpid++;
        }
        return rtpid;
    }

    //    public Participant get_participant(Jid full_jid, bool self) {
//        foreach (Participant participant in participants) {
//            if (participant.full_jid.equals(full_jid)) {
//                return participant;
//            }
//        }
//        Participant participant;
//        if (self) {
//            participant = new SelfParticipant(pipe, full_jid);
//        } else {
//            participant = new Participant(pipe, full_jid);
//        }
//        participants.add(participant);
//        return participant;
//    }

    public Stream open_stream(Xmpp.Xep.Jingle.Content content) {
        init_call_pipe();
        var content_params = content.content_params as Xmpp.Xep.JingleRtp.Parameters;
        if (content_params == null) return null;
        Stream stream;
        if (content_params.media == "video") {
            stream = new VideoStream(this, content);
        } else {
            stream = new Stream(this, content);
        }
        streams.add(stream);
        return stream;
    }

    public void close_stream(Stream stream) {
        streams.remove(stream);
        stream.destroy();
    }

    public void shutdown() {
        if (device_monitor != null) {
            device_monitor.stop();
        }
        destroy_call_pipe();
        Gst.deinit();
    }

    public bool supports(string? media) {
        if (!codec_util.is_element_supported("rtpbin")) return false;

        if (media == "audio") {
            if (get_devices("audio", false).is_empty) return false;
            if (get_devices("audio", true).is_empty) return false;
        }

        if (media == "video") {
            if (get_devices("video", false).is_empty) return false;
        }

        return true;
    }

    public VideoCallWidget? create_widget(WidgetType type) {
        init_call_pipe();
        if (type == WidgetType.GTK4) {
            return new VideoWidget(this);
        }
        return null;
    }

    public Gee.List<MediaDevice> get_devices(string media, bool incoming) {
        Gee.List<MediaDevice> devices;
        if (media == "video" && !incoming) {
            devices = get_video_sources();
        } else if (media == "audio") {
            devices = get_audio_devices(incoming);
        } else {
            devices = new ArrayList<MediaDevice>();
            devices.add_all_iterator(this.devices.filter(it => it.media == media && (incoming && it.is_sink || !incoming && it.is_source) && !it.is_monitor));
        }
        devices.sort((media_left, media_right) => {
            return strcmp(media_left.id, media_right.id);
        });

        return devices;
    }

    public Gee.List<MediaDevice> get_audio_devices(bool incoming) {
        ArrayList<MediaDevice> pulse_devices = new ArrayList<MediaDevice>();
        ArrayList<MediaDevice> other_devices = new ArrayList<MediaDevice>();

        foreach (Device device in devices) {
            if (device.media != "audio") continue;
            if (incoming && !device.is_sink || !incoming && !device.is_source) continue;

            // Skip monitors
            if (device.is_monitor) continue;

            if (device.protocol == DeviceProtocol.PULSEAUDIO) {
                pulse_devices.add(device);
            } else {
                other_devices.add(device);
            }
        }

        // If we have any pulseaudio devices, present only those. Don't want duplicated devices from pipewire and pulseaudio.
        return pulse_devices.size > 0 ? pulse_devices : other_devices;
    }

    public Gee.List<MediaDevice> get_video_sources() {
        ArrayList<MediaDevice> pipewire_devices = new ArrayList<MediaDevice>();
        ArrayList<MediaDevice> other_devices = new ArrayList<MediaDevice>();

        foreach (Device device in devices) {
            if (device.media != "video") continue;
            if (device.is_sink) continue;

            // Skip monitors
            if (device.is_monitor) continue;

            bool is_color = false;
            for (int i = 0; i < device.device.caps.get_size(); i++) {
                unowned Gst.Structure structure = device.device.caps.get_structure(i);
                if (!structure.has_field("format")) continue;
                // "format" might be an array and get_string() will then return null. We just assume arrays to be fine.
                string? format = structure.get_string("format");
                if (format == null || !format.has_prefix("GRAY")) {
                    is_color = true;
                }
            }

            // Don't allow grey-scale devices
            if (!is_color) continue;

            if (device.protocol == DeviceProtocol.PIPEWIRE) {
                pipewire_devices.add(device);
            } else {
                other_devices.add(device);
            }
        }

        // If we have any pipewire devices, present only those. Don't want duplicated devices from pipewire and video for linux.
        return pipewire_devices.size > 0 ? pipewire_devices : other_devices;
    }

    private int get_max_fps(Device device) {
        int fps = 0;
        for (int i = 0; i < device.device.caps.get_size(); i++) {
            unowned Gst.Structure structure = device.device.caps.get_structure(i);

            if (structure.has_field("framerate")) {
                Value framerate = structure.get_value("framerate");
                if (framerate.type() == typeof(Gst.Fraction)) {
                    int num = Gst.Value.get_fraction_numerator(framerate);
                    int den = Gst.Value.get_fraction_denominator(framerate);
                    fps = int.max(fps, num / den);
                } else if (framerate.type() == typeof(Gst.ValueList)) {
                    for(uint j = 0; j < Gst.ValueList.get_size(framerate); j++) {
                        Value fraction = Gst.ValueList.get_value(framerate, j);
                        int num = Gst.Value.get_fraction_numerator(fraction);
                        int den = Gst.Value.get_fraction_denominator(fraction);
                        fps = int.max(fps, num / den);
                    }
                } else {
                    debug("Unknown type for framerate %s on device %s", framerate.type_name(), device.display_name);
                }
            }
        }

        debug("Max framerate for device %s: %d", device.display_name, fps);
        return fps;
    }

    public MediaDevice? get_preferred_device(string media, bool incoming) {
        Gee.List<Device> devices = new ArrayList<Device>();
        foreach (MediaDevice media_device in get_devices(media, incoming)) {
            if (media_device is Device) devices.add((Device)media_device);
        }
        if (devices.is_empty) {
            warning("No preferred device for %s %s. Media will not be processed.", incoming ? "incoming" : "outgoing", media);
            return null;
        }

        // Take default if present
        foreach (Device device in devices) {
            if (device.is_default) {
                debug("Using %s for %s %s as it's default", device.display_name, incoming ? "incoming" : "outgoing", media);
                return device;
            }
        }

        if (media == "video") {
            // Pick best FPS
            int max_fps = -1;
            Device? max_fps_device = null;
            foreach (Device device in devices) {
                int fps = get_max_fps(device);
                if (fps > max_fps || max_fps_device == null) {
                    max_fps = fps;
                    max_fps_device = device;
                }
            }
            debug("Using %s for %s %s as it has max FPS (%d)", max_fps_device.display_name, incoming ? "incoming" : "outgoing", media, max_fps);
            return max_fps_device;
        } else {
            // Pick any
            Device? device = devices.first();
            debug("Using %s for %s %s as it's first pick", device.display_name, incoming ? "incoming" : "outgoing", media);
            return device;
        }
    }

    public MediaDevice? get_device(Xmpp.Xep.JingleRtp.Stream? stream, bool incoming) {
        Stream? plugin_stream = stream as Stream?;
        if (plugin_stream == null) return null;
        MediaDevice? device = incoming ? plugin_stream.output_device : plugin_stream.input_device;
        return device ?? get_preferred_device(stream.media, incoming);
    }

    public void dump_dot() {
        if (pipe == null) return;
        string name = @"pipe-$(pipe.clock.get_time())-$(pipe.current_state)";
        Gst.Debug.bin_to_dot_file(pipe, Gst.DebugGraphDetails.ALL, name);
        print(@"Stored pipe details as $name\n");
    }

    public void set_pause(Xmpp.Xep.JingleRtp.Stream? stream, bool pause) {
        Stream? plugin_stream = stream as Stream?;
        if (plugin_stream == null) return;
        if (pause) {
            plugin_stream.pause();
        } else {
            plugin_stream.unpause();
        }
    }

    public void set_device(Xmpp.Xep.JingleRtp.Stream? stream, MediaDevice? device) {
        Device? real_device = device as Device?;
        Stream? plugin_stream = stream as Stream?;
        if (real_device == null || plugin_stream == null) return;
        if (real_device.is_source) {
            plugin_stream.input_device = real_device;
        } else if (real_device.is_sink) {
            plugin_stream.output_device = real_device;
        }
    }
}
