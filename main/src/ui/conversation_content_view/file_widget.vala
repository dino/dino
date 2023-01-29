using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public class FileMetaItem : ConversationSummary.ContentMetaItem {

    private StreamInteractor stream_interactor;
    private FileItem file_item;
    private FileTransfer file_transfer;

    public FileMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
        base(content_item);
        this.stream_interactor = stream_interactor;
        this.file_item = content_item as FileItem;
        this.file_transfer = file_item.file_transfer;
    }

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
        FileWidget widget = new FileWidget(file_transfer);
        FileWidgetController widget_controller = new FileWidgetController(widget, file_transfer, stream_interactor);
        return widget;
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
        if (file_transfer.provider != 0 || file_transfer.info == null) return null;

        Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();

        if (stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_id_for_content_item(file_item.conversation, content_item) != null) {
            actions.add(get_reply_action(content_item, file_item.conversation, stream_interactor));
            actions.add(get_reaction_action(content_item, file_item.conversation, stream_interactor));
        }
        return actions;
    }
}

public class FileWidget : SizeRequestBox {

    enum State {
        IMAGE,
        DEFAULT
    }

    private FileTransfer file_transfer;
    public FileTransfer.State file_transfer_state { get; set; }
    public string file_transfer_mime_type { get; set; }
    private State? state = null;

    private FileDefaultWidgetController default_widget_controller;
    private Widget? content = null;

    public signal void open_file();
    public signal void save_file_as();
    public signal void start_download();
    public signal void cancel_download();

    class construct {
        install_action("file.open", null, (widget, action_name) => { ((FileWidget) widget).open_file(); });
        install_action("file.save_as", null, (widget, action_name) => { ((FileWidget) widget).save_file_as(); });
        install_action("file.download", null, (widget, action_name) => { ((FileWidget) widget).start_download(); });
        install_action("file.cancel", null, (widget, action_name) => { ((FileWidget) widget).cancel_download(); });
    }

    construct {
        margin_top = 4;
        size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public FileWidget(FileTransfer file_transfer) {
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
            default_widget_controller.set_file_transfer(file_transfer);
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

public class FileWidgetController : Object {

    private weak Widget widget;
    private FileTransfer file_transfer;
    private StreamInteractor? stream_interactor;

    public FileWidgetController(FileWidget widget, FileTransfer file_transfer, StreamInteractor? stream_interactor = null) {
        this.widget = widget;
        this.ref();
        this.widget.weak_ref(() => {
            this.widget = null;
            this.unref();
        });
        this.file_transfer = file_transfer;
        this.stream_interactor = stream_interactor;

        widget.open_file.connect(open_file);
        widget.save_file_as.connect(save_file);
        widget.start_download.connect(start_download);
        widget.cancel_download.connect(cancel_download);
    }

    private void open_file() {
        try{
            AppInfo.launch_default_for_uri(file_transfer.get_file().get_uri(), null);
        } catch (Error err) {
            warning("Failed to open %s - %s", file_transfer.get_file().get_uri(), err.message);
        }
    }

    private void save_file() {
        var save_dialog = new FileChooserNative(_("Save as…"), widget.get_root() as Gtk.Window, FileChooserAction.SAVE, null, null);
        save_dialog.set_modal(true);
        save_dialog.set_current_name(file_transfer.file_name);

        save_dialog.response.connect(() => {
            try{
                GLib.File.new_for_uri(file_transfer.get_file().get_uri()).copy(save_dialog.get_file(), GLib.FileCopyFlags.OVERWRITE, null);
            } catch (Error err) {
                warning("Failed copy file %s - %s", file_transfer.get_file().get_uri(), err.message);
            }
        });

        save_dialog.show();
    }

    private void start_download() {
        if (stream_interactor != null) {
            stream_interactor.get_module(FileManager.IDENTITY).download_file.begin(file_transfer);
        }
    }

    private void cancel_download() {
        file_transfer.cancellable.cancel();
    }
}

public class FileDefaultWidgetController : Object {

    private FileDefaultWidget widget;
    private FileTransfer? file_transfer;
    public string file_transfer_state { get; set; }
    public string file_transfer_mime_type { get; set; }

    private FileTransfer.State state;

    public FileDefaultWidgetController(FileDefaultWidget widget) {
        this.widget = widget;

        widget.clicked.connect(on_clicked);

        this.notify["file-transfer-state"].connect(update_file_info);
        this.notify["file-transfer-mime-type"].connect(update_file_info);
    }

    public void set_file_transfer(FileTransfer file_transfer) {
        this.file_transfer = file_transfer;

        widget.name_label.label = file_transfer.file_name;

        file_transfer.bind_property("state", this, "file-transfer-state");
        file_transfer.bind_property("mime-type", this, "file-transfer-mime-type");

        update_file_info();
    }

    private void update_file_info() {
        state = file_transfer.state;
        widget.update_file_info(file_transfer.mime_type, file_transfer.state, file_transfer.size);
    }

    private void on_clicked() {
        switch (state) {
            case FileTransfer.State.COMPLETE:
                widget.activate_action("file.open", null);
                break;
            case FileTransfer.State.NOT_STARTED:
                widget.activate_action("file.download", null);
                break;
            default:
                // Clicking doesn't do anything in FAILED and IN_PROGRESS states
                break;
        }
    }
}

}
