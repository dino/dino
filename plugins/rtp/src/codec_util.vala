using Gee;
using Xmpp;
using Xmpp.Xep;

public class Dino.Plugins.Rtp.CodecUtil {
    private Set<string> supported_elements = new HashSet<string>();
    private Set<string> unsupported_elements = new HashSet<string>();

    public static Gst.Caps get_caps(string media, JingleRtp.PayloadType payload_type, bool incoming) {
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
        if (incoming) {
            foreach (JingleRtp.RtcpFeedback rtcp_fb in payload_type.rtcp_fbs) {
                if (rtcp_fb.subtype == null) {
                    s.set(@"rtcp-fb-$(rtcp_fb.type_)", typeof(bool), true);
                } else {
                    s.set(@"rtcp-fb-$(rtcp_fb.type_)-$(rtcp_fb.subtype)", typeof(bool), true);
                }
            }
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
                case "g722":
                    return new string[] {"avenc_g722"};
            }
        } else if (media == "video") {
            switch (codec) {
                case "h264":
                    return new string[] {
#if ENABLE_MSDK
                        "msdkh264enc",
#endif
#if ENABLE_VAAPI
                        "vah264lpenc",
                        "vah264enc",
#endif
                        "x264enc"
                    };
                case "vp8":
                    return new string[] {
#if ENABLE_MSDK
                        "msdkvp8enc",
#endif
#if ENABLE_VAAPI
                        "vavp8enc",
#endif
                        "vp8enc"
                    };
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
                case "g722":
                    return new string[] {"avdec_g722"};
            }
        } else if (media == "video") {
            switch (codec) {
                case "h264":
                    return new string[] {
#if ENABLE_MSDK
                        "msdkh264dec",
#endif
#if ENABLE_VAAPI
                        "vah264dec",
#endif
#if ENABLE_V4L2
                        "v4l2h264dec",
#endif
#if ENABLE_V4L2SL
                        "v4l2slh264dec",
#endif
                        "avdec_h264"
                    };
                case "vp8":
                    return new string[] {
#if ENABLE_MSDK
                        "msdkvp8dec",
#endif
#if ENABLE_VAAPI
                        "vavp8dec",
#endif
#if ENABLE_V4L2
                        "v4l2vp8dec",
#endif
#if ENABLE_V4L2SL
                        "v4l2slvp8dec",
#endif
                        "vp8dec"
                    };
            }
        }
        return new string[0];
    }

    public static string? get_encode_prefix(string media, string codec, string encode, JingleRtp.PayloadType? payload_type) {
        if (encode == "msdkh264enc") return "capsfilter caps=video/x-raw,format=NV12 ! ";
        if (encode == "vah264lpenc" || encode == "vah264enc") return "capsfilter caps=video/x-raw,format=NV12 ! ";
        return null;
    }

    public static string? get_encode_args(string media, string codec, string encode, JingleRtp.PayloadType? payload_type) {
        // H264
        if (encode == "msdkh264enc") return @" rate-control=vbr";
        if (encode == "vah264lpenc" || encode == "vah264enc") return @" rate-control=vbr";
        if (encode == "x264enc") return @" byte-stream=1 speed-preset=faster tune=zerolatency bframes=0 cabac=false dct8x8=false";

        // VP8
        if (encode == "vavp8enc" || encode == "msdkvp8enc") return " rate-control=vbr target-percentage=90";
        if (encode == "vp8enc") return " deadline=1 error-resilient=3 lag-in-frames=0 resize-allowed=true threads=8 dropframe-threshold=30 end-usage=vbr cpu-used=4";

        // OPUS
        if (encode == "opusenc") {
            if (payload_type != null && payload_type.parameters.has("useinbandfec", "1")) return " audio-type=voice inband-fec=true";
            return " audio-type=voice";
        }

        return null;
    }

    public static string? get_encode_suffix(string media, string codec, string encode, JingleRtp.PayloadType? payload_type) {
        // H264
        if (media == "video" && codec == "h264") return " ! capsfilter caps=video/x-h264,profile=constrained-baseline ! h264parse";
        if (media == "video" && codec == "vp8" && encode == "vp8enc") return " ! capsfilter caps=video/x-vp8,profile=(string)1";
        return null;
    }

    public uint update_bitrate(string media, JingleRtp.PayloadType payload_type, Gst.Element encode_element, uint bitrate) {
        Gst.Bin? encode_bin = encode_element as Gst.Bin;
        if (encode_bin == null) return 0;
        string? codec = get_codec_from_payload(media, payload_type);
        string? encode_name = get_encode_element_name(media, codec);
        if (encode_name == null) return 0;
        Gst.Element encode = encode_bin.get_by_name(@"$(encode_bin.name)_encode");

        switch (encode_name) {
            case "msdkh264enc":
            case "vah264lpenc":
            case "vah264enc":
            case "x264enc":
            case "msdkvp8enc":
            case "vavp8enc":
                bitrate = uint.min(2048000, bitrate);
                encode.set("bitrate", bitrate);
                return bitrate;
            case "vp8enc":
                bitrate = uint.min(2147483, bitrate);
                encode.set("target-bitrate", bitrate * 1024);
                return bitrate;
        }

        return 0;
    }

    public void update_rescale_caps(Gst.Element encode_element, Gst.Caps caps) {
        Gst.Bin? encode_bin = encode_element as Gst.Bin;
        if (encode_bin == null) return;
        Gst.Element rescale_caps = encode_bin.get_by_name(@"$(encode_bin.name)_rescale_caps");
        rescale_caps.set("caps", caps);
    }

    public Gst.Caps? get_rescale_caps(Gst.Element encode_element) {
        Gst.Bin? encode_bin = encode_element as Gst.Bin;
        if (encode_bin == null) return null;
        Gst.Element rescale_caps = encode_bin.get_by_name(@"$(encode_bin.name)_rescale_caps");
        Gst.Caps caps;
        rescale_caps.get("caps", out caps);
        return caps;
    }

    public static string? get_decode_prefix(string media, string codec, string decode, JingleRtp.PayloadType? payload_type) {
        if (decode == "vah264dec" || decode == "v4l2h264dec" || decode == "v4l2slh264dec" || decode == "avdec_h264") return "h264parse ! ";
        return null;
    }

    public static string? get_decode_args(string media, string codec, string decode, JingleRtp.PayloadType? payload_type) {
        if (decode == "opusdec" && payload_type != null && payload_type.parameters.has("useinbandfec", "1")) return " use-inband-fec=true";
        if (decode == "vavp8dec" || decode == "v4l2vp8dec" || decode == "v4l2slvp8dec" || decode == "vah264dec" || decode == "v4l2h264dec" || decode == "v4l2slh264dec") return " max-errors=100";
        if (decode == "vp8dec") return " threads=8";
        return null;
    }

    public static string? get_decode_suffix(string media, string codec, string encode, JingleRtp.PayloadType? payload_type) {
        return null;
    }

    public static string? get_depay_args(string media, string codec, string encode, JingleRtp.PayloadType? payload_type) {
#if GST_1_18
        if (codec == "vp8") return " wait-for-keyframe=true";
#endif
        return null;
    }

    public bool is_element_supported(string? element_name) {
        if (element_name == null) return false;
        if (unsupported_elements.contains(element_name)) return false;
        if (supported_elements.contains(element_name)) return true;
        var test_element = Gst.ElementFactory.make(element_name, @"test-$element_name");
        if (test_element != null) {
            supported_elements.add(element_name);
            return true;
        } else {
            info("%s is not installed or supported on this system", element_name);
            unsupported_elements.add(element_name);
            return false;
        }
    }

    public string? get_encode_element_name(string media, string? codec) {
        if (get_pay_element_name(media, codec) == null) return null;
        foreach (string candidate in get_encode_candidates(media, codec)) {
            if (is_element_supported(candidate)) return candidate;
        }
        return null;
    }

    public string? get_pay_element_name(string media, string? codec) {
        string? candidate = get_pay_candidate(media, codec);
        if (candidate != null && is_element_supported(candidate)) return candidate;
        return null;
    }

    public string? get_decode_element_name(string media, string? codec) {
        if (get_depay_element_name(media, codec) == null) return null;
        foreach (string candidate in get_decode_candidates(media, codec)) {
            if (is_element_supported(candidate)) return candidate;
        }
        return null;
    }

    public string? get_depay_element_name(string media, string? codec) {
        string? candidate = get_depay_candidate(media, codec);
        if (candidate != null && is_element_supported(candidate)) return candidate;
        return null;
    }

    public void mark_element_unsupported(string element_name) {
        unsupported_elements.add(element_name);
    }

    public string? get_decode_bin_description(string media, string? codec, JingleRtp.PayloadType? payload_type, string? element_name = null, string? name = null) {
        if (codec == null) return null;
        string base_name = name ?? @"encode-$codec-$(Random.next_int())";
        string? depay = get_depay_element_name(media, codec);
        string? decode = element_name ?? get_decode_element_name(media, codec);
        if (depay == null || decode == null) return null;
        string decode_prefix = get_decode_prefix(media, codec, decode, payload_type) ?? "";
        string decode_args = get_decode_args(media, codec, decode, payload_type) ?? "";
        string decode_suffix = get_decode_suffix(media, codec, decode, payload_type) ?? "";
        string depay_args = get_depay_args(media, codec, decode, payload_type) ?? "";
        string resample = media == "audio" ? @" ! audioresample name=$(base_name)_resample" : "";
        return @"queue ! $depay$depay_args name=$(base_name)_rtp_depay ! $decode_prefix$decode$decode_args name=$(base_name)_$(codec)_decode$decode_suffix ! $(media)convert name=$(base_name)_convert$resample";
    }

    public Gst.Element? get_decode_bin(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"decode_$(codec)_$(Random.next_int())";
        string? desc = get_decode_bin_description(media, codec, payload_type, null, base_name);
        if (desc == null) return null;
        debug("Pipeline to decode %s %s: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

    public string? get_encode_bin_description(string media, string? codec, JingleRtp.PayloadType? payload_type, string? element_name = null, string? name = null) {
        string? desc1 = get_encode_bin_without_payloader_description(media, codec, payload_type, element_name, name);
        string? desc2 = get_payloader_bin_description(media, codec, payload_type, name);
        return @"$desc1 ! $desc2";
    }

    public string? get_payloader_bin_description(string media, string? codec, JingleRtp.PayloadType? payload_type, string? name = null) {
        if (codec == null) return null;
        string base_name = name ?? @"encode_$(codec)_$(Random.next_int())";
        string? pay = get_pay_element_name(media, codec);
        if (pay == null) return null;
        return @"$pay pt=$(payload_type != null ? payload_type.id : 96) name=$(base_name)_rtp_pay";
    }

    public string? get_encode_bin_without_payloader_description(string media, string? codec, JingleRtp.PayloadType? payload_type, string? element_name = null, string? name = null) {
        if (codec == null) return null;
        string base_name = name ?? @"encode_$(codec)_$(Random.next_int())";
        string? encode = element_name ?? get_encode_element_name(media, codec);
        if (encode == null) return null;
        string encode_prefix = get_encode_prefix(media, codec, encode, payload_type) ?? "";
        string encode_args = get_encode_args(media, codec, encode, payload_type) ?? "";
        string encode_suffix = get_encode_suffix(media, codec, encode, payload_type) ?? "";
        string rescale = media == "audio" ? @" ! audioresample name=$(base_name)_resample" : @" ! videoscale name=$(base_name)_rescale ! capsfilter name=$(base_name)_rescale_caps";
        return @"$(media)convert name=$(base_name)_convert$rescale ! queue ! $encode_prefix$encode$encode_args name=$(base_name)_encode$encode_suffix";
    }

    public Gst.Element? get_encode_bin(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"encode_$(codec)_$(Random.next_int())";
        string? desc = get_encode_bin_description(media, codec, payload_type, null, base_name);
        if (desc == null) return null;
        debug("Pipeline to encode %s %s: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

    public Gst.Element? get_encode_bin_without_payloader(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"encode_$(codec)_$(Random.next_int())";
        string? desc = get_encode_bin_without_payloader_description(media, codec, payload_type, null, base_name);
        if (desc == null) return null;
        debug("Pipeline to encode %s %s without payloader: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

    public Gst.Element? get_payloader_bin(string media, JingleRtp.PayloadType payload_type, string? name = null) {
        string? codec = get_codec_from_payload(media, payload_type);
        string base_name = name ?? @"encode_$(codec)_$(Random.next_int())";
        string? desc = get_payloader_bin_description(media, codec, payload_type, base_name);
        if (desc == null) return null;
        debug("Pipeline to payload %s %s: %s", media, codec, desc);
        Gst.Element bin = Gst.parse_bin_from_description(desc, true);
        bin.name = name;
        return bin;
    }

}
