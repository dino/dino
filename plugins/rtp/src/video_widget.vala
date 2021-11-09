public class Dino.Plugins.Rtp.VideoWidget : Gtk.Bin, Dino.Plugins.VideoCallWidget {
    private static uint last_id = 0;

    public uint id { get; private set; }
    public Gst.Element element { get; private set; }
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

    public VideoWidget(Plugin plugin) {
        this.plugin = plugin;

        id = last_id++;
        element = Gst.ElementFactory.make("gtksink", @"video_widget_$id");
        if (element != null) {
            Gtk.Widget widget;
            element.@get("widget", out widget);
            element.@set("async", false);
            element.@set("sync", false);
            this.widget = widget;
            add(widget);
            widget.visible = true;
        } else {
            warning("Could not create GTK video sink. Won't display videos.");
        }
        size_allocate.connect_after(after_size_allocate);
    }

    public void input_caps_changed(GLib.Object pad, ParamSpec spec) {
        Gst.Caps? caps = (pad as Gst.Pad).caps;
        if (caps == null) return;

        int width, height;
        caps.get_structure(0).get_int("width", out width);
        caps.get_structure(0).get_int("height", out height);
        resolution_changed(width, height);
    }

    public void after_size_allocate(Gtk.Allocation allocation) {
        if (prepare != null) {
            Gst.Element crop = ((Gst.Bin)prepare).get_by_name(@"video_widget_$(id)_crop");
            if (crop != null) {
                Value ratio = new Value(typeof(Gst.Fraction));
                Gst.Value.set_fraction(ref ratio, allocation.width, allocation.height);
                crop.set_property("aspect-ratio", ratio);
            }
        }
    }

    public void display_stream(Xmpp.Xep.JingleRtp.Stream stream, Xmpp.Jid jid) {
        if (element == null) return;
        detach();
        if (stream.media != "video") return;
        connected_stream = stream as Stream;
        if (connected_stream == null) return;
        plugin.pause();
        pipe.add(element);
        prepare = Gst.parse_bin_from_description(@"aspectratiocrop aspect-ratio=4/3 name=video_widget_$(id)_crop ! videoconvert name=video_widget_$(id)_convert", true);
        prepare.name = @"video_widget_$(id)_prepare";
        prepare.get_static_pad("sink").notify["caps"].connect(input_caps_changed);
        pipe.add(prepare);
        connected_stream.add_output(prepare);
        prepare.link(element);
        element.set_locked_state(false);
        plugin.unpause();
        attached = true;
    }

    public void display_device(MediaDevice media_device) {
        if (element == null) return;
        detach();
        connected_device = media_device as Device;
        if (connected_device == null) return;
        plugin.pause();
        pipe.add(element);
        prepare = Gst.parse_bin_from_description(@"aspectratiocrop aspect-ratio=4/3 name=video_widget_$(id)_crop ! videoflip method=horizontal-flip name=video_widget_$(id)_flip ! videoconvert name=video_widget_$(id)_convert", true);
        prepare.name = @"video_widget_$(id)_prepare";
        prepare.get_static_pad("sink").notify["caps"].connect(input_caps_changed);
        pipe.add(prepare);
        connected_device_element = connected_device.link_source();
        connected_device_element.link(prepare);
        prepare.link(element);
        element.set_locked_state(false);
        plugin.unpause();
        attached = true;
    }

    public void detach() {
        if (element == null) return;
        if (attached) {
            if (connected_stream != null) {
                connected_stream.remove_output(prepare);
                connected_stream = null;
            }
            if (connected_device != null) {
                connected_device_element.unlink(element);
                connected_device_element = null;
                connected_device.unlink();
                connected_device = null;
            }
            prepare.set_locked_state(true);
            prepare.set_state(Gst.State.NULL);
            pipe.remove(prepare);
            prepare = null;
            element.set_locked_state(true);
            element.set_state(Gst.State.NULL);
            pipe.remove(element);
            attached = false;
        }
    }

    public override void dispose() {
        detach();
        widget = null;
        element = null;
    }
}