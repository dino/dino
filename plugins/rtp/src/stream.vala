using Gee;
using Xmpp;

public class Dino.Plugins.Rtp.Stream : Xmpp.Xep.JingleRtp.Stream {
    public uint8 rtpid { get; private set; }

    public Plugin plugin { get; private set; }
    public Gst.Pipeline pipe { get {
        return plugin.pipe;
    }}
    public Gst.Element rtpbin { get {
        return plugin.rtpbin;
    }}
    public CodecUtil codec_util { get {
        return plugin.codec_util;
    }}
    private Gst.App.Sink send_rtp;
    private Gst.App.Sink send_rtcp;
    private Gst.App.Src recv_rtp;
    private Gst.App.Src recv_rtcp;
    private Gst.Element decode;
    private Gst.RTP.BaseDepayload decode_depay;
    private Gst.Element input;
    private Gst.Pad input_pad;
    private Gst.Element output;
    private Gst.Element session;

    private Device _input_device;
    public Device input_device { get { return _input_device; } set {
        if (!paused) {
            var input = this.input;
            set_input(value != null ? value.link_source(payload_type, our_ssrc, next_seqnum_offset, next_timestamp_offset) : null);
            if (this._input_device != null) this._input_device.unlink(input);
        }
        this._input_device = value;
    }}
    private Device _output_device;
    public Device output_device { get { return _output_device; } set {
        if (output != null) remove_output(output);
        if (value != null) add_output(value.link_sink());
        this._output_device = value;
    }}

    public bool created { get; private set; default = false; }
    public bool paused { get; private set; default = false; }
    private bool push_recv_data = false;
    private uint our_ssrc = Random.next_int();
    private int next_seqnum_offset = -1;
    private uint32 next_timestamp_offset_base = 0;
    private int64 next_timestamp_offset_stamp = 0;
    private uint32 next_timestamp_offset { get {
        if (next_timestamp_offset_base == 0) return 0;
        int64 monotonic_diff = get_monotonic_time() - next_timestamp_offset_stamp;
        return next_timestamp_offset_base + (uint32)((double)monotonic_diff / 1000000.0 * payload_type.clockrate);
    } }
    private uint32 participant_ssrc = 0;

    private Gst.Pad recv_rtcp_sink_pad;
    private Gst.Pad recv_rtp_sink_pad;
    private Gst.Pad recv_rtp_src_pad;
    private Gst.Pad send_rtcp_src_pad;
    private Gst.Pad send_rtp_sink_pad;
    private Gst.Pad send_rtp_src_pad;

    private Crypto.Srtp.Session? crypto_session = new Crypto.Srtp.Session();

    public Stream(Plugin plugin, Xmpp.Xep.Jingle.Content content) {
        base(content);
        this.plugin = plugin;
        this.rtpid = plugin.next_free_id();

        content.notify["senders"].connect_after(on_senders_changed);
    }

    public void on_senders_changed() {
        if (sending && input == null) {
            input_device = plugin.get_preferred_device(media, false);
        }
        if (receiving && output == null) {
            output_device = plugin.get_preferred_device(media, true);
        }
    }

