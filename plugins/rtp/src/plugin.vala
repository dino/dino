using Gee;
using Xmpp;
using Xmpp.Xep;

public class Dino.Plugins.Rtp.Plugin : RootInterface, VideoCallPlugin, Object {
    public Dino.Application app { get; private set; }
    public CodecUtil codec_util { get; private set; }
    public Gst.DeviceMonitor device_monitor { get; private set; }
    public Gst.Pipeline pipe { get; private set; }
    public Gst.Bin rtpbin { get; private set; }
    public Gst.Element echoprobe { get; private set; }

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

    public void startup() {
        device_monitor = new Gst.DeviceMonitor();
        device_monitor.show_all = true;
        device_monitor.get_bus().add_watch(Priority.DEFAULT, on_device_monitor_message);
        device_monitor.start();
        foreach (Gst.Device device in device_monitor.get_devices()) {
            if (device.properties.has_name("pipewire-proplist") && device.device_class.has_prefix("Audio/")) continue;
            if (device.properties.get_string("device.api") == "wasapi") continue;
            if (device.properties.get_string("device.class") == "monitor") continue;
            if (devices.any_match((it) => it.matches(device))) continue;
            devices.add(new Device(this, device));
        }

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
        rtpbin.@set("do-sync-event", true);
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
                    stream.on_ssrc_pad_added(split[4], pad);
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
        Gst.Device old_device = null;
        Gst.Device device = null;
        Device old = null;
        switch (message.type) {
            case Gst.MessageType.DEVICE_ADDED:
                message.parse_device_added(out device);
                if (device.properties.has_name("pipewire-proplist") && device.device_class.has_prefix("Audio/")) return Source.CONTINUE;
                if (device.properties.get_string("device.api") == "wasapi") return Source.CONTINUE;
                if (device.properties.get_string("device.class") == "monitor") return Source.CONTINUE;
                if (devices.any_match((it) => it.matches(device))) return Source.CONTINUE;
                devices.add(new Device(this, device));
                break;
#if GST_1_16
            case Gst.MessageType.DEVICE_CHANGED:
                message.parse_device_changed(out device, out old_device);
                if (device.properties.has_name("pipewire-proplist") && device.device_class.has_prefix("Audio/")) return Source.CONTINUE;
                if (device.properties.get_string("device.api") == "wasapi") return Source.CONTINUE;
                if (device.properties.get_string("device.class") == "monitor") return Source.CONTINUE;
                old = devices.first_match((it) => it.matches(old_device));
                if (old != null) old.update(device);
                break;
#endif
            case Gst.MessageType.DEVICE_REMOVED:
                message.parse_device_removed(out device);
                if (device.properties.has_name("pipewire-proplist") && device.device_class.has_prefix("Audio/")) return Source.CONTINUE;
                if (device.properties.get_string("device.api") == "wasapi") return Source.CONTINUE;
                if (device.properties.get_string("device.class") == "monitor") return Source.CONTINUE;
                old = devices.first_match((it) => it.matches(device));
                if (old != null) devices.remove(old);
                break;
        }
        if (device != null) {
            switch (device.device_class) {
                case "Audio/Source":
                    devices_changed("audio", false);
                    break;
                case "Audio/Sink":
                    devices_changed("audio", true);
                    break;
                case "Video/Source":
                    devices_changed("video", false);
                    break;
                case "Video/Sink":
                    devices_changed("video", true);
                    break;
            }
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
        device_monitor.stop();
        pipe.set_state(Gst.State.NULL);
        rtpbin = null;
        pipe = null;
        Gst.deinit();
    }

    public bool supports(string media) {
        if (rtpbin == null) return false;

        if (media == "audio") {
            if (get_devices("audio", false).is_empty) return false;
            if (get_devices("audio", true).is_empty) return false;
        }

        if (media == "video") {
            if (Gst.ElementFactory.make("gtksink", null) == null) return false;
            if (get_devices("video", false).is_empty) return false;
        }

        return true;
    }

    public VideoCallWidget? create_widget(WidgetType type) {
        if (type == WidgetType.GTK) {
            return new VideoWidget(this);
        }
        return null;
    }

    public Gee.List<MediaDevice> get_devices(string media, bool incoming) {
        if (media == "video" && !incoming) {
            return get_video_sources();
        }

        ArrayList<MediaDevice> result = new ArrayList<MediaDevice>();
        foreach (Device device in devices) {
            if (device.media == media && (incoming && device.is_sink || !incoming && device.is_source)) {
                result.add(device);
            }
        }
        if (media == "audio") {
            // Reorder sources
            result.sort((media_left, media_right) => {
                Device left = media_left as Device;
                Device right = media_right as Device;
                if (left == null) return 1;
                if (right == null) return -1;

                bool left_is_pipewire = left.device.properties.has_name("pipewire-proplist");
                bool right_is_pipewire = right.device.properties.has_name("pipewire-proplist");

                bool left_is_default = false;
                left.device.properties.get_boolean("is-default", out left_is_default);
                bool right_is_default = false;
                right.device.properties.get_boolean("is-default", out right_is_default);

                // default DirectSound device on Windows has (NULL) as guid
                if (left.device.properties.get_string("device.guid") == "(NULL)") {
                    left_is_default = true;
                }
                if (right.device.properties.get_string("device.guid") == "(NULL)") {
                    right_is_default = true;
                }

                // Prefer pipewire
                if (left_is_pipewire && !right_is_pipewire) return -1;
                if (right_is_pipewire && !left_is_pipewire) return 1;

                // Prefer pulse audio default device
                if (left_is_default && !right_is_default) return -1;
                if (right_is_default && !left_is_default) return 1;


                return 0;
            });
        }
        return result;
    }

    public Gee.List<MediaDevice> get_video_sources() {
        ArrayList<MediaDevice> pipewire_devices = new ArrayList<MediaDevice>();
        ArrayList<MediaDevice> other_devices = new ArrayList<MediaDevice>();

        foreach (Device device in devices) {
            if (device.media != "video") continue;
            if (device.is_sink) continue;

            bool is_color = false;
            for (int i = 0; i < device.device.caps.get_size(); i++) {
                unowned Gst.Structure structure = device.device.caps.get_structure(i);
                if (structure.has_field("format") && !structure.get_string("format").has_prefix("GRAY")) {
                    is_color = true;
                }
            }

            // Don't allow grey-scale devices
            if (!is_color) continue;

            if (device.device.properties.has_name("pipewire-proplist")) {
                pipewire_devices.add(device);
            } else {
                other_devices.add(device);
            }
        }

        // If we have any pipewire devices, present only those. Don't want duplicated devices from pipewire and video for linux.
        ArrayList<MediaDevice> devices = pipewire_devices.size > 0 ? pipewire_devices : other_devices;

        // Reorder sources
        devices.sort((media_left, media_right) => {
            Device left = media_left as Device;
            Device right = media_right as Device;
            if (left == null) return 1;
            if (right == null) return -1;

            int left_fps = 0;
            for (int i = 0; i < left.device.caps.get_size(); i++) {
                unowned Gst.Structure structure = left.device.caps.get_structure(i);
                int num = 0, den = 0;
                if (structure.has_field("framerate") && structure.get_fraction("framerate", out num, out den)) left_fps = int.max(left_fps, num / den);
            }

            int right_fps = 0;
            for (int i = 0; i < left.device.caps.get_size(); i++) {
                unowned Gst.Structure structure = left.device.caps.get_structure(i);
                int num = 0, den = 0;
                if (structure.has_field("framerate") && structure.get_fraction("framerate", out num, out den)) right_fps = int.max(right_fps, num / den);
            }

            // More FPS is better
            if (left_fps > right_fps) return -1;
            if (right_fps > left_fps) return 1;

            return 0;
        });

        return devices;
    }

    public Device? get_preferred_device(string media, bool incoming) {
        foreach (MediaDevice media_device in get_devices(media, incoming)) {
            Device? device = media_device as Device;
            if (device != null) return device;
        }
        warning("No preferred device for %s %s. Media will not be processed.", incoming ? "incoming" : "outgoing", media);
        return null;
    }

    public MediaDevice? get_device(Xmpp.Xep.JingleRtp.Stream stream, bool incoming) {
        Stream plugin_stream = stream as Stream;
        if (plugin_stream == null) return null;
        if (incoming) {
            return plugin_stream.output_device ?? get_preferred_device(stream.media, incoming);
        } else {
            return plugin_stream.input_device ?? get_preferred_device(stream.media, incoming);
        }
    }

    private void dump_dot() {
        string name = @"pipe-$(pipe.clock.get_time())-$(pipe.current_state)";
        Gst.Debug.bin_to_dot_file(pipe, Gst.DebugGraphDetails.ALL, name);
        debug("Stored pipe details as %s", name);
    }

    public void set_pause(Xmpp.Xep.JingleRtp.Stream stream, bool pause) {
        Stream plugin_stream = stream as Stream;
        if (plugin_stream == null) return;
        if (pause) {
            plugin_stream.pause();
        } else {
            plugin_stream.unpause();
        }
    }

    public void set_device(Xmpp.Xep.JingleRtp.Stream stream, MediaDevice? device) {
        Device real_device = device as Device;
        Stream plugin_stream = stream as Stream;
        if (real_device == null || plugin_stream == null) return;
        if (real_device.is_source) {
            plugin_stream.input_device = real_device;
        } else if (real_device.is_sink) {
            plugin_stream.output_device = real_device;
        }
    }
}
