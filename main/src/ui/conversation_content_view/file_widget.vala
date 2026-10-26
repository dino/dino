using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

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
        if ((file_transfer.provider != FileManager.HTTP_PROVIDER_ID && file_transfer.provider != FileManager.SFS_PROVIDER_ID) || file_transfer.info == null) return null;

        Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();

        actions.add(get_reply_action(content_item, file_item.conversation, stream_interactor));
        actions.add(get_reaction_action(content_item, file_item.conversation, stream_interactor));

        var delete_action = get_delete_action(content_item, file_item.conversation, stream_interactor);
        if (delete_action != null) actions.add(delete_action);

        return actions;
    }
}

public class FileWidget : SizeRequestBin {

    enum State {
        IMAGE,
        DEFAULT
    }

    private FileTransfer file_transfer;
    public FileTransfer.State file_transfer_state { get; set; }
    public FileContentType file_transfer_content_type { get; set; }
    private State? state = null;

    private FileDefaultWidgetController default_widget_controller;
    private Widget? content = null;

    construct {
        margin_top = 4;
        size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
        check_widget_leak(this);
    }

    public FileWidget(FileTransfer file_transfer) {
        this.file_transfer = file_transfer;

        update_widget.begin();

        file_transfer.bind_property("state", this, "file-transfer-state");
        file_transfer.bind_property("content-type", this, "file-transfer-content-type");

        this.notify["file-transfer-state"].connect(update_widget);
        this.notify["file-transfer-content-type"].connect(update_widget);
    }

    private async void update_widget() {
        bool show_image = FileImageWidget.can_display(file_transfer);

        if (show_image && state != State.IMAGE) {
            var content_bak = content;

            FileImageWidget file_image_widget = null;
            try {
                file_image_widget = new FileImageWidget.from_file_transfer(file_transfer);
                file_image_widget.add_css_class("file-image-widget");

                // If the widget changed in the meanwhile, stop
                if (content != content_bak) return;

                if (content != null) content.unparent();
                content = file_image_widget;
                state = State.IMAGE;
                content.insert_after(this, null);
                return;
            } catch (Error e) { }
        }

        if (!show_image && state != State.DEFAULT) {
            if (content != null) content.unparent();
            FileDefaultWidget default_file_widget = new FileDefaultWidget();
            default_widget_controller = new FileDefaultWidgetController(default_file_widget);
            default_widget_controller.set_file_transfer(file_transfer);
            content = default_file_widget;
            this.state = State.DEFAULT;
            content.insert_after(this, null);
        }
    }

    public override void dispose() {
        if (default_widget_controller != null) default_widget_controller.dispose();
        default_widget_controller = null;
        if (content != null) {
            content.unparent();
            content.dispose();
            content = null;
        }
        base.dispose();
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
    }
}

public class FileDefaultWidgetController : Object {

    private FileDefaultWidget widget;
    private FileTransfer? file_transfer;
    public string file_transfer_state { get; set; }
    public FileContentType file_transfer_content_type { get; set; }
    public int64 file_transfer_transferred_bytes { get; set; }

    private FileTransfer.State state;

    public FileDefaultWidgetController(FileDefaultWidget widget) {
        this.widget = widget;

        widget.clicked.connect(on_clicked);

        this.notify["file-transfer-state"].connect(update_file_info);
        this.notify["file-transfer-content-type"].connect(update_file_info);
        this.notify["file-transfer-transferred-bytes"].connect(update_file_info);
    }

    public void set_file_transfer(FileTransfer file_transfer) {
        this.file_transfer = file_transfer;

        widget.init_updating_file_info();
        widget.name_label.label = file_transfer.file_name;

        file_transfer.bind_property("state", this, "file-transfer-state");
        file_transfer.bind_property("content-type", this, "file-transfer-content-type");
        file_transfer.bind_property("transferred-bytes", this, "file-transfer-transferred-bytes");

        update_file_info();
    }

    private void update_file_info() {
        state = file_transfer.state;
        widget.update_file_info(file_transfer);
    }

    private void on_clicked() {
        switch (state) {
            case FileTransfer.State.COMPLETE:
                Dino.Application.get_default().activate_action("file_open_externally", new GLib.Variant.int32(file_transfer.id));
                break;
            case FileTransfer.State.NOT_STARTED:
                Dino.Application.get_default().activate_action("file_start_download", new GLib.Variant.int32(file_transfer.id));
                break;
            default:
                // Clicking doesn't do anything in FAILED and IN_PROGRESS states
                break;
        }
    }
}

}