    public override void create() {
        plugin.pause();

        // Create i/o if needed

        if (input == null && input_device == null && sending) {
            input_device = plugin.get_preferred_device(media, false);
        }
        if (output == null && output_device == null && receiving && media == "audio") {
            output_device = plugin.get_preferred_device(media, true);
        }

        // Create app elements
        send_rtp = Gst.ElementFactory.make("appsink", @"rtp_sink_$rtpid") as Gst.App.Sink;
        send_rtp.async = false;
        send_rtp.caps = CodecUtil.get_caps(media, payload_type, false);
        send_rtp.emit_signals = true;
        send_rtp.sync = true;
        send_rtp.drop = true;
        send_rtp.wait_on_eos = false;
        send_rtp.new_sample.connect(on_new_sample);
        send_rtp.connect("signal::eos", on_eos_static, this);
        pipe.add(send_rtp);

        send_rtcp = Gst.ElementFactory.make("appsink", @"rtcp_sink_$rtpid") as Gst.App.Sink;
        send_rtcp.async = false;
        send_rtcp.caps = new Gst.Caps.empty_simple("application/x-rtcp");
        send_rtcp.emit_signals = true;
        send_rtcp.sync = true;
        send_rtcp.drop = true;
        send_rtcp.wait_on_eos = false;
        send_rtcp.new_sample.connect(on_new_sample);
        send_rtcp.connect("signal::eos", on_eos_static, this);
        pipe.add(send_rtcp);

        recv_rtp = Gst.ElementFactory.make("appsrc", @"rtp_src_$rtpid") as Gst.App.Src;
        recv_rtp.caps = CodecUtil.get_caps(media, payload_type, true);
        recv_rtp.do_timestamp = true;
        recv_rtp.format = Gst.Format.TIME;
        recv_rtp.is_live = true;
        pipe.add(recv_rtp);

        recv_rtcp = Gst.ElementFactory.make("appsrc", @"rtcp_src_$rtpid") as Gst.App.Src;
        recv_rtcp.caps = new Gst.Caps.empty_simple("application/x-rtcp");
        recv_rtcp.do_timestamp = true;
        recv_rtcp.format = Gst.Format.TIME;
        recv_rtcp.is_live = true;
        pipe.add(recv_rtcp);

        // Connect RTCP
        send_rtcp_src_pad = rtpbin.get_request_pad(@"send_rtcp_src_$rtpid");
        send_rtcp_src_pad.link(send_rtcp.get_static_pad("sink"));
        recv_rtcp_sink_pad = rtpbin.get_request_pad(@"recv_rtcp_sink_$rtpid");
        recv_rtcp.get_static_pad("src").link(recv_rtcp_sink_pad);

        // Connect input
        send_rtp_sink_pad = rtpbin.get_request_pad(@"send_rtp_sink_$rtpid");
        if (input != null) {
            input_pad = input.get_request_pad(@"src_$rtpid");
            input_pad.link(send_rtp_sink_pad);
        }

        // Connect output
        decode = codec_util.get_decode_bin(media, payload_type, @"decode_$rtpid");
        decode_depay = (Gst.RTP.BaseDepayload)((Gst.Bin)decode).get_by_name(@"decode_$(rtpid)_rtp_depay");
        pipe.add(decode);
        if (output != null) {
            decode.link(output);
        }

        // Connect RTP
        recv_rtp_sink_pad = rtpbin.get_request_pad(@"recv_rtp_sink_$rtpid");
        recv_rtp.get_static_pad("src").link(recv_rtp_sink_pad);

        created = true;
        push_recv_data = true;
        plugin.unpause();

        GLib.Signal.emit_by_name(rtpbin, "get-session", rtpid, out session);
        if (session != null && remb_enabled) {
            Object internal_session;
            session.@get("internal-session", out internal_session);
            if (internal_session != null) {
                internal_session.connect("signal::on-feedback-rtcp", on_feedback_rtcp, this);
            }
            Timeout.add(1000, () => remb_adjust());
        }
        if (input_device != null && media == "video") {
            input_device.update_bitrate(payload_type, target_send_bitrate);
        }
    }

