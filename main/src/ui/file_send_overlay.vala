using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class FileSendOverlay {

    public signal void close();
    public signal void send_file();

    public Box main_box;
    public Button close_button;
    public Button send_button;
    public SizingBin file_widget_insert;
    public Label info_label;

    private bool can_send = true;

    public FileSendOverlay(File file, FileInfo file_info) {
        Builder builder = new Builder.from_resource("/im/dino/Dino/file_send_overlay.ui");
        main_box = (Box) builder.get_object("main_box");
        close_button = (Button) builder.get_object("close_button");
        send_button = (Button) builder.get_object("send_button");
        file_widget_insert = (SizingBin) builder.get_object("file_widget_insert");
        info_label = (Label) builder.get_object("info_label");

        close_button.clicked.connect(() => {
            do_close();
        });
        send_button.clicked.connect(() => {
            send_file();
            do_close();
        });

        load_file_widget.begin(file, file_info);

        main_box.realize.connect(() => {
            if (can_send) {
                send_button.grab_focus();
            } else {
                close_button.grab_focus();
            }
        });

        var key_events = new EventControllerKey();
        key_events.key_pressed.connect((keyval) => {
            if (keyval == Gdk.Key.Escape) {
                do_close();
            }
            return false;
        });
        this.main_box.add_controller(key_events);
    }

    private async void load_file_widget(File file, FileInfo file_info) {
        string file_name = file_info.get_display_name();
        string mime_type = Dino.Util.get_content_type(file_info);

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
            FileImageWidget image_widget = new FileImageWidget();
            try {
                yield image_widget.load_from_file(file, file_name);
                widget = image_widget;
            } catch (Error e) { }
        }

        if (widget == null) {
            FileDefaultWidget default_widget = new FileDefaultWidget();
            default_widget.name_label.label = file_name;
            default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
            widget = default_widget;
        }

        widget.set_parent(file_widget_insert);
    }

    public void set_file_too_large() {
        info_label.label= _("The file exceeds the server's maximum upload size.");
        Util.force_error_color(info_label);
        send_button.sensitive = false;
        can_send = false;
    }

    private void do_close() {
        this.close();
        main_box.unparent();
        main_box.destroy();
    }

    public Widget get_widget() {
        return main_box;
    }
}

}
