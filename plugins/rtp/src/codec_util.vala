using Gee;
using Xmpp;
using Xmpp.Xep;

public class Dino.Plugins.Rtp.CodecUtil {
    private Set<string> supported_elements = new HashSet<string>();
    private Set<string> unsupported_elements = new HashSet<string>();

    public static Gst.Caps get_caps(string media, JingleRtp.PayloadType payload_type) {
        Gst.Caps caps = new Gst.Caps.simple("application/x-rtp",
                "media", typeof(string), media,
                "payload", typeof(int), payload_type.id);
        //"channels", typeof(int), payloadType.channels,
                //"max-ptime", typeof(int), payloadType.maxptime);
        unowned Gst.Structure s = caps.get_structure(0);
        if (payload_type.clockrate != 0) {
            s.set("clock-rate", typeof(int), payload_type.clockrate);
        }
        if (payload_type.name != null) {
            s.set("encoding-name", typeof(string), payload_type.name.up());
        }
        return caps;
    }

    public static string? get_codec_from_payload(string media, JingleRtp.PayloadType payload_type) {
        if (payload_type.name != null) return payload_type.name.down();
        if (media == "audio") {
            switch (payload_type.id) {
                case 0:
                    return "pcmu";
                case 8:
                    return "pcma";
            }
        }
        return null;
    }

    public static string? get_media_type_from_payload(string media, JingleRtp.PayloadType payload_type) {
        return get_media_type(media, get_codec_from_payload(media, payload_type));
    }

    public static string? get_media_type(string media, string? codec) {
        if (codec == null) return null;
        if (media == "audio") {
            switch (codec) {
                case "pcma":
                    return "audio/x-alaw";
                case "pcmu":
                    return "audio/x-mulaw";
            }
        }
        return @"$media/x-$codec";
    }

    public static string? get_rtp_pay_element_name_from_payload(string media, JingleRtp.PayloadType payload_type) {
        return get_pay_candidate(media, get_codec_from_payload(media, payload_type));
    }

    public static string? get_pay_candidate(string media, string? codec) {
        if (codec == null) return null;
        return @"rtp$(codec)pay";
    }

    public static string? get_rtp_depay_element_name_from_payload(string media, JingleRtp.PayloadType payload_type) {
        return get_depay_candidate(media, get_codec_from_payload(media, payload_type));
    }

    public static string? get_depay_candidate(string media, string? codec) {
        if (codec == null) return null;
        return @"rtp$(codec)depay";
    }

    public static string[] get_encode_candidates(string media, string? codec) {
        if (codec == null) return new string[0];
        if (media == "audio") {
            switch (codec) {
                case "opus":
                    return new string[] {"opusenc"};
                case "speex":
                    return new string[] {"speexenc"};
                case "pcma":
                    return new string[] {"alawenc"};
                case "pcmu":
                    return new string[] {"mulawenc"};
            }
        } else if (media == "video") {
            switch (codec) {
                case "h264":
                    return new string[] {/*"msdkh264enc", */"vaapih264enc", "x264enc"};
                case "vp9":
                    return new string[] {/*"msdkvp9enc", */"vaapivp9enc" /*, "vp9enc" */};
                case "vp8":
                    return new string[] {/*"msdkvp8enc", */"vaapivp8enc", "vp8enc"};
            }
        }
        return new string[0];
    }

    public static string[] get_decode_candidates(string media, string? codec) {
        if (codec == null) return new string[0];
        if (media == "audio") {
            switch (codec) {
                case "opus":
                    return new string[] {"opusdec"};
                case "speex":
                    return new string[] {"speexdec"};
                case "pcma":
                    return new string[] {"alawdec"};
                case "pcmu":
                    return new string[] {"mulawdec"};
            }
        } else if (media == "video") {
            switch (codec) {
                case "h264":
                    return new string[] {/*"msdkh264dec", */"vaapih264dec"};
                case "vp9":
                    return new string[] {/*"msdkvp9dec", */"vaapivp9dec", "vp9dec"};
                case "vp8":
                    return new string[] {/*"msdkvp8dec", */"vaapivp8dec", "vp8dec"};
            }
        }
        return new string[0];
    }

    public static string? get_encode_prefix(string media, string codec, string encode) {
        if (encode == "msdkh264enc") return "video/x-raw,format=NV12 ! ";
        if (encode == "vaapih264enc") return "video/x-raw,format=NV12 ! ";
        return null;
    }