    private int last_packets_lost = -1;
    private uint64 last_packets_received = 0;
    private uint64 last_octets_received = 0;
    private uint max_target_receive_bitrate = 0;
    private int64 last_remb_time = 0;
    private bool remb_adjust() {
        unowned Gst.Structure? stats;
        if (session == null) {
            debug("Session for %u finished, turning off remb adjustment", rtpid);
            return Source.REMOVE;
        }
        session.get("stats", out stats);
        if (stats == null) {
            warning("No stats for session %u", rtpid);
            return Source.REMOVE;
        }
        unowned ValueArray? source_stats;
        stats.get("source-stats", typeof(ValueArray), out source_stats);
        if (source_stats == null) {
            warning("No source-stats for session %u", rtpid);
            return Source.REMOVE;
        }

        if (input_device == null) return Source.CONTINUE;

        foreach (Value value in source_stats.values) {
            unowned Gst.Structure source_stat = (Gst.Structure) value.get_boxed();
            uint32 ssrc;
            if (!source_stat.get_uint("ssrc", out ssrc)) continue;
            if (ssrc == participant_ssrc) {
                int packets_lost;
                uint64 packets_received, octets_received;
                source_stat.get_int("packets-lost", out packets_lost);
                source_stat.get_uint64("packets-received", out packets_received);
                source_stat.get_uint64("octets-received", out octets_received);
                int new_lost = packets_lost - last_packets_lost;
                if (new_lost < 0) new_lost = 0;
                uint64 new_received = packets_received - last_packets_received;
                if (packets_received < last_packets_received) new_received = 0;
                uint64 new_octets = octets_received - last_octets_received;
                if (octets_received < last_octets_received) octets_received = 0;
                if (new_received == 0) continue;
                last_packets_lost = packets_lost;
                last_packets_received = packets_received;
                last_octets_received = octets_received;
                double loss_rate = (double)new_lost / (double)(new_lost + new_received);
                uint new_target_receive_bitrate;
                if (new_lost <= 0 || loss_rate < 0.02) {
                    new_target_receive_bitrate = (uint)(1.08 * (double)target_receive_bitrate);
                } else if (loss_rate > 0.1) {
                    new_target_receive_bitrate = (uint)((1.0 - 0.5 * loss_rate) * (double)target_receive_bitrate);
                } else {
                    new_target_receive_bitrate = target_receive_bitrate;
                }
                if (last_remb_time == 0) {
                    last_remb_time = get_monotonic_time();
                } else {
                    int64 time_now = get_monotonic_time();
                    int64 time_diff = time_now - last_remb_time;
                    last_remb_time = time_now;
                    uint actual_bitrate = (uint)(((double)new_octets * 8.0) * (double)time_diff / 1000.0 / 1000000.0);
                    new_target_receive_bitrate = uint.max(new_target_receive_bitrate, (uint)(0.9 * (double)actual_bitrate));
                    max_target_receive_bitrate = uint.max((uint)(1.5 * (double)actual_bitrate), max_target_receive_bitrate);
                    new_target_receive_bitrate = uint.min(new_target_receive_bitrate, max_target_receive_bitrate);
                }
                new_target_receive_bitrate = uint.max(16, new_target_receive_bitrate); // Never go below 16
                if (new_target_receive_bitrate != target_receive_bitrate) {
                    target_receive_bitrate = new_target_receive_bitrate;
                    uint8[] data = new uint8[] {
                        143, 206, 0, 5,
                        0, 0, 0, 0,
                        0, 0, 0, 0,
                        'R', 'E', 'M', 'B',
                        1, 0, 0, 0,
                        0, 0, 0, 0
                    };
                    data[4] = (uint8)((our_ssrc >> 24) & 0xff);
                    data[5] = (uint8)((our_ssrc >> 16) & 0xff);
                    data[6] = (uint8)((our_ssrc >> 8) & 0xff);
                    data[7] = (uint8)(our_ssrc & 0xff);
                    uint8 br_exp = 0;
                    uint32 br_mant = target_receive_bitrate * 1000;
                    uint8 bits = (uint8)Math.log2(br_mant);
                    if (bits > 16) {
                        br_exp = (uint8)bits - 16;
                        br_mant = br_mant >> br_exp;
                    }
                    data[17] = (uint8)((br_exp << 2) | ((br_mant >> 16) & 0x3));
                    data[18] = (uint8)((br_mant >> 8) & 0xff);
                    data[19] = (uint8)(br_mant & 0xff);
                    data[20] = (uint8)((ssrc >> 24) & 0xff);
                    data[21] = (uint8)((ssrc >> 16) & 0xff);
                    data[22] = (uint8)((ssrc >> 8) & 0xff);
                    data[23] = (uint8)(ssrc & 0xff);
                    encrypt_and_send_rtcp(data);
                }
            }
        }
        return Source.CONTINUE;
    }

