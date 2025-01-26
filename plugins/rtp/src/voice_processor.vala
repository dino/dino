using Gst;

namespace Dino.Plugins.Rtp {
public static extern Buffer adjust_to_running_time(Base.Transform transform, Buffer buf);
}

public class Dino.Plugins.Rtp.EchoProbe : Audio.Filter {
    private static StaticPadTemplate sink_template = {"sink", PadDirection.SINK, PadPresence.ALWAYS, {null, "audio/x-raw,rate=48000,channels=1,layout=interleaved,format=S16LE"}};
    private static StaticPadTemplate src_template = {"src", PadDirection.SRC, PadPresence.ALWAYS, {null, "audio/x-raw,rate=48000,channels=1,layout=interleaved,format=S16LE"}};
    public Audio.Info audio_info { get; private set; }
    public signal void on_new_buffer(owned Buffer buffer);
    public signal void on_new_delay(int delay);
    private uint period_samples;
    private uint period_size;
    public int delay { get; private set; }
    private Base.Adapter adapter = new Base.Adapter();

    static construct {
        add_static_pad_template(sink_template);
        add_static_pad_template(src_template);
        set_static_metadata("Acoustic Echo Canceller probe", "Generic/Audio", "Gathers playback buffers for echo cancellation", "Dino Team <contact@dino.im>");
    }

    construct {
        set_passthrough(true);
    }

    public override bool setup(Audio.Info info) {
        audio_info = info;
        period_samples = info.rate / 100; // 10ms buffers
        period_size = period_samples * info.bpf;
        return true;
    }

    public override bool src_event(owned Event event) {
        Query query = new Query.latency();
        if (event.type == EventType.LATENCY && srcpad != null && srcpad.query(query)) {
            ClockTime upstream_latency;
            query.parse_latency(null, out upstream_latency, null);
            int delay = this.delay;
            if (upstream_latency != CLOCK_TIME_NONE) {
                delay = (int) (upstream_latency / MSECOND);
            } else {
                delay = 0;
            }
            if (delay != this.delay) {
                debug("Delay adjusted from %ms to %dms", this.delay, delay);
                this.delay = delay;
                on_new_delay(delay);
            }
        }
        return base.src_event((owned) event);
    }

    public override FlowReturn transform_ip(Buffer buf) {
        lock (adapter) {
            adapter.push(adjust_to_running_time(this, buf));
            while (adapter.available() > period_size) {
                on_new_buffer(adapter.take_buffer(period_size));
            }
        }
        return FlowReturn.OK;
    }

    public override bool stop() {
        adapter.clear();
        return true;
    }
}

public class Dino.Plugins.Rtp.VoiceProcessor : Audio.Filter {
    private static StaticPadTemplate sink_template = {"sink", PadDirection.SINK, PadPresence.ALWAYS, {null, "audio/x-raw,rate=48000,channels=1,layout=interleaved,format=S16LE"}};
    private static StaticPadTemplate src_template = {"src", PadDirection.SRC, PadPresence.ALWAYS, {null, "audio/x-raw,rate=48000,channels=1,layout=interleaved,format=S16LE"}};
    public Audio.Info audio_info { get; private set; }
    private ulong process_outgoing_buffer_handler_id;
    private ulong process_stream_delay_handler_id;
    private uint adjust_delay_timeout_id;
    private uint period_samples;
    private uint period_size;
    private Base.Adapter adapter = new Base.Adapter();
    private EchoProbe? echo_probe;
    private Audio.StreamVolume? stream_volume;
    private ClockTime last_reverse;
    private void* native;

    static construct {
        add_static_pad_template(sink_template);
        add_static_pad_template(src_template);
        set_static_metadata("Voice Processor (AGC, AEC, filters, etc.)", "Generic/Audio", "Pre-processes voice with WebRTC Audio Processing Library", "Dino Team <contact@dino.im>");
    }

    construct {
        set_passthrough(false);
    }

    public VoiceProcessor(EchoProbe? echo_probe = null, Audio.StreamVolume? stream_volume = null) {
        this.echo_probe = echo_probe;
        this.stream_volume = stream_volume;
    }

