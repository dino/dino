using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Gtk.EventBox {

    public signal void close();
    public signal void send_file();

    [GtkChild] public Button close_button;
    [GtkChild] public Button send_button;
    [GtkChild] public SizingBin file_widget_insert;
    [GtkChild] public Label info_label;

    private bool can_send = true;

    public FileSendOverlay(File file, FileInfo file_info) {
        close_button.clicked.connect(() => {
            this.close();
            this.destroy();
        });
        send_button.clicked.connect(() => {
            send_file();
            this.close();
            this.destroy();
        });

        load_file_widget.begin(file, file_info);

        this.realize.connect(() => {
            if (can_send) {
                send_button.grab_focus();
            } else {
                close_button.grab_focus();
            }
        });

        this.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                this.destroy();
            }
            return false;
        });
    }

    public void set_file_too_large() {
        info_label.label= "The file exceeds the server's maximum upload size.";
        Util.force_error_color(info_label);
        send_button.sensitive = false;
        can_send = false;
    }

    private async void load_file_widget(File file, FileInfo file_info) {
        string file_name = file_info.get_display_name();
        string mime_type = file_info.get_content_type();

        bool is_image = false;

        foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
            foreach (string supported_mime_type in pixbuf_format.get_mime_types()) {
                if (supported_mime_type == mime_type) {
                    is_image = true;
                }
            }
        }

        Widget? widget = null;
        if (is_image) {
            FileImageWidget image_widget = new FileImageWidget() { visible=true };
            try {
                yield image_widget.load_from_file(file, file_name);
                widget = image_widget;
            } catch (Error e) { }
        }

        if (widget == null) {
            FileDefaultWidget default_widget = new FileDefaultWidget() { visible=true };
            default_widget.name_label.label = file_name;
            default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
            widget = default_widget;
        }

        file_widget_insert.add(widget);
    }
}

}
