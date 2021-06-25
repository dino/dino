using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public class FileMetaItem : ConversationSummary.ContentMetaItem {

    private StreamInteractor stream_interactor;

    public FileMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
        base(content_item);
        this.stream_interactor = stream_interactor;
    }

    public override Object? get_widget(Plugins.WidgetType type) {
        FileItem file_item = content_item as FileItem;
        FileTransfer transfer = file_item.file_transfer;
        return new FileWidget(stream_interactor, transfer) { visible=true };
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
}

public class FileWidget : SizeRequestBox {

    enum State {
        IMAGE,
        DEFAULT
    }

    private StreamInteractor stream_interactor;
    private FileTransfer file_transfer;
    public FileTransfer.State file_transfer_state { get; set; }
    public string file_transfer_mime_type { get; set; }
    private State? state = null;

    private FileDefaultWidgetController default_widget_controller;
    private Widget? content = null;

    construct {
        margin_top = 4;
        size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public FileWidget(StreamInteractor stream_interactor, FileTransfer file_transfer) {
        this.stream_interactor = stream_interactor;
        this.file_transfer = file_transfer;

        update_widget.begin();
        size_allocate.connect((allocation) => {
            if (allocation.height > parent.get_allocated_height()) {
                Idle.add(() => { parent.queue_resize(); return false; });
            }
        });

        file_transfer.bind_property("state", this, "file-transfer-state");
        file_transfer.bind_property("mime-type", this, "file-transfer-mime-type");

        this.notify["file-transfer-state"].connect(update_widget);
        this.notify["file-transfer-mime-type"].connect(update_widget);
    }

    private async void update_widget() {
        if (show_image() && state != State.IMAGE) {
            var content_bak = content;

            FileImageWidget file_image_widget = null;
            try {
                file_image_widget = new FileImageWidget() { visible=true };
                yield file_image_widget.load_from_file(file_transfer.get_file(), file_transfer.file_name);

                // If the widget changed in the meanwhile, stop
                if (content != content_bak) return;

                if (content != null) this.remove(content);
                content = file_image_widget;
                state = State.IMAGE;
                this.add(content);
                return;
            } catch (Error e) { }
        }

        if (state != State.DEFAULT) {
            if (content != null) this.remove(content);
            FileDefaultWidget default_file_widget = new FileDefaultWidget() { visible=true };
            default_widget_controller = new FileDefaultWidgetController(default_file_widget);
            default_widget_controller.set_file_transfer(file_transfer, stream_interactor);
            content = default_file_widget;
            this.state = State.DEFAULT;
            this.add(content);
        }
    }

    private bool show_image() {
        if (file_transfer.mime_type == null) return false;
        if (file_transfer.state != FileTransfer.State.COMPLETE &&
                !(file_transfer.direction == FileTransfer.DIRECTION_SENT && file_transfer.state == FileTransfer.State.IN_PROGRESS)) {
            return false;
        }

        foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
            foreach (string mime_type in pixbuf_format.get_mime_types()) {
                if (mime_type == file_transfer.mime_type) {
                    return true;
                }
            }
        }
        return false;
    }
}

public class FileDefaultWidgetController : Object {

    private FileDefaultWidget widget;
    private FileTransfer? file_transfer;
    public string file_transfer_path { get; set; }
    public string file_transfer_state { get; set; }
    public string file_transfer_mime_type { get; set; }

    private StreamInteractor? stream_interactor;
    private string file_uri;
    private FileTransfer.State state;

    public FileDefaultWidgetController(FileDefaultWidget widget) {
        this.widget = widget;
        widget.button_release_event.connect(on_clicked);
    }

    public void set_file_transfer(FileTransfer file_transfer, StreamInteractor stream_interactor) {
        this.file_transfer = file_transfer;
        this.stream_interactor = stream_interactor;

        widget.name_label.label = file_transfer.file_name;

        file_transfer.bind_property("path", this, "file-transfer-path");
        file_transfer.bind_property("state", this, "file-transfer-state");
        file_transfer.bind_property("mime-type", this, "file-transfer-mime-type");

        this.notify["file-transfer-path"].connect(update_file_info);
        this.notify["file-transfer-state"].connect(update_file_info);
        this.notify["file-transfer-mime-type"].connect(update_file_info);

        update_file_info();
    }

    public void set_file(File file, string file_name, string? mime_type) {
        file_uri = file.get_uri();
        state = FileTransfer.State.COMPLETE;
        widget.name_label.label = file_name;
        widget.update_file_info(mime_type, state, -1);
    }

    private void update_file_info() {
        file_uri = file_transfer.get_file().get_uri();
        state = file_transfer.state;
        widget.update_file_info(file_transfer.mime_type, file_transfer.state, file_transfer.size);
    }

    private void save_as(Gtk.Dialog dialog, int response_id) {
        var save_dialog = dialog as Gtk.FileChooserDialog;
        File file_src;
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                file_src = GLib.File.new_for_path (GLib.Path.build_filename (file_uri.substring(7)));
                    try{
                        file_src.copy(save_dialog.get_file(), GLib.FileCopyFlags.OVERWRITE, null);	
                    } catch (Error err) {
                        warning("Failed copy file %s - %s", file_uri, err.message);
                    }
            break;
            default:
            break;
        }
        dialog.destroy ();
    }

    private bool on_clicked(EventButton event_button) {
        switch (state) {
            case FileTransfer.State.COMPLETE:
                if (event_button.button == 1) {
                    try{
                        AppInfo.launch_default_for_uri(file_uri, null);
                    } catch (Error err) {
                        warning("Failed to open %s - %s", file_uri, err.message);
                    }
                }
                if (event_button.button == 3) {
                    var save_dialog = new Gtk.FileChooserDialog ("Save as file", this as Gtk.Window, Gtk.FileChooserAction.SAVE, Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL, Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
                    save_dialog.set_do_overwrite_confirmation (true);
                    save_dialog.set_modal(true);
                    try {
                        (save_dialog as Gtk.FileChooser).set_file (GLib.File.new_for_path (GLib.Path.build_filename (file_uri.substring(7))));
                    } catch (GLib.Error error) {
                        warning("Faild to open save dialog: %s\n", error.message);
                    }
                    save_dialog.response.connect(save_as);
                    save_dialog.show();
                }
                break;
            case FileTransfer.State.NOT_STARTED:
                assert(stream_interactor != null && file_transfer != null);
                stream_interactor.get_module(FileManager.IDENTITY).download_file.begin(file_transfer);
                break;
        }
        return false;
    }
}

}
