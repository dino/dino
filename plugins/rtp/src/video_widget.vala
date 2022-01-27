#if !VALA_0_52
[CCode (cheader_filename = "gst/gst.h")]
private static extern void gst_value_set_fraction(ref GLib.Value value, int numerator, int denominator);
#endif

public class Dino.Plugins.Rtp.VideoWidget : Gtk.Bin, Dino.Plugins.VideoCallWidget {
    private static uint last_id = 0;

    public uint id { get; private set; }
    public Gst.Base.Sink sink { get; private set; }
    public Gtk.Widget widget { get; private set; }

    public Plugin plugin { get; private set; }
    public Gst.Pipeline pipe { get {
        return plugin.pipe;
    }}

    private bool attached;
    private Device? connected_device;
    private Gst.Element? connected_device_element;
    private Stream? connected_stream;
    private Gst.Element prepare;
    private Gst.Caps last_input_caps;
    private Gst.Caps last_caps;

    public VideoWidget(Plugin plugin) {
        this.plugin = plugin;

        id = last_id++;
        sink = Gst.ElementFactory.make("gtksink", @"video_widget_$id") as Gst.Base.Sink;
        if (sink != null) {
            Gtk.Widget widget;
            sink.@get("widget", out widget);
            sink.@set("async", false);
            sink.@set("sync", true);
            sink.@set("ignore-alpha", false);
            this.widget = widget;
            this.widget.draw.connect(fix_caps_issues);
            add(widget);
            widget.visible = true;
        } else {
            warning("Could not create GTK video sink. Won't display videos.");
        }
        size_allocate.connect_after(after_size_allocate);
    }

    public void input_caps_changed(GLib.Object pad, ParamSpec spec) {
        Gst.Caps? caps = ((Gst.Pad)pad).caps;
        if (caps == null) {
            warning("Input: No caps");
            return;
        }

        int width, height;
        caps.get_structure(0).get_int("width", out width);
        caps.get_structure(0).get_int("height", out height);
        debug("Input resolution changed: %ix%i", width, height);
        resolution_changed(width, height);
        last_input_caps = caps;
    }

    public void processed_input_caps_changed(GLib.Object pad, ParamSpec spec) {
        Gst.Caps? caps = (pad as Gst.Pad).caps;
        if (caps == null) {
            warning("Processed input: No caps");
            return;
        }

        int width, height;
        caps.get_structure(0).get_int("width", out width);
        caps.get_structure(0).get_int("height", out height);
        debug("Processed resolution changed: %ix%i", width, height);
        sink.set_caps(caps);
        last_caps = caps;
    }

    public void after_size_allocate(Gtk.Allocation allocation) {
        if (prepare != null) {
            Gst.Element crop = ((Gst.Bin)prepare).get_by_name(@"video_widget_$(id)_crop");
            if (crop != null) {
                int output_width = allocation.width;
                int output_height = allocation.height;
                int target_num, target_den;
                if (last_input_caps != null) {
                    int input_width, input_height;
                    last_input_caps.get_structure(0).get_int("width", out input_width);
                    last_input_caps.get_structure(0).get_int("height", out input_height);
                    double target_ratio = 3.0/2.0;
                    double ratio = (double)(output_width*input_height)/(double)(input_width*output_height);
                    if (ratio > target_ratio) {
                        target_num = (int)((double)input_width * target_ratio);
                        target_den = input_height;
                        sink.@set("force-aspect-ratio", true);
                    } else if (ratio < 1.0/target_ratio) {
                        target_num = input_width;
                        target_den = (int)((double)input_height * target_ratio);;
                        sink.@set("force-aspect-ratio", true);
                    } else {
                        target_num = output_width;
                        target_den = output_height;
                        sink.@set("force-aspect-ratio", false);
                    }
                } else {
                    target_num = output_width;
                    target_den = output_height;
                    sink.@set("force-aspect-ratio", false);
                }
                Value ratio = Value(typeof(Gst.Fraction));
#if VALA_0_52
                Gst.Value.set_fraction(ref ratio, target_num, target_den);
#else
                gst_value_set_fraction(ref ratio, target_num, target_den);
#endif
                crop.set_property("aspect-ratio", ratio);
            }
        }
    }

    public bool fix_caps_issues() {
        // FIXME: Detect if draw would fail and do something better
        if (last_caps != null) {
            Gst.Caps? temp = last_caps.copy();
            temp.set_simple("width", typeof(int), 1, "height", typeof(int), 1, null);
            sink.set_caps(temp);
            sink.set_caps(last_caps);
        }
        return false;
    }

    public void display_stream(Xmpp.Xep.JingleRtp.Stream stream, Xmpp.Jid jid) {
        if (sink == null) return;
        detach();
        if (stream.media != "video") return;
        connected_stream = stream as Stream;
        if (connected_stream == null) return;
        plugin.pause();
        pipe.add(sink);
        prepare = Gst.parse_bin_from_description(@"aspectratiocrop aspect-ratio=4/3 name=video_widget_$(id)_crop ! videoconvert name=video_widget_$(id)_convert", true);
        prepare.name = @"video_widget_$(id)_prepare";
        prepare.get_static_pad("sink").notify["caps"].connect(input_caps_changed);
        prepare.get_static_pad("src").notify["caps"].connect(processed_input_caps_changed);
        pipe.add(prepare);
        connected_stream.add_output(prepare);
        prepare.link(sink);
        sink.set_locked_state(false);
        plugin.unpause();
        attached = true;
    }

    public void display_device(MediaDevice media_device) {
        if (sink == null) return;
        detach();
        connected_device = media_device as Device;
        if (connected_device == null) return;
        plugin.pause();
        pipe.add(sink);
        prepare = Gst.parse_bin_from_description(@"aspectratiocrop aspect-ratio=4/3 name=video_widget_$(id)_crop ! videoflip method=horizontal-flip name=video_widget_$(id)_flip ! videoconvert name=video_widget_$(id)_convert", true);
        prepare.name = @"video_widget_$(id)_prepare";
        prepare.get_static_pad("sink").notify["caps"].connect(input_caps_changed);
        pipe.add(prepare);
        connected_device_element = connected_device.link_source();
        connected_device_element.link(prepare);
        prepare.link(sink);
        sink.set_locked_state(false);
        plugin.unpause();
        attached = true;
    }

    public void detach() {
        if (sink == null) return;
        if (attached) {
            if (connected_stream != null) {
                connected_stream.remove_output(prepare);
                connected_stream = null;
            }
            if (connected_device != null) {
                connected_device_element.unlink(sink);
                connected_device_element = null;
                connected_device.unlink();
                connected_device = null;
            }
            prepare.set_locked_state(true);
            prepare.set_state(Gst.State.NULL);
            pipe.remove(prepare);
            prepare = null;
            sink.set_locked_state(true);
            sink.set_state(Gst.State.NULL);
            pipe.remove(sink);
            attached = false;
        }
    }

    public override void dispose() {
        detach();
        widget = null;
        sink = null;
    }
}
