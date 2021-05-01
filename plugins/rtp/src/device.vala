public class Dino.Plugins.Rtp.Device : MediaDevice, Object {
    public Plugin plugin { get; private set; }
    public Gst.Device device { get; private set; }

    private string device_name;
    public string id { get {
        return device_name;
    }}
    private string device_display_name;
    public string display_name { get {
        return device_display_name;
    }}
    public string detail_name { get {
        return device.properties.get_string("alsa.card_name") ?? device.properties.get_string("alsa.id") ?? id;
    }}
    public Gst.Pipeline pipe { get {
        return plugin.pipe;
    }}
    public string? media { get {
        if (device.device_class.has_prefix("Audio/")) {
            return "audio";
        } else if (device.device_class.has_prefix("Video/")) {
            return "video";
        } else {
            return null;
        }
    }}
    public bool is_source { get {
        return device.device_class.has_suffix("/Source");
    }}
    public bool is_sink { get {
        return device.device_class.has_suffix("/Sink");
    }}

    private Gst.Element element;
    private Gst.Element tee;
    private Gst.Element dsp;
    private Gst.Element mixer;
    private Gst.Element filter;
    private Gst.Element rate;
    private int links = 0;

    public Device(Plugin plugin, Gst.Device device) {
        this.plugin = plugin;
        update(device);
    }

    public bool matches(Gst.Device device) {
        if (this.device.name == device.name) return true;
        return false;
    }

    public void update(Gst.Device device) {
        this.device = device;
        this.device_name = device.name;
        this.device_display_name = device.display_name;
    }

    public Gst.Element? link_sink() {
        if (element == null) create();
        links++;
        if (mixer != null) return mixer;
        if (is_sink && media == "audio") return filter;
        return element;
    }

    public Gst.Element? link_source() {
        if (element == null) create();
        links++;
        if (tee != null) return tee;
        return element;
    }

    public void unlink() {
        if (links <= 0) {
            critical("Link count below zero.");
            return;
        }
        links--;
        if (links == 0) {
            destroy();
        }
    }

    private Gst.Caps get_best_caps() {
        if (media == "audio") {
            return Gst.Caps.from_string("audio/x-raw,rate=48000,channels=1");
        } else if (media == "video" && device.caps.get_size() > 0) {
            int best_index = 0;
            int best_fps = 0;
            int best_width = 0;
            int best_height = 0;
            for (int i = 0; i < device.caps.get_size(); i++) {
                unowned Gst.Structure? that = device.caps.get_structure(i);
                if (!that.has_name("video/x-raw")) continue;
                int num = 0, den = 0, width = 0, height = 0;
                if (!that.has_field("framerate") || !that.get_fraction("framerate", out num, out den)) continue;
                if (!that.has_field("width") || !that.get_int("width", out width)) continue;
                if (!that.has_field("height") || !that.get_int("height", out height)) continue;
                int fps = num/den;
                if (best_fps < fps || best_fps == fps && best_width < width || best_fps == fps && best_width == width && best_height < height) {
                    best_fps = fps;
                    best_width = width;
                    best_height = height;
                    best_index = i;
                }
            }
            return caps_copy_nth(device.caps, best_index);
        } else if (device.caps.get_size() > 0) {
            return caps_copy_nth(device.caps, 0);
        } else {
            return new Gst.Caps.any();
        }
    }

    // Backport from gst_caps_copy_nth added in GStreamer 1.16
    private static Gst.Caps caps_copy_nth(Gst.Caps source, uint index) {
        Gst.Caps target = new Gst.Caps.empty();
        target.flags = source.flags;
        target.append_structure_full(source.get_structure(index).copy(), source.get_features(index).copy());
        return target;
    }

    private void create() {
        debug("Creating device %s", id);
        plugin.pause();
        element = device.create_element(id);
        pipe.add(element);
        if (is_source) {
            element.@set("do-timestamp", true);
            filter = Gst.ElementFactory.make("capsfilter", @"caps_filter_$id");
            filter.@set("caps", get_best_caps());
            pipe.add(filter);
            element.link(filter);
#if WITH_VOICE_PROCESSOR
            if (media == "audio" && plugin.echoprobe != null) {
                dsp = new VoiceProcessor(plugin.echoprobe as EchoProbe, element as Gst.Audio.StreamVolume);
                dsp.name = @"dsp_$id";
                pipe.add(dsp);
                filter.link(dsp);
            }
#endif
            tee = Gst.ElementFactory.make("tee", @"tee_$id");
            tee.@set("allow-not-linked", true);
            pipe.add(tee);
            (dsp ?? filter).link(tee);
        }
        if (is_sink) {
            element.@set("async", false);
            element.@set("sync", false);
        }
        if (is_sink && media == "audio") {
            filter = Gst.ElementFactory.make("capsfilter", @"caps_filter_$id");
            filter.@set("caps", get_best_caps());
            pipe.add(filter);
            if (plugin.echoprobe != null) {
                rate = Gst.ElementFactory.make("audiorate", @"rate_$id");
                rate.@set("tolerance", 100000000);
                pipe.add(rate);
                filter.link(rate);
                rate.link(plugin.echoprobe);
                plugin.echoprobe.link(element);
            } else {
                filter.link(element);
            }
        }
        plugin.unpause();
    }

    private void destroy() {
        if (mixer != null) {
            if (is_sink && media == "audio" && plugin.echoprobe != null) {
                plugin.echoprobe.unlink(mixer);
            }
            int linked_sink_pads = 0;
            mixer.foreach_sink_pad((_, pad) => {
                if (pad.is_linked()) linked_sink_pads++;
                return true;
            });
            if (linked_sink_pads > 0) {
                warning("%s-mixer still has %i sink pads while being destroyed", id, linked_sink_pads);
            }
            mixer.set_locked_state(true);
            mixer.set_state(Gst.State.NULL);
            mixer.unlink(element);
            pipe.remove(mixer);
            mixer = null;
        } else if (is_sink && media == "audio") {
            if (filter != null) {
                filter.set_locked_state(true);
                filter.set_state(Gst.State.NULL);
                filter.unlink(rate ?? ((Gst.Element)plugin.echoprobe) ?? element);
                pipe.remove(filter);
                filter = null;
            }
            if (rate != null) {
                rate.set_locked_state(true);
                rate.set_state(Gst.State.NULL);
                rate.unlink(plugin.echoprobe);
                pipe.remove(rate);
                rate = null;
            }
            if (plugin.echoprobe != null) {
                plugin.echoprobe.unlink(element);
            }
        }
        element.set_locked_state(true);
        element.set_state(Gst.State.NULL);
        if (filter != null) element.unlink(filter);
        else if (is_source) element.unlink(tee);
        pipe.remove(element);
        element = null;
        if (filter != null) {
            filter.set_locked_state(true);
            filter.set_state(Gst.State.NULL);
            filter.unlink(dsp ?? tee);
            pipe.remove(filter);
            filter = null;
        }
        if (dsp != null) {
            dsp.set_locked_state(true);
            dsp.set_state(Gst.State.NULL);
            dsp.unlink(tee);
            pipe.remove(dsp);
            dsp = null;
        }
        if (tee != null) {
            int linked_src_pads = 0;
            tee.foreach_src_pad((_, pad) => {
                if (pad.is_linked()) linked_src_pads++;
                return true;
            });
            if (linked_src_pads != 0) {
                warning("%s-tee still has %d src pads while being destroyed", id, linked_src_pads);
            }
            tee.set_locked_state(true);
            tee.set_state(Gst.State.NULL);
            pipe.remove(tee);
            tee = null;
        }
        debug("Destroyed device %s", id);
    }
}