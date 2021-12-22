using Gee;
using Xmpp;
using Xmpp.Xep;

public class Dino.Plugins.Rtp.Module : JingleRtp.Module {
    private Set<string> supported_codecs = new HashSet<string>();
    private Set<string> unsupported_codecs = new HashSet<string>();
    public Plugin plugin { get; private set; }
    public CodecUtil codec_util { get {
        return plugin.codec_util;
    }}

    public Module(Plugin plugin) {
        base();
        this.plugin = plugin;
    }

    private async bool pipeline_works(string media, string element_desc) {
        var supported = false;
        string pipeline_desc = @"$(media)testsrc is-live=true ! $element_desc ! appsink name=output";
        try {
            var pipeline = Gst.parse_launch(pipeline_desc);
            var output = ((Gst.Bin) pipeline).get_by_name("output") as Gst.App.Sink;
            SourceFunc callback = pipeline_works.callback;
            var finished = false;
            output.emit_signals = true;
            output.new_sample.connect(() => {
                if (!finished) {
                    finished = true;
                    supported = true;
                    Idle.add(() => {
                        callback();
                        return Source.REMOVE;
                    });
                }
                return Gst.FlowReturn.EOS;
            });
            pipeline.bus.add_watch(Priority.DEFAULT, (_, message) => {
                if (message.type == Gst.MessageType.ERROR && !finished) {
                    Error e;
                    string d;
                    message.parse_error(out e, out d);
                    debug("pipeline [%s] failed: %s", pipeline_desc, e.message);
                    debug(d);
                    finished = true;
                    callback();
                }
                return true;
            });
            Timeout.add(2000, () => {
                if (!finished) {
                    finished = true;
                    callback();
                }
                return Source.REMOVE;
            });
            pipeline.set_state(Gst.State.PLAYING);
            yield;
            pipeline.set_state(Gst.State.NULL);
        } catch (Error e) {
            debug("pipeline [%s] failed: %s", pipeline_desc, e.message);
        }
        return supported;
    }

    public override async bool is_payload_supported(string media, JingleRtp.PayloadType payload_type) {
        string? codec = CodecUtil.get_codec_from_payload(media, payload_type);
        if (codec == null) return false;
        if (unsupported_codecs.contains(codec)) return false;
        if (supported_codecs.contains(codec)) return true;

        string? encode_element = codec_util.get_encode_element_name(media, codec);
        string? decode_element = codec_util.get_decode_element_name(media, codec);
        if (encode_element == null || decode_element == null) {
            warning("No suitable encoder or decoder found for %s", codec);
            unsupported_codecs.add(codec);
            return false;
        }

        string encode_bin = codec_util.get_encode_bin_description(media, codec, null, encode_element);
        while (!(yield pipeline_works(media, encode_bin))) {
            debug("%s not suited for encoding %s", encode_element, codec);
            codec_util.mark_element_unsupported(encode_element);
            encode_element = codec_util.get_encode_element_name(media, codec);
            if (encode_element == null) {
                warning("No suitable encoder found for %s", codec);
                unsupported_codecs.add(codec);
                return false;
            }
            encode_bin = codec_util.get_encode_bin_description(media, codec, null, encode_element);
        }
        debug("using %s to encode %s", encode_element, codec);

        string decode_bin = codec_util.get_decode_bin_description(media, codec, null, decode_element);
        while (!(yield pipeline_works(media, @"$encode_bin ! $decode_bin"))) {
            debug("%s not suited for decoding %s", decode_element, codec);
            codec_util.mark_element_unsupported(decode_element);
            decode_element = codec_util.get_decode_element_name(media, codec);
            if (decode_element == null) {
                warning("No suitable decoder found for %s", codec);
                unsupported_codecs.add(codec);
                return false;
            }
            decode_bin = codec_util.get_decode_bin_description(media, codec, null, decode_element);
        }
        debug("using %s to decode %s", decode_element, codec);

        supported_codecs.add(codec);
        return true;
    }

    public override bool is_header_extension_supported(string media, JingleRtp.HeaderExtension ext) {
        if (media == "video" && ext.uri == "urn:3gpp:video-orientation") return true;
        return false;
    }

    public override Gee.List<JingleRtp.HeaderExtension> get_suggested_header_extensions(string media) {
        Gee.List<JingleRtp.HeaderExtension> exts = new ArrayList<JingleRtp.HeaderExtension>();
        if (media == "video") {
            exts.add(new JingleRtp.HeaderExtension(1, "urn:3gpp:video-orientation"));
        }
        return exts;
    }

    public async void add_if_supported(Gee.List<JingleRtp.PayloadType> list, string media, JingleRtp.PayloadType payload_type) {
        if (yield is_payload_supported(media, payload_type)) {
            list.add(payload_type);
        }
    }

