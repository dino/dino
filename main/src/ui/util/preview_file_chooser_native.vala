using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class PreviewFileChooserNative : Object {
    private const int PREVIEW_SIZE = 180;
    private const int PREVIEW_PADDING = 5;

    private Gtk.FileChooserNative? chooser = null;
    private Image preview_image = new Image();

    public PreviewFileChooserNative(string? title, Gtk.Window? parent, FileChooserAction action, string? accept_label, string? cancel_label) {
        chooser = new FileChooserNative(title, parent, action, accept_label, cancel_label);

        chooser.set_preview_widget(this.preview_image);
        chooser.use_preview_label = false;
        chooser.preview_widget_active = false;

        chooser.update_preview.connect(on_update_preview);
    }

    public void add_filter(owned Gtk.FileFilter filter) {
        chooser.add_filter(filter);
    }

    public SList<File> get_files() {
        return chooser.get_files();
    }

    public int run() {
        return chooser.run();
    }

    public string? get_filename() {
        return chooser.get_filename();
    }

    private void on_update_preview() {
        Pixbuf preview_pixbuf = get_preview_pixbuf();
        if (preview_pixbuf != null) {
            int extra_space = PREVIEW_SIZE - preview_pixbuf.width;
            int smaller_half = extra_space/2;
            int larger_half = extra_space - smaller_half;

            preview_image.set_margin_start(PREVIEW_PADDING + smaller_half);
            preview_image.set_margin_end(PREVIEW_PADDING + larger_half);

            preview_image.set_from_pixbuf(preview_pixbuf);
            chooser.preview_widget_active = true;
        } else {
            chooser.preview_widget_active = false;
        }
    }

    private Pixbuf? get_preview_pixbuf() {
        string? filename = chooser.get_preview_filename();
        if (filename == null) {
            return null;
        }

        int width = 0;
        int height = 0;
        Gdk.PixbufFormat? format = Gdk.Pixbuf.get_file_info(filename, out width, out height);
        if (format == null) {
            return null;
        }

        try {
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale(filename, PREVIEW_SIZE, PREVIEW_SIZE, true);
            pixbuf = pixbuf.apply_embedded_orientation();
            return pixbuf;
        } catch (Error e) {
            return null;
        }
    }

}

}
