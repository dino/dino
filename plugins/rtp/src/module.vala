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
            var output = (pipeline as Gst.Bin).get_by_name("output") as Gst.App.Sink;
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

    private async bool supports(string media, JingleRtp.PayloadType payload_type) {
        string codec = CodecUtil.get_codec_from_payload(media, payload_type);
        if (codec == null) return false;
        if (unsupported_codecs.contains(codec)) return false;
        if (supported_codecs.contains(codec)) return true;

        string encode_element = codec_util.get_encode_element_name(media, codec);
        string decode_element = codec_util.get_decode_element_name(media, codec);
        if (encode_element == null || decode_element == null) {
            debug("No suitable encoder or decoder found for %s", codec);
            unsupported_codecs.add(codec);
            return false;
        }

        string encode_bin = codec_util.get_encode_bin_description(media, codec, encode_element);
        while (!(yield pipeline_works(media, encode_bin))) {
            debug("%s not suited for encoding %s", encode_element, codec);
            codec_util.mark_element_unsupported(encode_element);
            encode_element = codec_util.get_encode_element_name(media, codec);
            if (encode_element == null) {
                debug("No suitable encoder found for %s", codec);
                unsupported_codecs.add(codec);
                return false;
            }
            encode_bin = codec_util.get_encode_bin_description(media, codec, encode_element);
        }
        debug("using %s to encode %s", encode_element, codec);

        string decode_bin = codec_util.get_decode_bin_description(media, codec, decode_element);
        while (!(yield pipeline_works(media, @"$encode_bin ! $decode_bin"))) {
            debug("%s not suited for decoding %s", decode_element, codec);
            codec_util.mark_element_unsupported(decode_element);
            decode_element = codec_util.get_decode_element_name(media, codec);
            if (decode_element == null) {
                debug("No suitable decoder found for %s", codec);
                unsupported_codecs.add(codec);
                return false;
            }
            decode_bin = codec_util.get_decode_bin_description(media, codec, decode_element);
        }
        debug("using %s to decode %s", decode_element, codec);

        supported_codecs.add(codec);
        return true;
    }

    public async void add_if_supported(Gee.List<JingleRtp.PayloadType> list, string media, JingleRtp.PayloadType payload_type) {
        if (yield supports(media, payload_type)) {
            list.add(payload_type);
        }
    }

    public override async Gee.List<JingleRtp.PayloadType> get_supported_payloads(string media) {
        Gee.List<JingleRtp.PayloadType> list = new ArrayList<JingleRtp.PayloadType>(JingleRtp.PayloadType.equals_func);
        if (media == "audio") {
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 2,
                clockrate = 48000,
                name = "opus",
                id = 99
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 1,
                clockrate = 32000,
                name = "speex",
                id = 100
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 1,
                clockrate = 16000,
                name = "speex",
                id = 101
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 1,
                clockrate = 8000,
                name = "speex",
                id = 102
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 1,
                clockrate = 8000,
                name = "PCMU",
                id = 0
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                channels = 1,
                clockrate = 8000,
                name = "PCMA",
                id = 8
            });
        } else if (media == "video") {
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                clockrate = 90000,
                name = "H264",
                id = 96
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                clockrate = 90000,
                name = "VP9",
                id = 97
            });
            yield add_if_supported(list, media, new JingleRtp.PayloadType() {
                clockrate = 90000,
                name = "VP8",
                id = 98
            });
        } else {
            warning("Unsupported media type: %s", media);
        }
        return list;
    }

    public override async JingleRtp.PayloadType? pick_payload_type(string media, Gee.List<JingleRtp.PayloadType> payloads) {
        if (media == "audio") {
            foreach (JingleRtp.PayloadType type in payloads) {
                if (yield supports(media, type)) return type;
            }
        } else if (media == "video") {
            foreach (JingleRtp.PayloadType type in payloads) {
                if (yield supports(media, type)) return type;
            }
        } else {
            warning("Unsupported media type: %s", media);
        }
        return null;
    }

    public override JingleRtp.Stream create_stream(Jingle.Content content) {
        return plugin.open_stream(content);
    }

    public override void close_stream(JingleRtp.Stream stream) {
        var rtp_stream = stream as Rtp.Stream;
        plugin.close_stream(rtp_stream);
    }

    public override JingleRtp.Crypto? generate_local_crypto() {
        uint8[] keyAndSalt = new uint8[30];
        Crypto.randomize(keyAndSalt);
        return JingleRtp.Crypto.create(JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_80, keyAndSalt);
    }

    public override JingleRtp.Crypto? pick_remote_crypto(Gee.List<JingleRtp.Crypto> cryptos) {
        foreach (JingleRtp.Crypto crypto in cryptos) {
            if (crypto.is_valid) return crypto;
        }
        return null;
    }

    public override JingleRtp.Crypto? pick_local_crypto(JingleRtp.Crypto? remote) {
        if (remote == null || !remote.is_valid) return null;
        uint8[] keyAndSalt = new uint8[30];
        Crypto.randomize(keyAndSalt);
        return remote.rekey(keyAndSalt);
    }
}