    private static void on_feedback_rtcp(Gst.Element session, uint type, uint fbtype, uint sender_ssrc, uint media_ssrc, Gst.Buffer? fci, Stream self) {
        if (self.input_device != null && self.media == "video" && type == 206 && fbtype == 15 && fci != null && sender_ssrc == self.participant_ssrc) {
            // https://tools.ietf.org/html/draft-alvestrand-rmcat-remb-03
            uint8[] data;
            fci.extract_dup(0, fci.get_size(), out data);
            if (data[0] != 'R' || data[1] != 'E' || data[2] != 'M' || data[3] != 'B') return;
            uint8 br_exp = data[5] >> 2;
            uint32 br_mant = (((uint32)data[5] & 0x3) << 16) + ((uint32)data[6] << 8) + (uint32)data[7];
            self.target_send_bitrate = (br_mant << br_exp) / 1000;
            self.input_device.update_bitrate(self.payload_type, self.target_send_bitrate);
        }
    }

    private void prepare_local_crypto() {
        if (local_crypto != null && local_crypto.is_valid && !crypto_session.has_encrypt) {
            crypto_session.set_encryption_key(local_crypto.crypto_suite, local_crypto.key, local_crypto.salt);
            debug("Setting up encryption with key params %s", local_crypto.key_params);
        }
    }

    private Gst.FlowReturn on_new_sample(Gst.App.Sink sink) {
        if (sink == null) {
            debug("Sink is null");
            return Gst.FlowReturn.EOS;
        }
        if (sink != send_rtp && sink != send_rtcp) {
            warning("unknown sample");
            return Gst.FlowReturn.NOT_SUPPORTED;
        }
        Gst.Sample sample = sink.pull_sample();
        Gst.Buffer buffer = sample.get_buffer();
        if (sink == send_rtp) {
            uint buffer_ssrc = 0, buffer_seq = 0;
            Gst.RTP.Buffer rtp_buffer;
            if (Gst.RTP.Buffer.map(buffer, Gst.MapFlags.READ, out rtp_buffer)) {
                buffer_ssrc = rtp_buffer.get_ssrc();
                buffer_seq = rtp_buffer.get_seq();
                next_seqnum_offset = rtp_buffer.get_seq() + 1;
                next_timestamp_offset_base = rtp_buffer.get_timestamp();
                next_timestamp_offset_stamp = get_monotonic_time();
                rtp_buffer.unmap();
            }
            if (our_ssrc != buffer_ssrc) {
                warning("Sending RTP %s buffer seq %u with SSRC %u when our ssrc is %u", media, buffer_seq, buffer_ssrc, our_ssrc);
            } else {
                debug("Sending RTP %s buffer seq %u with SSRC %u", media, buffer_seq, buffer_ssrc);
            }
        }

        prepare_local_crypto();

        uint8[] data;
        buffer.extract_dup(0, buffer.get_size(), out data);
        if (sink == send_rtp) {
            encrypt_and_send_rtp((owned) data);
        } else if (sink == send_rtcp) {
            encrypt_and_send_rtcp((owned) data);
        }
        return Gst.FlowReturn.OK;
    }

    private void encrypt_and_send_rtp(owned uint8[] data) {
        Bytes bytes;
        if (crypto_session.has_encrypt) {
            bytes = new Bytes.take(crypto_session.encrypt_rtp(data));
        } else {
            bytes = new Bytes.take(data);
        }
        on_send_rtp_data(bytes);
    }