    public override async Gee.List<JingleRtp.PayloadType> get_supported_payloads(string media) {
        Gee.List<JingleRtp.PayloadType> list = new ArrayList<JingleRtp.PayloadType>(JingleRtp.PayloadType.equals_func);
        if (media == "audio") {
            var opus = new JingleRtp.PayloadType() { channels = 1, clockrate = 48000, name = "opus", id = 99 };
            opus.parameters["useinbandfec"] = "1";
            var speex32 = new JingleRtp.PayloadType() { channels = 1, clockrate = 32000, name = "speex", id = 100 };
            var speex16 = new JingleRtp.PayloadType() { channels = 1, clockrate = 16000, name = "speex", id = 101 };
            var speex8 = new JingleRtp.PayloadType() { channels = 1, clockrate = 8000, name = "speex", id = 102 };
            var pcmu = new JingleRtp.PayloadType() { channels = 1, clockrate = 8000, name = "PCMU", id = 0 };
            var pcma = new JingleRtp.PayloadType() { channels = 1, clockrate = 8000, name = "PCMA", id = 8 };
            yield add_if_supported(list, media, opus);
            yield add_if_supported(list, media, speex32);
            yield add_if_supported(list, media, speex16);
            yield add_if_supported(list, media, speex8);
            yield add_if_supported(list, media, pcmu);
            yield add_if_supported(list, media, pcma);
        } else if (media == "video") {
            var h264 = new JingleRtp.PayloadType() { clockrate = 90000, name = "H264", id = 96 };
            var vp9 = new JingleRtp.PayloadType() { clockrate = 90000, name = "VP9", id = 97 };
            var vp8 = new JingleRtp.PayloadType() { clockrate = 90000, name = "VP8", id = 98 };
            var rtcp_fbs = new ArrayList<JingleRtp.RtcpFeedback>();
            rtcp_fbs.add(new JingleRtp.RtcpFeedback("goog-remb"));
            rtcp_fbs.add(new JingleRtp.RtcpFeedback("ccm", "fir"));
            rtcp_fbs.add(new JingleRtp.RtcpFeedback("nack"));
            rtcp_fbs.add(new JingleRtp.RtcpFeedback("nack", "pli"));
            h264.rtcp_fbs.add_all(rtcp_fbs);
            vp9.rtcp_fbs.add_all(rtcp_fbs);
            vp8.rtcp_fbs.add_all(rtcp_fbs);
            yield add_if_supported(list, media, h264);
            yield add_if_supported(list, media, vp9);
            yield add_if_supported(list, media, vp8);
        } else {
            warning("Unsupported media type: %s", media);
        }
        return list;
    }

    public override async JingleRtp.PayloadType? pick_payload_type(string media, Gee.List<JingleRtp.PayloadType> payloads) {
        if (media == "audio") {
            foreach (JingleRtp.PayloadType type in payloads) {
                if (yield is_payload_supported(media, type)) return adjust_payload_type(media, type.clone());
            }
        } else if (media == "video") {
            // We prefer H.264 (best support for hardware acceleration and good overall codec quality)
            JingleRtp.PayloadType? h264 = payloads.first_match((it) => it.name.up() == "H264");
            if (h264 != null && yield is_payload_supported(media, h264)) return adjust_payload_type(media, h264.clone());
            // Take first of the list that we do support otherwise
            foreach (JingleRtp.PayloadType type in payloads) {
                if (yield is_payload_supported(media, type)) return adjust_payload_type(media, type.clone());
            }
        } else {
            warning("Unsupported media type: %s", media);
        }
        return null;
    }

    public JingleRtp.PayloadType adjust_payload_type(string media, JingleRtp.PayloadType type) {
        var iter = type.rtcp_fbs.iterator();
        while (iter.next()) {
            var fb = iter.@get();
            switch (fb.type_) {
                case "goog-remb":
                    if (fb.subtype != null) iter.remove();
                    break;
                case "ccm":
                    if (fb.subtype != "fir") iter.remove();
                    break;
                case "nack":
                    if (fb.subtype != null && fb.subtype != "pli") iter.remove();
                    break;
                default:
                    iter.remove();
                    break;
            }
        }
        return type;
    }

    public override JingleRtp.Stream create_stream(Jingle.Content content) {
        return plugin.open_stream(content);
    }

    public override void close_stream(JingleRtp.Stream stream) {
        var rtp_stream = stream as Rtp.Stream;
        plugin.close_stream(rtp_stream);
    }

    public override JingleRtp.Crypto? generate_local_crypto() {
        uint8[] key_and_salt = new uint8[30];
        Crypto.randomize(key_and_salt);
        return JingleRtp.Crypto.create(JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_80, key_and_salt);
    }

    public override JingleRtp.Crypto? pick_remote_crypto(Gee.List<JingleRtp.Crypto> cryptos) {
        foreach (JingleRtp.Crypto crypto in cryptos) {
            if (crypto.is_valid) return crypto;
        }
        return null;
    }

    public override JingleRtp.Crypto? pick_local_crypto(JingleRtp.Crypto? remote) {
        if (remote == null || !remote.is_valid) return null;
        uint8[] key_and_salt = new uint8[30];
        Crypto.randomize(key_and_salt);
        return remote.rekey(key_and_salt);
    }
}