    private static extern void* init_native(int stream_delay);
    private static extern void setup_native(void* native);
    private static extern void destroy_native(void* native);
    private static extern void analyze_reverse_stream(void* native, Audio.Info info, Buffer buffer);
    private static extern void process_stream(void* native, Audio.Info info, Buffer buffer);
    private static extern void adjust_stream_delay(void* native);
    private static extern void set_stream_delay(void* native, int delay);
    private static extern void notify_gain_level(void* native, int gain_level);
    private static extern int get_suggested_gain_level(void* native);
    private static extern bool get_stream_has_voice(void* native);

    public override bool setup(Audio.Info info) {
        debug("VoiceProcessor.setup(%s)", info.to_caps().to_string());
        audio_info = info;
        period_samples = info.rate / 100; // 10ms buffers
        period_size = period_samples * info.bpf;
        adapter.clear();
        setup_native(native);
        return true;
    }

    public override bool start() {
        native = init_native(echo_probe.delay);
        if (process_outgoing_buffer_handler_id == 0 && echo_probe != null) {
            process_outgoing_buffer_handler_id = echo_probe.on_new_buffer.connect(process_outgoing_buffer);
        }
        if (process_stream_delay_handler_id == 0 && echo_probe != null) {
            process_stream_delay_handler_id = echo_probe.on_new_delay.connect(process_stream_delay);
        }
        if (stream_volume == null && sinkpad.get_peer() != null && sinkpad.get_peer().get_parent_element() is Audio.StreamVolume) {
            stream_volume = sinkpad.get_peer().get_parent_element() as Audio.StreamVolume;
        }
        return true;
    }

    private bool adjust_delay() {
        if (native != null) {
            adjust_stream_delay(native);
            return Source.CONTINUE;
        } else {
            adjust_delay_timeout_id = 0;
            return Source.REMOVE;
        }
    }

    private void process_outgoing_buffer(owned Buffer buffer) {
        if (buffer.pts != uint64.MAX) {
            last_reverse = buffer.pts;
        }
        if (native != null) {
            buffer = (Buffer) buffer.make_writable();
            analyze_reverse_stream(native, echo_probe.audio_info, buffer);
        }
        if (adjust_delay_timeout_id == 0 && echo_probe != null) {
            adjust_delay_timeout_id = Timeout.add(1000, adjust_delay);
        }
    }

    private void process_stream_delay(int stream_delay) {
        if (native != null) {
            set_stream_delay(native, stream_delay);
        }
    }

    public override FlowReturn submit_input_buffer(bool is_discont, Buffer input) {
        lock (adapter) {
            if (is_discont) {
                adapter.clear();
            }
            adapter.push(adjust_to_running_time(this, input));
        }
        return FlowReturn.OK;
    }

    public override FlowReturn generate_output(out Buffer output_buffer) {
        lock (adapter) {
            if (adapter.available() >= period_size) {
                output_buffer = (Gst.Buffer) adapter.take_buffer(period_size).make_writable();
                int old_gain_level = 0;
                if (stream_volume != null) {
                    old_gain_level = (int) (stream_volume.get_volume(Audio.StreamVolumeFormat.LINEAR) * 255.0);
                    notify_gain_level(native, old_gain_level);
                }
                process_stream(native, audio_info, output_buffer);
                if (stream_volume != null) {
                    int new_gain_level = get_suggested_gain_level(native);
                    if (old_gain_level != new_gain_level) {
                        debug("Gain: %i -> %i", old_gain_level, new_gain_level);
                        stream_volume.set_volume(Audio.StreamVolumeFormat.LINEAR, ((double)new_gain_level) / 255.0);
                    }
                }
            }
        }
        return FlowReturn.OK;
    }

    public override bool stop() {
        if (process_outgoing_buffer_handler_id != 0) {
            echo_probe.disconnect(process_outgoing_buffer_handler_id);
            process_outgoing_buffer_handler_id = 0;
        }
        if (adjust_delay_timeout_id != 0) {
            Source.remove(adjust_delay_timeout_id);
            adjust_delay_timeout_id = 0;
        }
        adapter.clear();
        destroy_native(native);
        native = null;
        return true;
    }
}