    private void encrypt_and_send_rtcp(owned uint8[] data) {
        Bytes bytes;
        if (crypto_session.has_encrypt) {
            bytes = new Bytes.take(crypto_session.encrypt_rtcp(data));
        } else {
            bytes = new Bytes.take(data);
        }
        if (rtcp_mux) {
            on_send_rtp_data(bytes);
        } else {
            on_send_rtcp_data(bytes);
        }
    }

    private static Gst.PadProbeReturn drop_probe() {
        return Gst.PadProbeReturn.DROP;
    }

    private static void on_eos_static(Gst.App.Sink sink, Stream self) {
        debug("EOS on %s", sink.name);
        if (sink == self.send_rtp) {
            Idle.add(() => { self.on_send_rtp_eos(); return Source.REMOVE; });
        } else if (sink == self.send_rtcp) {
            Idle.add(() => { self.on_send_rtcp_eos(); return Source.REMOVE; });
        }
    }

    private void on_send_rtp_eos() {
        if (send_rtp_src_pad != null) {
            send_rtp_src_pad.unlink(send_rtp.get_static_pad("sink"));
            send_rtp_src_pad = null;
        }
        send_rtp.set_locked_state(true);
        send_rtp.set_state(Gst.State.NULL);
        pipe.remove(send_rtp);
        send_rtp = null;
        debug("Stopped sending RTP for %u", rtpid);
    }

    private void on_send_rtcp_eos() {
        send_rtcp.set_locked_state(true);
        send_rtcp.set_state(Gst.State.NULL);
        pipe.remove(send_rtcp);
        send_rtcp = null;
        debug("Stopped sending RTCP for %u", rtpid);
    }

    public override void destroy() {
        // Stop network communication
        push_recv_data = false;
        if (recv_rtp != null) recv_rtp.end_of_stream();
        if (recv_rtcp != null) recv_rtcp.end_of_stream();
        if (send_rtp != null) send_rtp.new_sample.disconnect(on_new_sample);
        if (send_rtcp != null) send_rtcp.new_sample.disconnect(on_new_sample);

        // Disconnect input device
        if (input != null) {
            input_pad.unlink(send_rtp_sink_pad);
            input.release_request_pad(input_pad);
            input_pad = null;
        }
        if (this._input_device != null) {
            if (!paused) this._input_device.unlink(input);
            this._input_device = null;
            this.input = null;
        }

        // Inject EOS
        if (send_rtp_sink_pad != null) {
            send_rtp_sink_pad.send_event(new Gst.Event.eos());
        }

        // Disconnect decode
        if (recv_rtp_src_pad != null) {
            recv_rtp_src_pad.add_probe(Gst.PadProbeType.BLOCK, drop_probe);
            recv_rtp_src_pad.unlink(decode.get_static_pad("sink"));
        }

        // Disconnect output
        if (output != null) {
            decode.get_static_pad("src").add_probe(Gst.PadProbeType.BLOCK, drop_probe);
            decode.unlink(output);
        }

        // Disconnect output device
        if (this._output_device != null) {
            this._output_device.unlink(output);
            this._output_device = null;
        }
        output = null;

        // Destroy decode
        if (decode != null) {
            decode.set_locked_state(true);
            decode.set_state(Gst.State.NULL);
            pipe.remove(decode);
            decode = null;
            decode_depay = null;
        }

        // Disconnect and remove RTP input
        if (recv_rtp != null) {
            recv_rtp.get_static_pad("src").unlink(recv_rtp_sink_pad);
            recv_rtp.set_locked_state(true);
            recv_rtp.set_state(Gst.State.NULL);
            pipe.remove(recv_rtp);
            recv_rtp = null;
        }

        // Disconnect and remove RTCP input
        if (recv_rtcp != null) {
            recv_rtcp.get_static_pad("src").unlink(recv_rtcp_sink_pad);
            recv_rtcp.set_locked_state(true);
            recv_rtcp.set_state(Gst.State.NULL);
            pipe.remove(recv_rtcp);
            recv_rtcp = null;
        }

        // Release rtp pads
        if (send_rtp_sink_pad != null) {
            rtpbin.release_request_pad(send_rtp_sink_pad);
            send_rtp_sink_pad = null;
        }
        if (recv_rtp_sink_pad != null) {
            rtpbin.release_request_pad(recv_rtp_sink_pad);
            recv_rtp_sink_pad = null;
        }
        if (send_rtcp_src_pad != null) {
            rtpbin.release_request_pad(send_rtcp_src_pad);
            send_rtcp_src_pad = null;
        }
        if (recv_rtcp_sink_pad != null) {
            rtpbin.release_request_pad(recv_rtcp_sink_pad);
            recv_rtcp_sink_pad = null;
        }
    }

