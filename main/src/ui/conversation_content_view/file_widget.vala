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

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
        FileItem file_item = content_item as FileItem;
        FileTransfer transfer = file_item.file_transfer;
        return new FileWidget(stream_interactor, transfer);
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
//        size_allocate.connect((allocation) => {
//            if (allocation.height > parent.get_allocated_height()) {
//                Idle.add(() => { parent.queue_resize(); return false; });
//            }
//        });

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
                file_image_widget = new FileImageWidget();
                yield file_image_widget.load_from_file(file_transfer.get_file(), file_transfer.file_name);

                // If the widget changed in the meanwhile, stop
                if (content != content_bak) return;

                if (content != null) this.remove(content);
                content = file_image_widget;
                state = State.IMAGE;
                this.append(content);
                return;
            } catch (Error e) { }
        }

        if (state != State.DEFAULT) {
            if (content != null) this.remove(content);
            FileDefaultWidget default_file_widget = new FileDefaultWidget();
            default_widget_controller = new FileDefaultWidgetController(default_file_widget);
            default_widget_controller.set_file_transfer(file_transfer, stream_interactor);
            content = default_file_widget;
            this.state = State.DEFAULT;
            this.append(content);
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
    private string file_name;
    private FileTransfer.State state;

    public FileDefaultWidgetController(FileDefaultWidget widget) {
        this.widget = widget;

        widget.clicked.connect(on_clicked);
        widget.open_file.connect(open_file);
        widget.save_file_as.connect(save_file);
        widget.cancel_download.connect(cancel_download);
    }

    public void set_file_transfer(FileTransfer file_transfer, StreamInteractor stream_interactor) {
        this.file_transfer = file_transfer;
        this.stream_interactor = stream_interactor;

        widget.name_label.label = file_name = file_transfer.file_name;

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
        widget.name_label.label = this.file_name = file_name;
        widget.update_file_info(mime_type, state, -1);
    }

    private void update_file_info() {
        file_uri = file_transfer.get_file().get_uri();
        state = file_transfer.state;
        widget.update_file_info(file_transfer.mime_type, file_transfer.state, (long) file_transfer.size);
    }

    private void open_file() {
        try{
            AppInfo.launch_default_for_uri(file_uri, null);
        } catch (Error err) {
            warning("Failed to open %s - %s", file_uri, err.message);
        }
    }

    private void save_file() {
        var save_dialog = new FileChooserNative(_("Save as…"), widget.get_root() as Gtk.Window, FileChooserAction.SAVE, null, null);
        save_dialog.set_modal(true);
        save_dialog.set_current_name(file_name);

        save_dialog.response.connect(() => {
            try{
                GLib.File.new_for_uri(file_uri).copy(save_dialog.get_file(), GLib.FileCopyFlags.OVERWRITE, null);
            } catch (Error err) {
                warning("Failed copy file %s - %s", file_uri, err.message);
            }
        });

        save_dialog.show();
    }

    private void cancel_download() {
        file_transfer.cancellable.cancel();
    }

    private void on_clicked() {
        switch (state) {
            case FileTransfer.State.COMPLETE:
                open_file();
                break;
            case FileTransfer.State.NOT_STARTED:
                assert(stream_interactor != null && file_transfer != null);
                stream_interactor.get_module(FileManager.IDENTITY).download_file.begin(file_transfer);
                break;
            default:
                // Clicking doesn't do anything in FAILED and IN_PROGRESS states
                break;
        }
    }
}

}
