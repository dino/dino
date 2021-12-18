using Xmpp.Xep.JingleRtp;
using Gee;

public class Dino.Plugins.Rtp.Device : MediaDevice, Object {
    public Plugin plugin { get; private set; }
    public CodecUtil codec_util { get { return plugin.codec_util; } }
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
        if (device.has_classes("Audio")) {
            return "audio";
        } else if (device.has_classes("Video")) {
            return "video";
        } else {
            return null;
        }
    }}
    public bool is_source { get {
        return device.has_classes("Source");
    }}
    public bool is_sink { get {
        return device.has_classes("Sink");
    }}

    private Gst.Caps device_caps;
    private Gst.Element element;
    private Gst.Element tee;
    private Gst.Element dsp;
    private Gst.Base.Aggregator mixer;
    private Gst.Element filter;
    private int links;

    // Codecs
    private Gee.Map<PayloadType, Gst.Element> codecs = new HashMap<PayloadType, Gst.Element>(PayloadType.hash_func, PayloadType.equals_func);
    private Gee.Map<PayloadType, Gst.Element> codec_tees = new HashMap<PayloadType, Gst.Element>(PayloadType.hash_func, PayloadType.equals_func);

    // Payloaders
    private Gee.Map<PayloadType, Gee.Map<uint, Gst.Element>> payloaders = new HashMap<PayloadType, Gee.Map<uint, Gst.Element>>(PayloadType.hash_func, PayloadType.equals_func);
    private Gee.Map<PayloadType, Gee.Map<uint, Gst.Element>> payloader_tees = new HashMap<PayloadType, Gee.Map<uint, Gst.Element>>(PayloadType.hash_func, PayloadType.equals_func);
    private Gee.Map<PayloadType, Gee.Map<uint, uint>> payloader_links = new HashMap<PayloadType, Gee.Map<uint, uint>>(PayloadType.hash_func, PayloadType.equals_func);

    // Bitrate
    private Gee.Map<PayloadType, Gee.List<CodecBitrate>> codec_bitrates = new HashMap<PayloadType, Gee.List<CodecBitrate>>(PayloadType.hash_func, PayloadType.equals_func);

    private class CodecBitrate {
        public uint bitrate;
        public int64 timestamp;

        public CodecBitrate(uint bitrate) {
            this.bitrate = bitrate;
            this.timestamp = get_monotonic_time();
        }
    }

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
        if (!is_sink) return null;
        if (element == null) create();
        links++;
        if (mixer != null) {
            Gst.Element rate = Gst.ElementFactory.make("audiorate", @"$(id)_rate_$(Random.next_int())");
            pipe.add(rate);
            rate.link(mixer);
            return rate;
        }
        if (media == "audio") return filter;
        return element;
    }

    public Gst.Element? link_source(PayloadType? payload_type = null, uint ssrc = Random.next_int(), int seqnum_offset = -1, uint32 timestamp_offset = 0) {
        if (!is_source) return null;
        if (element == null) create();
        links++;
        if (payload_type != null && tee != null) {
            bool new_codec = false;
            string? codec = CodecUtil.get_codec_from_payload(media, payload_type);
            if (!codecs.has_key(payload_type)) {
                codecs[payload_type] = codec_util.get_encode_bin_without_payloader(media, payload_type, @"$(id)_$(codec)_encoder");
                pipe.add(codecs[payload_type]);
                new_codec = true;
            }
            if (!codec_tees.has_key(payload_type)) {
                codec_tees[payload_type] = Gst.ElementFactory.make("tee", @"$(id)_$(codec)_tee");
                codec_tees[payload_type].@set("allow-not-linked", true);
                pipe.add(codec_tees[payload_type]);
                codecs[payload_type].link(codec_tees[payload_type]);
            }
            if (!payloaders.has_key(payload_type)) {
                payloaders[payload_type] = new HashMap<uint, Gst.Element>();
            }
            if (!payloaders[payload_type].has_key(ssrc)) {
                payloaders[payload_type][ssrc] = codec_util.get_payloader_bin(media, payload_type, @"$(id)_$(codec)_$(ssrc)");
                var payload = (Gst.RTP.BasePayload) ((Gst.Bin) payloaders[payload_type][ssrc]).get_by_name(@"$(id)_$(codec)_$(ssrc)_rtp_pay");
                payload.ssrc = ssrc;
                payload.seqnum_offset = seqnum_offset;
                if (timestamp_offset != 0) {
                    payload.timestamp_offset = timestamp_offset;
                }
                pipe.add(payloaders[payload_type][ssrc]);
                codec_tees[payload_type].link(payloaders[payload_type][ssrc]);
                debug("Payload for %s with %s using ssrc %u, seqnum_offset %u, timestamp_offset %u", media, codec, ssrc, seqnum_offset, timestamp_offset);
            }
            if (!payloader_tees.has_key(payload_type)) {
                payloader_tees[payload_type] = new HashMap<uint, Gst.Element>();
            }
            if (!payloader_tees[payload_type].has_key(ssrc)) {
                payloader_tees[payload_type][ssrc] = Gst.ElementFactory.make("tee", @"$(id)_$(codec)_$(ssrc)_tee");
                payloader_tees[payload_type][ssrc].@set("allow-not-linked", true);
                pipe.add(payloader_tees[payload_type][ssrc]);
                payloaders[payload_type][ssrc].link(payloader_tees[payload_type][ssrc]);
            }
            if (!payloader_links.has_key(payload_type)) {
                payloader_links[payload_type] = new HashMap<uint, uint>();
            }
            if (!payloader_links[payload_type].has_key(ssrc)) {
                payloader_links[payload_type][ssrc] = 1;
            } else {
                payloader_links[payload_type][ssrc] = payloader_links[payload_type][ssrc] + 1;
            }
            if (new_codec) {
                tee.link(codecs[payload_type]);
            }
            return payloader_tees[payload_type][ssrc];
        }
        if (tee != null) return tee;
        return element;
    }

    private static double get_target_bitrate(Gst.Caps caps) {
        if (caps == null || caps.get_size() == 0) return uint.MAX;
        unowned Gst.Structure? that = caps.get_structure(0);
        int num = 0, den = 0, width = 0, height = 0;
        if (!that.has_field("width") || !that.get_int("width", out width)) return uint.MAX;
        if (!that.has_field("height") || !that.get_int("height", out height)) return uint.MAX;
        if (!that.has_field("framerate")) return uint.MAX;
        Value framerate = that.get_value("framerate");
        if (framerate.type() != typeof(Gst.Fraction)) return uint.MAX;
        num = Gst.Value.get_fraction_numerator(framerate);
        den = Gst.Value.get_fraction_denominator(framerate);
        double pxs = ((double)num/(double)den) * (double)width * (double)height;
        double br = Math.sqrt(Math.sqrt(pxs)) * 100.0 - 3700.0;
        if (br < 128.0) return 128.0;
        return br;
    }

    private const int[] common_widths = {320, 480, 640, 960, 1280, 1920, 2560, 3840};
    private Gst.Caps get_active_caps(PayloadType payload_type) {
        return codec_util.get_rescale_caps(codecs[payload_type]) ?? device_caps;
    }
    private void apply_caps(PayloadType payload_type, Gst.Caps caps) {
        plugin.pause();
        debug("Set scaled caps to %s", caps.to_string());
        codec_util.update_rescale_caps(codecs[payload_type], caps);
        plugin.unpause();
    }
    private void apply_width(PayloadType payload_type, int new_width, uint bitrate) {
        int device_caps_width, device_caps_height, active_caps_width, device_caps_framerate_num, device_caps_framerate_den;
        device_caps.get_structure(0).get_int("width", out device_caps_width);
        device_caps.get_structure(0).get_int("height", out device_caps_height);
        device_caps.get_structure(0).get_fraction("framerate", out device_caps_framerate_num, out device_caps_framerate_den);
        Gst.Caps active_caps = get_active_caps(payload_type);
        if (active_caps != null && active_caps.get_size() > 0) {
            active_caps.get_structure(0).get_int("width", out active_caps_width);
        } else {
            active_caps_width = device_caps_width;
        }
        if (new_width == active_caps_width) return;
        int new_height = device_caps_height * new_width / device_caps_width;
        Gst.Caps new_caps = new Gst.Caps.simple("video/x-raw", "width", typeof(int), new_width, "height", typeof(int), new_height, "framerate", typeof(Gst.Fraction), device_caps_framerate_num, device_caps_framerate_den, null);
        double required_bitrate = get_target_bitrate(new_caps);
        if (bitrate < required_bitrate) return;
        apply_caps(payload_type, new_caps);
    }
    public void update_bitrate(PayloadType payload_type, uint bitrate) {
        if (codecs.has_key(payload_type)) {
            lock(codec_bitrates);
            if (!codec_bitrates.has_key(payload_type)) {
                codec_bitrates[payload_type] = new ArrayList<CodecBitrate>();
            }
            codec_bitrates[payload_type].add(new CodecBitrate(bitrate));
            var remove = new ArrayList<CodecBitrate>();
            foreach (CodecBitrate rate in codec_bitrates[payload_type]) {
                if (rate.timestamp < get_monotonic_time() - 5000000L) {
                    remove.add(rate);
                    continue;
                }
                if (rate.bitrate < bitrate) {
                    bitrate = rate.bitrate;
                }
            }
            codec_bitrates[payload_type].remove_all(remove);
            if (media == "video") {
                if (bitrate < 128) bitrate = 128;
                Gst.Caps active_caps = get_active_caps(payload_type);
                double max_bitrate = get_target_bitrate(device_caps) * 2;
                double current_target_bitrate = get_target_bitrate(active_caps);
                int device_caps_width, active_caps_width;
                device_caps.get_structure(0).get_int("width", out device_caps_width);
                if (active_caps != null && active_caps.get_size() > 0) {
                    active_caps.get_structure(0).get_int("width", out active_caps_width);
                } else {
                    active_caps_width = device_caps_width;
                }
                if (bitrate < 0.75 * current_target_bitrate && active_caps_width > common_widths[0]) {
                    // Lower video resolution
                    int i = 1;
                    for(; i < common_widths.length && common_widths[i] < active_caps_width; i++);
                    apply_width(payload_type, common_widths[i-1], bitrate);
                } else if (bitrate > 2 * current_target_bitrate && active_caps_width < device_caps_width) {
                    // Higher video resolution
                    int i = 0;
                    for(; i < common_widths.length && common_widths[i] <= active_caps_width; i++);
                    if (common_widths[i] > device_caps_width) {
                        // We never scale up, so just stick with what the device gives
                        apply_width(payload_type, device_caps_width, bitrate);
                    } else if (common_widths[i] != active_caps_width) {
                        apply_width(payload_type, common_widths[i], bitrate);
                    }
                }
                if (bitrate > max_bitrate) bitrate = (uint) max_bitrate;
            }
            codec_util.update_bitrate(media, payload_type, codecs[payload_type], bitrate);
            unlock(codec_bitrates);
        }
    }

    public void unlink(Gst.Element? link = null) {
        if (links <= 0) {
            critical("Link count below zero.");
            return;
        }
        if (link != null && is_source && tee != null) {
            PayloadType payload_type = payloader_tees.first_match((entry) => entry.value.any_match((entry) => entry.value == link)).key;
            uint ssrc = payloader_tees[payload_type].first_match((entry) => entry.value == link).key;
            payloader_links[payload_type][ssrc] = payloader_links[payload_type][ssrc] - 1;
            if (payloader_links[payload_type][ssrc] == 0) {
                plugin.pause();

                codec_tees[payload_type].unlink(payloaders[payload_type][ssrc]);
                payloaders[payload_type][ssrc].set_locked_state(true);
                payloaders[payload_type][ssrc].set_state(Gst.State.NULL);
                payloaders[payload_type][ssrc].unlink(payloader_tees[payload_type][ssrc]);
                pipe.remove(payloaders[payload_type][ssrc]);
                payloaders[payload_type].unset(ssrc);
                payloader_tees[payload_type][ssrc].set_locked_state(true);
                payloader_tees[payload_type][ssrc].set_state(Gst.State.NULL);
                pipe.remove(payloader_tees[payload_type][ssrc]);
                payloader_tees[payload_type].unset(ssrc);

                payloader_links[payload_type].unset(ssrc);
                plugin.unpause();
            }
            if (payloader_links[payload_type].size == 0) {
                plugin.pause();

                tee.unlink(codecs[payload_type]);
                codecs[payload_type].set_locked_state(true);
                codecs[payload_type].set_state(Gst.State.NULL);
                codecs[payload_type].unlink(codec_tees[payload_type]);
                pipe.remove(codecs[payload_type]);
                codecs.unset(payload_type);
                codec_tees[payload_type].set_locked_state(true);
                codec_tees[payload_type].set_state(Gst.State.NULL);
                pipe.remove(codec_tees[payload_type]);
                codec_tees.unset(payload_type);

                payloaders.unset(payload_type);
                payloader_tees.unset(payload_type);
                payloader_links.unset(payload_type);
                plugin.unpause();
            }
        }
        if (link != null && is_sink && mixer != null) {
            plugin.pause();
            link.set_locked_state(true);
            Gst.Base.AggregatorPad mixer_sink_pad = (Gst.Base.AggregatorPad) link.get_static_pad("src").get_peer();
            link.get_static_pad("src").unlink(mixer_sink_pad);
            mixer_sink_pad.set_active(false);
            link.set_state(Gst.State.NULL);
            pipe.remove(link);
            mixer.release_request_pad(mixer_sink_pad);
            plugin.unpause();
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
            Value? best_fraction = null;
            int best_fps = 0;
            int best_width = 0;
            int best_height = 0;
            for (int i = 0; i < device.caps.get_size(); i++) {
                unowned Gst.Structure? that = device.caps.get_structure(i);
                if (!that.has_name("video/x-raw")) continue;
                int num = 0, den = 0, width = 0, height = 0;
                if (!that.has_field("framerate")) continue;
                Value framerate = that.get_value("framerate");
                if (framerate.type() == typeof(Gst.Fraction)) {
                    num = Gst.Value.get_fraction_numerator(framerate);
                    den = Gst.Value.get_fraction_denominator(framerate);
                } else if (framerate.type() == typeof(Gst.ValueList)) {
                    for(uint j = 0; j < Gst.ValueList.get_size(framerate); j++) {
                        Value fraction = Gst.ValueList.get_value(framerate, j);
                        int in_num = Gst.Value.get_fraction_numerator(fraction);
                        int in_den = Gst.Value.get_fraction_denominator(fraction);
                        int fps = den > 0 ? (num/den) : 0;
                        int in_fps = in_den > 0 ? (in_num/in_den) : 0;
                        if (in_fps > fps) {
                            best_fraction = fraction;
                            num = in_num;
                            den = in_den;
                        }
                    }
                } else {
                    debug("Unknown type for framerate: %s", framerate.type_name());
                }
                if (den == 0) continue;
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
            Gst.Caps res = caps_copy_nth(device.caps, best_index);
            unowned Gst.Structure? that = res.get_structure(0);
            Value framerate = that.get_value("framerate");
            if (framerate.type() == typeof(Gst.ValueList)) {
                that.set_value("framerate", best_fraction);
            }
            debug("Selected caps %s", res.to_string());
            return res;
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

    private static Gst.PadProbeReturn log_probe(Gst.Pad pad, Gst.PadProbeInfo info) {
        if ((info.type & Gst.PadProbeType.EVENT_DOWNSTREAM) > 0) {
            debug("%s.%s probed downstream event %s", pad.get_parent_element().name, pad.name, info.get_event().type.get_name());
        }
        if ((info.type & Gst.PadProbeType.EVENT_UPSTREAM) > 0) {
            var event = info.get_event();
            if (event.type == Gst.EventType.RECONFIGURE) return Gst.PadProbeReturn.DROP;
            if (event.type == Gst.EventType.QOS) {
                Gst.QOSType qos_type;
                double proportion;
                Gst.ClockTimeDiff diff;
                Gst.ClockTime timestamp;
                event.parse_qos(out qos_type, out proportion, out diff, out timestamp);
                debug("%s.%s probed qos event: type: %s, proportion: %f, diff: %lli, timestamp: %llu", pad.get_parent_element().name, pad.name, @"$qos_type", proportion, diff, timestamp);
            } else {
                debug("%s.%s probed upstream event %s", pad.get_parent_element().name, pad.name, event.type.get_name());
            }
        }
        if ((info.type & Gst.PadProbeType.QUERY_DOWNSTREAM) > 0) {
            debug("%s.%s probed downstream query %s", pad.get_parent_element().name, pad.name, info.get_query().type.get_name());
        }
        if ((info.type & Gst.PadProbeType.QUERY_UPSTREAM) > 0) {
            debug("%s.%s probed upstream query %s", pad.get_parent_element().name, pad.name, info.get_query().type.get_name());
        }
        if ((info.type & Gst.PadProbeType.BUFFER) > 0) {
            uint id = pad.get_data("no_buffer_probe_timeout");
            if (id != 0) {
                Source.remove(id);
            }
            string name = @"$(pad.get_parent_element().name).$(pad.name)";
            id = Timeout.add_seconds(1, () => {
                debug("%s probed no buffer for 1 second", name);
                return Source.REMOVE;
            });
            pad.set_data("no_buffer_probe_timeout", id);
        }
        return Gst.PadProbeReturn.PASS;
    }

    private void create() {
        debug("Creating device %s", id);
        plugin.pause();
        element = device.create_element(id);
        if (is_sink) {
            element.@set("async", false);
            element.@set("sync", false);
        }
        pipe.add(element);
        device_caps = get_best_caps();
        if (is_source) {
            element.@set("do-timestamp", true);
            filter = Gst.ElementFactory.make("capsfilter", @"caps_filter_$id");
            filter.@set("caps", device_caps);
            filter.get_static_pad("src").add_probe(Gst.PadProbeType.BLOCK, log_probe);
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
        if (is_sink && media == "audio") {
            mixer = (Gst.Base.Aggregator) Gst.ElementFactory.make("audiomixer", @"mixer_$id");
            pipe.add(mixer);
            mixer.link(pipe);
            if (plugin.echoprobe != null && !plugin.echoprobe.get_static_pad("src").is_linked()) {
                mixer.link(plugin.echoprobe);
                plugin.echoprobe.link(element);
            } else {
                filter = Gst.ElementFactory.make("capsfilter", @"caps_filter_$id");
                filter.@set("caps", device_caps);
                pipe.add(filter);
                mixer.link(filter);
                filter.link(element);
            }
        }
        plugin.unpause();
    }

    private void destroy() {
        if (is_sink) {
            if (mixer != null) {
                int linked_sink_pads = 0;
                mixer.foreach_sink_pad((_, pad) => {
                    if (pad.is_linked()) linked_sink_pads++;
                    return true;
                });
                if (linked_sink_pads > 0) {
                    warning("%s-mixer still has %i sink pads while being destroyed", id, linked_sink_pads);
                }
                mixer.unlink(plugin.echoprobe ?? element);
            }
            if (filter != null) {
                filter.set_locked_state(true);
                filter.set_state(Gst.State.NULL);
                filter.unlink(element);
                pipe.remove(filter);
                filter = null;
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
        if (mixer != null) {
            mixer.set_locked_state(true);
            mixer.set_state(Gst.State.NULL);
            pipe.remove(mixer);
            mixer = null;
        }
        if (is_source) {
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
        }
        debug("Destroyed device %s", id);
    }
}