    private void prepare_remote_crypto() {
        if (remote_crypto != null && remote_crypto.is_valid && !crypto_session.has_decrypt) {
            crypto_session.set_decryption_key(remote_crypto.crypto_suite, remote_crypto.key, remote_crypto.salt);
            debug("Setting up decryption with key params %s", remote_crypto.key_params);
        }
    }

    private uint16 previous_video_orientation_degree = uint16.MAX;
    public signal void video_orientation_changed(uint16 degree);

    public override void on_recv_rtp_data(Bytes bytes) {
        if (rtcp_mux && bytes.length >= 2 && bytes.get(1) >= 192 && bytes.get(1) < 224) {
            on_recv_rtcp_data(bytes);
            return;
        }
#if GST_1_16
        {
            Gst.Buffer buffer = new Gst.Buffer.wrapped_bytes(bytes);
            Gst.RTP.Buffer rtp_buffer;
            uint buffer_ssrc = 0, buffer_seq = 0;
            if (Gst.RTP.Buffer.map(buffer, Gst.MapFlags.READ, out rtp_buffer)) {
                buffer_ssrc = rtp_buffer.get_ssrc();
                buffer_seq = rtp_buffer.get_seq();
                rtp_buffer.unmap();
            }
            debug("Received RTP %s buffer seq %u with SSRC %u", media, buffer_seq, buffer_ssrc);
        }
#endif
        if (push_recv_data) {
            prepare_remote_crypto();

            Gst.Buffer buffer;
            if (crypto_session.has_decrypt) {
                try {
                    buffer = new Gst.Buffer.wrapped(crypto_session.decrypt_rtp(bytes.get_data()));
                } catch (Error e) {
                    warning("%s (%d)", e.message, e.code);
                    return;
                }
            } else {
#if GST_1_16
                buffer = new Gst.Buffer.wrapped_bytes(bytes);
#else
                buffer = new Gst.Buffer.wrapped(bytes.get_data());
#endif
            }

            Gst.RTP.Buffer rtp_buffer;
            if (Gst.RTP.Buffer.map(buffer, Gst.MapFlags.READ, out rtp_buffer)) {
                if (rtp_buffer.get_extension()) {
                    Xmpp.Xep.JingleRtp.HeaderExtension? ext = header_extensions.first_match((it) => it.uri == "urn:3gpp:video-orientation");
                    if (ext != null) {
                        unowned uint8[] extension_data;
                        if (rtp_buffer.get_extension_onebyte_header(ext.id, 0, out extension_data) && extension_data.length == 1) {
                            bool camera = (extension_data[0] & 0x8) > 0;
                            bool flip = (extension_data[0] & 0x4) > 0;
                            uint8 rotation = extension_data[0] & 0x3;
                            uint16 rotation_degree = uint16.MAX;
                            switch(rotation) {
                                case 0: rotation_degree = 0; break;
                                case 1: rotation_degree = 90; break;
                                case 2: rotation_degree = 180; break;
                                case 3: rotation_degree = 270; break;
                            }
                            if (rotation_degree != previous_video_orientation_degree) {
                                video_orientation_changed(rotation_degree);
                                previous_video_orientation_degree = rotation_degree;
                            }
                        }
                    }
                }
                rtp_buffer.unmap();
            }

#if VALA_0_50
            recv_rtp.push_buffer((owned) buffer);
#else
            Gst.FlowReturn ret;
            GLib.Signal.emit_by_name(recv_rtp, "push-buffer", buffer, out ret);
#endif
        }
    }

