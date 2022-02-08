using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class FileImageWidget : EventBox {

    private ScalingImage image;
    FileDefaultWidget file_default_widget;
    FileDefaultWidgetController file_default_widget_controller;

    public FileImageWidget() {
        this.halign = Align.START;
        this.events = EventMask.POINTER_MOTION_MASK;

        this.get_style_context().add_class("file-image-widget");
    }

    public async void load_from_file(File file, string file_name, int MAX_WIDTH=600, int MAX_HEIGHT=300) throws GLib.Error {
        // Load and prepare image in tread
        Thread<ScalingImage?> thread = new Thread<ScalingImage?> (null, () => {
            ScalingImage image = new ScalingImage() { halign=Align.START, visible = true, max_width = MAX_WIDTH, max_height = MAX_HEIGHT };

            Gdk.Pixbuf pixbuf;
            try {
                pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
            } catch (Error error) {
                warning("Can't load picture %s - %s", file.get_path(), error.message);
                Idle.add(load_from_file.callback);
                return null;
            }

            pixbuf = pixbuf.apply_embedded_orientation();

            image.load(pixbuf);

            Idle.add(load_from_file.callback);
            return image;
        });
        yield;
        image = thread.join();
        if (image == null) throw new Error(-1, 0, "Error loading image");

        FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        string? mime_type = Dino.Util.get_content_type(file_info);

        file_default_widget = new FileDefaultWidget() { valign=Align.END, vexpand=false };
        file_default_widget.stack_event_box.visible = false;
        file_default_widget_controller = new FileDefaultWidgetController(file_default_widget);
        file_default_widget_controller.set_file(file, file_name, mime_type);

        Overlay overlay = new Overlay() { visible=true };
        overlay.add(image);
        overlay.add_overlay(file_default_widget);

        this.enter_notify_event.connect((event) => {
            file_default_widget.visible = true;
            return false;
        });
        this.leave_notify_event.connect((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) return false;
            if (file_default_widget.file_menu.popover != null && file_default_widget.file_menu.popover.visible) return false;

            file_default_widget.visible = false;
            return false;
        });

        this.add(overlay);
    }
}

}
