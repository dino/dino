private static extern unowned Gst.Video.Info gst_video_frame_get_video_info(Gst.Video.Frame frame);
private static extern unowned uint8[] gst_video_frame_get_data(Gst.Video.Frame frame);

public class Dino.Plugins.Rtp.Paintable : Gdk.Paintable, Object {
    private Gdk.Paintable image;
    private double pixel_aspect_ratio;

    public override Gdk.PaintableFlags get_flags() {
        return 0;
    }

    public void snapshot(Gdk.Snapshot snapshot, double width, double height) {
        if (image != null) image.snapshot(snapshot, width, height);
    }

    public override Gdk.Paintable get_current_image() {
        if (image != null) return image;
        return Gdk.Paintable.new_empty(0, 0);
    }

    public override int get_intrinsic_width() {
        if (image != null) return (int) (pixel_aspect_ratio * image.get_intrinsic_width());
        return 0;
    }

    public override int get_intrinsic_height() {
        if (image != null) return (int) (pixel_aspect_ratio * image.get_intrinsic_height());
        return 0;
    }

    public override double get_intrinsic_aspect_ratio() {
        if (image != null) return pixel_aspect_ratio * image.get_intrinsic_aspect_ratio();
        return 0.0;
    }

    public override void dispose() {
        image = null;
        base.dispose();
    }

    private void set_paintable(Gdk.Paintable paintable, double pixel_aspect_ratio) {
        if (paintable == image) return;
        bool size_changed = image == null ||
                this.pixel_aspect_ratio * image.get_intrinsic_width() != pixel_aspect_ratio * paintable.get_intrinsic_width() ||
                image.get_intrinsic_height() != paintable.get_intrinsic_height() ||
                image.get_intrinsic_aspect_ratio() != paintable.get_intrinsic_aspect_ratio();

        if (image != null) this.image.dispose();
        this.image = paintable;
        this.pixel_aspect_ratio = pixel_aspect_ratio;

        if (size_changed) invalidate_size();
        invalidate_contents();
    }

    public void queue_set_texture(Gdk.Texture texture, double pixel_aspect_ratio) {
        Idle.add(() => {
            set_paintable(texture, pixel_aspect_ratio);
            return Source.REMOVE;
        }, Priority.DEFAULT);
    }
}

public class Dino.Plugins.Rtp.Sink : Gst.Video.Sink {
    internal Paintable paintable = new Paintable();
    private Gst.Video.Info info = new Gst.Video.Info();

    class construct {
        set_metadata("Dino Gtk Video Sink", "Sink/Video", "The video sink used by Dino", "Dino Team <team@dino.im>");
        add_pad_template(new Gst.PadTemplate("sink", Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, Gst.Caps.from_string(@"video/x-raw, format={ BGRA, ARGB, RGBA, ABGR, RGB, BGR }")));
    }

    construct {
        set_drop_out_of_segment(false);
    }

#if GST_1_20
    public override bool set_info(Gst.Caps caps, Gst.Video.Info info) {
        this.info = info;
        return true;
    }
#else
    public override bool set_caps(Gst.Caps caps) {
        base.set_caps(caps);
        return info.from_caps(caps);
    }
#endif

    public override void get_times(Gst.Buffer buffer, out Gst.ClockTime start, out Gst.ClockTime end) {
        if (buffer.pts != -1) {
            start = buffer.pts;
            if (buffer.duration != -1) {
                end = start + buffer.duration;
            } else if (info.fps_n > 0) {
                end = start + Gst.Util.uint64_scale_int(Gst.SECOND, info.fps_d, info.fps_n);
            }
        }
    }

    public override Gst.Caps get_caps(Gst.Caps? filter) {
        Gst.Caps caps = Gst.Caps.from_string("video/x-raw, format={ BGRA, ARGB, RGBA, ABGR, RGB, BGR }");

        if (filter != null) {
            return filter.intersect(caps, Gst.CapsIntersectMode.FIRST);
        } else {
            return caps;
        }
    }

