using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Adw.Dialog {

    public signal void send_file(File file);

    [GtkChild] protected unowned Button send_button;
    [GtkChild] protected unowned SizingBin file_widget_insert;
    [GtkChild] protected unowned Label info_label;

    private File file;
    private bool can_send = true;

    public FileSendOverlay(File file, FileInfo file_info) {
        this.file = file;
        load_file_widget.begin(file, file_info);
    }

    [GtkCallback]
    private void on_send_button_clicked() {
        send_file(file);
        close();
    }

    private async void load_file_widget(File file, FileInfo file_info) {
        string file_name = file_info.get_display_name();
        var content_type = new Xmpp.FileContentType.from_file_info(file_info);

        bool is_image = Dino.Util.is_pixbuf_supported_content_type(content_type);

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
            default_widget.set_static_file_info(content_type);
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