    public override void on_recv_rtcp_data(Bytes bytes) {
        if (push_recv_data) {
            prepare_remote_crypto();

            Gst.Buffer buffer;
            if (crypto_session.has_decrypt) {
                try {
                    buffer = new Gst.Buffer.wrapped(crypto_session.decrypt_rtcp(bytes.get_data()));
                } catch (Error e) {
                    warning("%s (%d)", e.message, e.code);
                    return;
                }
            } else {
#if GST_1_16
                buffer = new Gst.Buffer.wrapped_bytes(bytes);
#else
                buffer = new Gst.Buffer.wrapped(bytes.get_data());
#endif
            }

#if VALA_0_50
            recv_rtcp.push_buffer((owned) buffer);
#else
            Gst.FlowReturn ret;
            GLib.Signal.emit_by_name(recv_rtcp, "push-buffer", buffer, out ret);
#endif
        }
    }

    public override void on_rtp_ready() {
        // If full frame has been sent before the connection was ready, the counterpart would only display our video after the next full frame.
        // Send a full frame to let the counterpart display our video asap
        rtpbin.send_event(new Gst.Event.custom(
                Gst.EventType.CUSTOM_UPSTREAM,
                new Gst.Structure("GstForceKeyUnit", "all-headers", typeof(bool), true, null))
        );
    }

    public override void on_rtcp_ready() {
        int rtp_session_id = (int) rtpid;
        uint64 max_delay = int.MAX;
        Object rtp_session;
        bool rtp_sent;
        GLib.Signal.emit_by_name(rtpbin, "get-internal-session", rtp_session_id, out rtp_session);
        GLib.Signal.emit_by_name(rtp_session, "send-rtcp-full", max_delay, out rtp_sent);
        debug("RTCP is ready, resending rtcp: %s", rtp_sent.to_string());
    }

    public void on_ssrc_pad_added(uint32 ssrc, Gst.Pad pad) {
        debug("New ssrc %u with pad %s", ssrc, pad.name);
        if (participant_ssrc != 0 && participant_ssrc != ssrc) {
            warning("Got second ssrc on stream (old: %u, new: %u), ignoring", participant_ssrc, ssrc);
            return;
        }
        participant_ssrc = ssrc;
        recv_rtp_src_pad = pad;
        if (decode != null) {
            plugin.pause();
            debug("Link %s to %s decode for %s", recv_rtp_src_pad.name, media, name);
            recv_rtp_src_pad.link(decode.get_static_pad("sink"));
            plugin.unpause();
        }
    }

    public void on_send_rtp_src_added(Gst.Pad pad) {
        send_rtp_src_pad = pad;
        if (send_rtp != null) {
            plugin.pause();
            debug("Link %s to %s send_rtp for %s", send_rtp_src_pad.name, media, name);
            send_rtp_src_pad.link(send_rtp.get_static_pad("sink"));
            plugin.unpause();
        }
    }

    public void set_input(Gst.Element? input) {
        set_input_and_pause(input, paused);
    }

    private void set_input_and_pause(Gst.Element? input, bool paused) {
        if (created && this.input != null) {
            this.input_pad.unlink(send_rtp_sink_pad);
            this.input.release_request_pad(this.input_pad);
            this.input_pad = null;
            this.input = null;
        }

        this.input = input;
        this.paused = paused;

        if (created && sending && !paused && input != null) {
            plugin.pause();
            input_pad = input.get_request_pad(@"src_$rtpid");
            input_pad.link(send_rtp_sink_pad);
            plugin.unpause();
        }
    }

    public void pause() {
        if (paused) return;
        var input = this.input;
        set_input_and_pause(null, true);
        if (input != null && input_device != null) input_device.unlink(input);
    }