    private Gdk.MemoryFormat memory_format_from_video(Gst.Video.Format format) {
        switch (format) {
            case Gst.Video.Format.BGRA: return Gdk.MemoryFormat.B8G8R8A8;
            case Gst.Video.Format.ARGB: return Gdk.MemoryFormat.A8R8G8B8;
            case Gst.Video.Format.RGBA: return Gdk.MemoryFormat.R8G8B8A8;
            case Gst.Video.Format.ABGR: return Gdk.MemoryFormat.A8B8G8R8;
            case Gst.Video.Format.RGB: return Gdk.MemoryFormat.R8G8B8;
            case Gst.Video.Format.BGR: return Gdk.MemoryFormat.B8G8R8;
            default:
                warning("Unsupported video format: %s", format.to_string());
                return Gdk.MemoryFormat.A8R8G8B8;
        }
    }

    private Gdk.Texture texture_from_buffer(Gst.Buffer buffer, out double pixel_aspect_ratio) {
        Gst.Video.Frame frame = Gst.Video.Frame();
        Gdk.Texture texture;

        if (frame.map(info, buffer, Gst.MapFlags.READ)) {
            unowned Gst.Video.Info info = gst_video_frame_get_video_info(frame);
            Bytes bytes = new Bytes.take(gst_video_frame_get_data(frame));
            texture = new Gdk.MemoryTexture(info.width, info.height, memory_format_from_video(info.finfo.format), bytes, info.stride[0]);
            pixel_aspect_ratio = ((double) info.par_n) / ((double) info.par_d);
            frame.unmap();
        } else {
            texture = null;
        }
        return texture;
    }

    private void queue_buffer(Gst.Buffer buf) {
        double pixel_aspect_ratio;
        Gdk.Texture texture = texture_from_buffer(buf, out pixel_aspect_ratio);
        if (texture != null) {
            paintable.queue_set_texture(texture, pixel_aspect_ratio);
        }
    }

    public override Gst.FlowReturn show_frame(Gst.Buffer buf) {
        @lock.lock();
        queue_buffer(buf);
        @lock.unlock();

        return Gst.FlowReturn.OK;
    }
}

public class Dino.Plugins.Rtp.VideoWidget : Gtk.Widget, Dino.Plugins.VideoCallWidget {
    private const int RECAPS_AFTER_CHANGE = 5;
    private static uint last_id = 0;

    public uint id { get; private set; }
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
    private int recaps_since_change;
    private Sink sink;
    private Gtk.Picture widget;

    public VideoWidget(Plugin plugin) {
        this.plugin = plugin;
        this.layout_manager = new Gtk.BinLayout();

        id = last_id++;
        sink = new Sink() { async = false, sync = true };
        widget = new Gtk.Picture.for_paintable(sink.paintable);
        widget.insert_after(this, null);
    }

    public void input_caps_changed(GLib.Object pad, ParamSpec spec) {
        Gst.Caps? caps = ((Gst.Pad)pad).caps;
        if (caps == null) {
            debug("Input: No caps");
            return;
        }

        int width, height;
        caps.get_structure(0).get_int("width", out width);
        caps.get_structure(0).get_int("height", out height);
        debug("Input resolution changed: %ix%i", width, height);
        resolution_changed(width, height);
        last_input_caps = caps;
    }

    public void display_stream(Xmpp.Xep.JingleRtp.Stream? stream, Xmpp.Jid jid) {
        if (sink == null) return;
        detach();
        if (stream.media != "video") return;
        connected_stream = stream as Stream?;
        if (connected_stream == null) return;
        plugin.pause();
        pipe.add(sink);
        prepare = Gst.parse_bin_from_description(@"videoconvert name=video_widget_$(id)_convert", true);
        prepare.name = @"video_widget_$(id)_prepare";
        prepare.get_static_pad("sink").notify["caps"].connect(input_caps_changed);
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
        prepare = Gst.parse_bin_from_description(@"videoflip method=horizontal-flip name=video_widget_$(id)_flip ! videoconvert name=video_widget_$(id)_convert", true);
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
            debug("Detaching");
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
        if (widget != null) widget.unparent();
        widget = null;
        sink = null;
    }
}
