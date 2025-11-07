using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Adw.Dialog {

    public signal void close();
    public signal void send_file();

    [GtkChild] protected unowned Button send_button;
    [GtkChild] protected unowned SizingBin file_widget_insert;
    [GtkChild] protected unowned Label info_label;

    private bool can_send = true;

    public FileSendOverlay(File file, FileInfo file_info) {
//        send_button.clicked.connect(() => {
//            send_file();
//            close();
//        });

        load_file_widget.begin(file, file_info);
    }

    private async void load_file_widget(File file, FileInfo file_info) {
        string file_name = file_info.get_display_name();
        string mime_type = file_info.get_content_type();

        bool is_image = Dino.Util.is_pixbuf_supported_mime_type(mime_type);

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
            default_widget.set_static_file_info(mime_type);
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
}

}