    public void unpause() {
        if (!paused) return;
        set_input_and_pause(input_device != null ? input_device.link_source(payload_type, our_ssrc, next_seqnum_offset, next_timestamp_offset) : null, false);
        input_device.update_bitrate(payload_type, target_send_bitrate);
    }

    public uint get_participant_ssrc(Xmpp.Jid participant) {
        if (participant.equals(content.session.peer_full_jid)) {
            return participant_ssrc;
        }
        return 0;
    }

    ulong block_probe_handler_id = 0;
    public virtual void add_output(Gst.Element element, Xmpp.Jid? participant = null) {
        if (output != null) {
            critical("add_output() invoked more than once");
            return;
        }
        if (participant != null) {
            critical("add_output() invoked with participant when not supported");
            return;
        }
        this.output = element;
        if (created) {
            plugin.pause();
            decode.link(element);
            if (block_probe_handler_id != 0) {
                decode.get_static_pad("src").remove_probe(block_probe_handler_id);
            }
            plugin.unpause();
        }
    }

    public virtual void remove_output(Gst.Element element) {
        if (output != element) {
            critical("remove_output() invoked without prior add_output()");
            return;
        }
        if (created) {
            block_probe_handler_id = decode.get_static_pad("src").add_probe(Gst.PadProbeType.BLOCK, drop_probe);
            decode.unlink(element);
        }
        if (this._output_device != null) {
            this._output_device.unlink(element);
            this._output_device = null;
        }
        this.output = null;
    }
}

public class Dino.Plugins.Rtp.VideoStream : Stream {
    private Gee.List<Gst.Element> outputs = new ArrayList<Gst.Element>();
    private Gst.Element output_tee;
    private Gst.Element rotate;
    private ulong video_orientation_changed_handler;

    public VideoStream(Plugin plugin, Xmpp.Xep.Jingle.Content content) {
        base(plugin, content);
        if (media != "video") critical("VideoStream created for non-video media");
    }

    public override void create() {
        video_orientation_changed_handler = video_orientation_changed.connect(on_video_orientation_changed);
        plugin.pause();
        rotate = Gst.ElementFactory.make("videoflip", @"video_rotate_$rtpid");
        pipe.add(rotate);
        output_tee = Gst.ElementFactory.make("tee", @"video_tee_$rtpid");
        output_tee.@set("allow-not-linked", true);
        pipe.add(output_tee);
        rotate.link(output_tee);
        add_output(rotate);
        base.create();
        foreach (Gst.Element output in outputs) {
            output_tee.link(output);
        }
        plugin.unpause();
    }

    private void on_video_orientation_changed(uint16 degree) {
        if (rotate != null) {
            switch (degree) {
                case 0:
                    rotate.@set("method", 0);
                    break;
                case 90:
                    rotate.@set("method", 1);
                    break;
                case 180:
                    rotate.@set("method", 2);
                    break;
                case 270:
                    rotate.@set("method", 3);
                    break;
            }
        }
    }

    public override void destroy() {
        foreach (Gst.Element output in outputs) {
            output_tee.unlink(output);
        }
        base.destroy();
        rotate.set_locked_state(true);
        rotate.set_state(Gst.State.NULL);
        rotate.unlink(output_tee);
        pipe.remove(rotate);
        rotate = null;
        output_tee.set_locked_state(true);
        output_tee.set_state(Gst.State.NULL);
        pipe.remove(output_tee);
        output_tee = null;
        disconnect(video_orientation_changed_handler);
    }

    public override void add_output(Gst.Element element, Xmpp.Jid? participant) {
        if (element == output_tee || element == rotate) {
            base.add_output(element);
            return;
        }
        outputs.add(element);
        if (output_tee != null) {
            output_tee.link(element);
        }
    }

    public override void remove_output(Gst.Element element) {
        if (element == output_tee || element == rotate) {
            base.remove_output(element);
            return;
        }
        outputs.remove(element);
        if (output_tee != null) {
            output_tee.unlink(element);
        }
    }
}