    public static string? get_encode_suffix(string media, string codec, string encode) {
        // H264
        const string h264_suffix = " ! video/x-h264,profile=constrained-baseline ! h264parse";
        if (encode == "msdkh264enc") return @" bitrate=256 rate-control=vbr target-usage=7$h264_suffix";
        if (encode == "vaapih264enc") return @" bitrate=256 quality-level=7 tune=low-power$h264_suffix";
        if (encode == "x264enc") return @" byte-stream=1 bitrate=256 profile=baseline speed-preset=ultrafast tune=zerolatency$h264_suffix";
        if (media == "video" && codec == "h264") return h264_suffix;

        // VP8
        if (encode == "msdkvp8enc") return " bitrate=256 rate-control=vbr target-usage=7";
        if (encode == "vaapivp8enc") return " bitrate=256 rate-control=vbr quality-level=7";
        if (encode == "vp8enc") return " target-bitrate=256000 deadline=1 error-resilient=1";

        // OPUS
        if (encode == "opusenc") return " audio-type=voice";

        return null;
    }

    public static string? get_decode_prefix(string media, string codec, string decode) {
        return null;
    }

    public bool is_element_supported(string element_name) {
        if (unsupported_elements.contains(element_name)) return false;
        if (supported_elements.contains(element_name)) return true;
        var test_element = Gst.ElementFactory.make(element_name, @"test-$element_name");
        if (test_element != null) {
            supported_elements.add(element_name);
            return true;
        } else {
            debug("%s is not supported on this platform", element_name);
            unsupported_elements.add(element_name);
            return false;
        }
    }

    public string? get_encode_element_name(string media, string? codec) {
        foreach (string candidate in get_encode_candidates(media, codec)) {
            if (is_element_supported(candidate)) return candidate;
        }
        return null;
    }

    public string? get_pay_element_name(string media, string? codec) {
        string candidate = get_pay_candidate(media, codec);
        if (is_element_supported(candidate)) return candidate;
        return null;
    }

    public string? get_decode_element_name(string media, string? codec) {
        foreach (string candidate in get_decode_candidates(media, codec)) {
            if (is_element_supported(candidate)) return candidate;
        }
        return null;
    }

    public string? get_depay_element_name(string media, string? codec) {
        string candidate = get_depay_candidate(media, codec);
        if (is_element_supported(candidate)) return candidate;
        return null;
    }

    public void mark_element_unsupported(string element_name) {
        unsupported_elements.add(element_name);
    }

    public string? get_decode_bin_description(string media, string? codec, string? element_name = null, string? name = null) {
        if (codec == null) return null;
        string base_name = name ?? @"encode-$codec-$(Random.next_int())";
        string depay = get_depay_element_name(media, codec);
        string decode = element_name ?? get_decode_element_name(media, codec);
        if (depay == null || decode == null) return null;
        string decode_prefix = get_decode_prefix(media, codec, decode) ?? "";
        return @"$depay name=$base_name-rtp-depay ! $decode_prefix$decode name=$base_name-decode ! $(media)convert name=$base_name-convert";
    }

    public Gst.Element? get_decode_bin(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"encode-$codec-$(Random.next_int())";
        string? desc = get_decode_bin_description(media, codec, null, base_name);
        if (desc == null) return null;
        debug("Pipeline to decode %s %s: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

    public string? get_encode_bin_description(string media, string? codec, string? element_name = null, uint pt = 96, string? name = null) {
        if (codec == null) return null;
        string base_name = name ?? @"encode-$codec-$(Random.next_int())";
        string pay = get_pay_element_name(media, codec);
        string encode = element_name ?? get_encode_element_name(media, codec);
        if (pay == null || encode == null) return null;
        string encode_prefix = get_encode_prefix(media, codec, encode) ?? "";
        string encode_suffix = get_encode_suffix(media, codec, encode) ?? "";
        if (media == "audio") {
            return @"audioconvert name=$base_name-convert ! audioresample name=$base_name-resample ! $encode_prefix$encode$encode_suffix ! $pay pt=$pt name=$base_name-rtp-pay";
        } else {
            return @"$(media)convert name=$base_name-convert ! $encode_prefix$encode$encode_suffix ! $pay pt=$pt name=$base_name-rtp-pay";
        }
    }

    public Gst.Element? get_encode_bin(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"encode-$codec-$(Random.next_int())";
        string? desc = get_encode_bin_description(media, codec, null, payload_type.id, base_name);
        if (desc == null) return null;
        debug("Pipeline to encode %s %s: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

}