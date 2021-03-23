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
    private Gst.Element encode;
    private Gst.Element decode;
    private Gst.Element input;
    private Gst.Element output;

    private Device _input_device;
    public Device input_device { get { return _input_device; } set {
        if (!paused) {
            if (this._input_device != null) {
                this._input_device.unlink();
                this._input_device = null;
            }
            set_input(value != null ? value.link_source() : null);
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
    private string participant_ssrc = null;

    private Gst.Pad recv_rtcp_sink_pad;
    private Gst.Pad recv_rtp_sink_pad;
    private Gst.Pad recv_rtp_src_pad;
    private Gst.Pad send_rtcp_src_pad;
    private Gst.Pad send_rtp_sink_pad;
    private Gst.Pad send_rtp_src_pad;

    private SrtpSession? local_crypto_session;
    private SrtpSession? remote_crypto_session;

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
        send_rtp = Gst.ElementFactory.make("appsink", @"rtp-sink-$rtpid") as Gst.App.Sink;
        send_rtp.async = false;
        send_rtp.caps = CodecUtil.get_caps(media, payload_type);
        send_rtp.emit_signals = true;
        send_rtp.sync = false;
        send_rtp.new_sample.connect(on_new_sample);
        pipe.add(send_rtp);

        send_rtcp = Gst.ElementFactory.make("appsink", @"rtcp-sink-$rtpid") as Gst.App.Sink;
        send_rtcp.async = false;
        send_rtcp.caps = new Gst.Caps.empty_simple("application/x-rtcp");
        send_rtcp.emit_signals = true;
        send_rtcp.sync = false;
        send_rtcp.new_sample.connect(on_new_sample);
        pipe.add(send_rtcp);

        recv_rtp = Gst.ElementFactory.make("appsrc", @"rtp-src-$rtpid") as Gst.App.Src;
        recv_rtp.caps = CodecUtil.get_caps(media, payload_type);
        recv_rtp.do_timestamp = true;
        recv_rtp.format = Gst.Format.TIME;
        recv_rtp.is_live = true;
        pipe.add(recv_rtp);

        recv_rtcp = Gst.ElementFactory.make("appsrc", @"rtcp-src-$rtpid") as Gst.App.Src;
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
        encode = codec_util.get_encode_bin(media, payload_type, @"encode-$rtpid");
        pipe.add(encode);
        send_rtp_sink_pad = rtpbin.get_request_pad(@"send_rtp_sink_$rtpid");
        encode.get_static_pad("src").link(send_rtp_sink_pad);
        if (input != null) {
            input.link(encode);
        }

        // Connect output
        decode = codec_util.get_decode_bin(media, payload_type, @"decode-$rtpid");
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
    }

    private void prepare_local_crypto() {
        if (local_crypto != null && local_crypto_session == null) {
            local_crypto_session = new SrtpSession(
                    local_crypto.crypto_suite == Xep.JingleRtp.Crypto.F8_128_HMAC_SHA1_80 ? SrtpEncryption.AES_F8 : SrtpEncryption.AES_CM,
                    SrtpAuthentication.HMAC_SHA1,
                    local_crypto.crypto_suite == Xep.JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_32 ? 4 : 10,
                    SrtpPrf.AES_CM,
                    0
            );
            local_crypto_session.setkey(local_crypto.key, local_crypto.salt);
            debug("Setting up encryption with key params %s", local_crypto.key_params);
        }
    }

    private Gst.FlowReturn on_new_sample(Gst.App.Sink sink) {
        if (sink == null) {
            debug("Sink is null");
            return Gst.FlowReturn.EOS;
        }
        Gst.Sample sample = sink.pull_sample();
        Gst.Buffer buffer = sample.get_buffer();
        uint8[] data;
        buffer.extract_dup(0, buffer.get_size(), out data);
        prepare_local_crypto();
        if (sink == send_rtp) {
            if (local_crypto_session != null) {
                data = local_crypto_session.encrypt_rtp(data, local_crypto.crypto_suite == Xep.JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_32 ? 4 : 10);
            }
            on_send_rtp_data(new Bytes.take(data));
        } else if (sink == send_rtcp) {
            if (local_crypto_session != null) {
                data = local_crypto_session.encrypt_rtcp(data, local_crypto.crypto_suite == Xep.JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_32 ? 4 : 10);
            }
            on_send_rtcp_data(new Bytes.take(data));
        } else {
            warning("unknown sample");
        }
        return Gst.FlowReturn.OK;
    }

    private static Gst.PadProbeReturn drop_probe() {
        return Gst.PadProbeReturn.DROP;
    }

    public override void destroy() {
        // Stop network communication
        push_recv_data = false;
        recv_rtp.end_of_stream();
        recv_rtcp.end_of_stream();
        send_rtp.new_sample.disconnect(on_new_sample);
        send_rtcp.new_sample.disconnect(on_new_sample);

        // Disconnect input device
        if (input != null) {
            input.unlink(encode);
            input = null;
        }
        if (this._input_device != null) {
            if (!paused) this._input_device.unlink();
            this._input_device = null;
        }

        // Disconnect encode
        encode.set_locked_state(true);
        encode.set_state(Gst.State.NULL);
        encode.get_static_pad("src").unlink(send_rtp_sink_pad);
        pipe.remove(encode);
        encode = null;

        // Disconnect RTP sending
        if (send_rtp_src_pad != null) {
            send_rtp_src_pad.add_probe(Gst.PadProbeType.BLOCK, drop_probe);
            send_rtp_src_pad.unlink(send_rtp.get_static_pad("sink"));
        }
        send_rtp.set_locked_state(true);
        send_rtp.set_state(Gst.State.NULL);
        pipe.remove(send_rtp);
        send_rtp = null;

        // Disconnect decode
        if (recv_rtp_src_pad != null) {
            recv_rtp_src_pad.add_probe(Gst.PadProbeType.BLOCK, drop_probe);
            recv_rtp_src_pad.unlink(decode.get_static_pad("sink"));
        }

        // Disconnect RTP receiving
        recv_rtp.set_locked_state(true);
        recv_rtp.set_state(Gst.State.NULL);
        recv_rtp.get_static_pad("src").unlink(recv_rtp_sink_pad);
        pipe.remove(recv_rtp);
        recv_rtp = null;

        // Disconnect output
        if (output != null) {
            decode.unlink(output);
        }
        decode.set_locked_state(true);
        decode.set_state(Gst.State.NULL);
        pipe.remove(decode);
        decode = null;
        output = null;

        // Disconnect output device
        if (this._output_device != null) {
            this._output_device.unlink();
            this._output_device = null;
        }

        // Disconnect RTCP receiving
        recv_rtcp.get_static_pad("src").unlink(recv_rtcp_sink_pad);
        recv_rtcp.set_locked_state(true);
        recv_rtcp.set_state(Gst.State.NULL);
        pipe.remove(recv_rtcp);
        recv_rtcp = null;

        // Disconnect RTCP sending
        send_rtcp_src_pad.unlink(send_rtcp.get_static_pad("sink"));
        send_rtcp.set_locked_state(true);
        send_rtcp.set_state(Gst.State.NULL);
        pipe.remove(send_rtcp);
        send_rtcp = null;

        // Release rtp pads
        rtpbin.release_request_pad(send_rtp_sink_pad);
        send_rtp_sink_pad = null;
        rtpbin.release_request_pad(recv_rtp_sink_pad);
        recv_rtp_sink_pad = null;
        rtpbin.release_request_pad(recv_rtcp_sink_pad);
        recv_rtcp_sink_pad = null;
        rtpbin.release_request_pad(send_rtcp_src_pad);
        send_rtcp_src_pad = null;
        send_rtp_src_pad = null;
        recv_rtp_src_pad = null;
    }

    private void prepare_remote_crypto() {
        if (remote_crypto != null && remote_crypto_session == null) {
            remote_crypto_session = new SrtpSession(
                    remote_crypto.crypto_suite == Xep.JingleRtp.Crypto.F8_128_HMAC_SHA1_80 ? SrtpEncryption.AES_F8 : SrtpEncryption.AES_CM,
                    SrtpAuthentication.HMAC_SHA1,
                    remote_crypto.crypto_suite == Xep.JingleRtp.Crypto.AES_CM_128_HMAC_SHA1_32 ? 4 : 10,
                    SrtpPrf.AES_CM,
                    0
            );
            remote_crypto_session.setkey(remote_crypto.key, remote_crypto.salt);
            debug("Setting up decryption with key params %s", remote_crypto.key_params);
        }
    }

    public override void on_recv_rtp_data(Bytes bytes) {
        prepare_remote_crypto();
        uint8[] data = bytes.get_data();
        if (remote_crypto_session != null) {
            try {
                data = remote_crypto_session.decrypt_rtp(data);
            } catch (Error e) {
                warning("%s (%d)", e.message, e.code);
            }
        }
        if (push_recv_data) {
            recv_rtp.push_buffer(new Gst.Buffer.wrapped((owned) data));
        }
    }

    public override void on_recv_rtcp_data(Bytes bytes) {
        prepare_remote_crypto();
        uint8[] data = bytes.get_data();
        if (remote_crypto_session != null) {
            try {
                data = remote_crypto_session.decrypt_rtcp(data);
            } catch (Error e) {
                warning("%s (%d)", e.message, e.code);
            }
        }
        if (push_recv_data) {
            recv_rtcp.push_buffer(new Gst.Buffer.wrapped((owned) data));
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

    public void on_ssrc_pad_added(string ssrc, Gst.Pad pad) {
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
            this.input.unlink(encode);
            this.input = null;
        }

        this.input = input;
        this.paused = paused;

        if (created && sending && !paused && input != null) {
            plugin.pause();
            input.link(encode);
            plugin.unpause();
        }
    }

    public void pause() {
        if (paused) return;
        set_input_and_pause(null, true);
        if (input_device != null) input_device.unlink();
    }

    public void unpause() {
        if (!paused) return;
        set_input_and_pause(input_device != null ? input_device.link_source() : null, false);
    }

    ulong block_probe_handler_id = 0;
    public virtual void add_output(Gst.Element element) {
        if (output != null) {
            critical("add_output() invoked more than once");
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
            this._output_device.unlink();
            this._output_device = null;
        }
        this.output = null;
    }
}

public class Dino.Plugins.Rtp.VideoStream : Stream {
    private Gee.List<Gst.Element> outputs = new ArrayList<Gst.Element>();
    private Gst.Element output_tee;

    public VideoStream(Plugin plugin, Xmpp.Xep.Jingle.Content content) {
        base(plugin, content);
        if (media != "video") critical("VideoStream created for non-video media");
    }

    public override void create() {
        plugin.pause();
        output_tee = Gst.ElementFactory.make("tee", null);
        output_tee.@set("allow-not-linked", true);
        pipe.add(output_tee);
        add_output(output_tee);
        base.create();
        foreach (Gst.Element output in outputs) {
            output_tee.link(output);
        }
        plugin.unpause();
    }

    public override void destroy() {
        foreach (Gst.Element output in outputs) {
            output_tee.unlink(output);
        }
        base.destroy();
        output_tee.set_locked_state(true);
        output_tee.set_state(Gst.State.NULL);
        pipe.remove(output_tee);
        output_tee = null;
    }

    public override void add_output(Gst.Element element) {
        if (element == output_tee) {
            base.add_output(element);
            return;
        }
        outputs.add(element);
        if (output_tee != null) {
            output_tee.link(element);
        }
    }

    public override void remove_output(Gst.Element element) {
        if (element == output_tee) {
            base.remove_output(element);
            return;
        }
        outputs.remove(element);
        if (output_tee != null) {
            output_tee.unlink(element);
        }
    }
}