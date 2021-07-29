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
    private Stream? connected_stream;
    private Gst.Element convert;

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

            // Listen for resolution changes
            element.get_static_pad("sink").notify["caps"].connect(() => {
                if (element.get_static_pad("sink").caps == null) return;

                int width, height;
                element.get_static_pad("sink").caps.get_structure(0).get_int("width", out width);
                element.get_static_pad("sink").caps.get_structure(0).get_int("height", out height);
                resolution_changed(width, height);
            });
        } else {
            warning("Could not create GTK video sink. Won't display videos.");
        }
    }

    public void display_stream(Xmpp.Xep.JingleRtp.Stream stream) {
        if (element == null) return;
        detach();
        if (stream.media != "video") return;
        connected_stream = stream as Stream;
        if (connected_stream == null) return;
        plugin.pause();
        pipe.add(element);
        convert = Gst.parse_bin_from_description(@"videoconvert name=video_widget_$(id)_convert", true);
        convert.name = @"video_widget_$(id)_prepare";
        pipe.add(convert);
        convert.link(element);
        connected_stream.add_output(convert);
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
        convert = Gst.parse_bin_from_description(@"videoflip method=horizontal-flip name=video_widget_$(id)_flip ! videoconvert name=video_widget_$(id)_convert", true);
        convert.name = @"video_widget_$(id)_prepare";
        pipe.add(convert);
        convert.link(element);
        connected_device.link_source().link(convert);
        element.set_locked_state(false);
        plugin.unpause();
        attached = true;
    }

    public void detach() {
        if (element == null) return;
        if (attached) {
            if (connected_stream != null) {
                connected_stream.remove_output(convert);
                connected_stream = null;
            }
            if (connected_device != null) {
                connected_device.link_source().unlink(element);
                connected_device.unlink(); // We get a new ref to recover the element, so unlink twice
                connected_device.unlink();
                connected_device = null;
            }
            convert.set_locked_state(true);
            convert.set_state(Gst.State.NULL);
            pipe.remove(convert);
            convert = null;
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