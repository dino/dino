using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class FileMetaItem : ContentMetaItem {

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

public class FileWidget : Box {

    enum State {
        IMAGE,
        DEFAULT
    }

    private const int MAX_HEIGHT = 300;
    private const int MAX_WIDTH = 600;

    private StreamInteractor stream_interactor;
    private FileTransfer file_transfer;
    private State state;

    private FileDefaultWidgetController default_widget_controller;
    private Widget content;

    public FileWidget(StreamInteractor stream_interactor, FileTransfer file_transfer) {
        this.stream_interactor = stream_interactor;
        this.file_transfer = file_transfer;

        load_widget.begin();
        size_allocate.connect((allocation) => {
            if (allocation.height > parent.get_allocated_height()) {
                Idle.add(() => { parent.queue_resize(); return false; });
            }
        });

        file_transfer.notify["state"].connect(update_widget_type);
        file_transfer.notify["mime-type"].connect(update_widget_type);
    }

    private async void load_widget() {
        if (show_image()) {
            content = yield get_image_widget(file_transfer.get_file(), file_transfer.file_name);
            if (content != null) {
                this.state = State.IMAGE;
                this.add(content);
                return;
            }
        }
        FileDefaultWidget default_file_widget = new FileDefaultWidget() { visible=true };
        default_widget_controller = new FileDefaultWidgetController(default_file_widget, file_transfer, stream_interactor);
        content = default_file_widget;
        this.state = State.DEFAULT;
        this.add(content);
    }

    private async void update_widget_type() {
        if (file_transfer.state == FileTransfer.State.COMPLETE && show_image() && state != State.IMAGE) {
            this.remove(content);
            this.add(yield get_image_widget(file_transfer.get_file(), file_transfer.file_name));
            state = State.IMAGE;
            return;
        }
        if (file_transfer.state == FileTransfer.State.FAILED && state == State.IMAGE) {
            this.remove(content);
            FileDefaultWidget default_file_widget = new FileDefaultWidget() { visible=true };
            default_widget_controller = new FileDefaultWidgetController(default_file_widget, file_transfer, stream_interactor);
            content = default_file_widget;
            this.state = State.DEFAULT;
            this.add(content);
        }
    }

    public static async Widget? get_image_widget(File file, string file_name, int MAX_WIDTH=600, int MAX_HEIGHT=300) {
        // Load and prepare image in tread
        Thread<Image?> thread = new Thread<Image?> (null, () => {
            ScalingImage image = new ScalingImage() { halign=Align.START, visible = true, max_width = MAX_WIDTH, max_height = MAX_HEIGHT };

            Gdk.Pixbuf pixbuf;
            try {
                pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
            } catch (Error error) {
                warning("Can't load picture %s - %s", file.get_path(), error.message);
                Idle.add(get_image_widget.callback);
                return null;
            }

            pixbuf = pixbuf.apply_embedded_orientation();

            image.load(pixbuf);

            Idle.add(get_image_widget.callback);
            return image;
        });
        yield;
        Image image = thread.join();
        if (image == null) return null;

        Util.force_css(image, "* { box-shadow: 0px 0px 2px 0px rgba(0,0,0,0.1); margin: 2px; border-radius: 3px; }");

        Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_content_view/image_toolbar.ui");
        Widget toolbar = builder.get_object("main") as Widget;
        Util.force_background(toolbar, "rgba(0, 0, 0, 0.5)");
        Util.force_css(toolbar, "* { padding: 3px; border-radius: 3px; }");

        Label url_label = builder.get_object("url_label") as Label;
        Util.force_color(url_label, "#eee");

        if (file_name != null && file_name != "") {
            string caption = file_name;
            url_label.label = caption;
        } else {
            url_label.visible = false;
        }

        Image open_image = builder.get_object("open_image") as Image;
        Util.force_css(open_image, "*:not(:hover) { color: #eee; }");
        Button open_button = builder.get_object("open_button") as Button;
        Util.force_css(open_button, "*:hover { background-color: rgba(255,255,255,0.3); border-color: transparent; }");
        open_button.clicked.connect(() => {
            try{
                AppInfo.launch_default_for_uri(file.get_uri(), null);
            } catch (Error err) {
                info("Could not to open file://%s: %s", file.get_path(), err.message);
            }
        });

        Revealer toolbar_revealer = new Revealer() { transition_type=RevealerTransitionType.CROSSFADE, transition_duration=400, visible=true };
        toolbar_revealer.add(toolbar);

        Grid grid = new Grid() { visible=true };
        grid.attach(toolbar_revealer, 0, 0, 1, 1);
        grid.attach(image, 0, 0, 1, 1);

        EventBox event_box = new EventBox() { margin_top=5, halign=Align.START, visible=true };
        event_box.events = EventMask.POINTER_MOTION_MASK;
        event_box.add(grid);
        event_box.enter_notify_event.connect(() => { toolbar_revealer.reveal_child = true; return false; });
        event_box.leave_notify_event.connect(() => { toolbar_revealer.reveal_child = false; return false; });

        return event_box;
    }

    private bool show_image() {
        if (file_transfer.mime_type == null || file_transfer.state != FileTransfer.State.COMPLETE) return false;

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
    private FileTransfer file_transfer;
    private StreamInteractor stream_interactor;

    public FileDefaultWidgetController(FileDefaultWidget widget, FileTransfer file_transfer, StreamInteractor stream_interactor) {
        this.widget = widget;
        this.file_transfer = file_transfer;
        this.stream_interactor = stream_interactor;

        widget.name_label.label = file_transfer.file_name;

        widget.button_release_event.connect(on_clicked);

        file_transfer.notify["path"].connect(update_file_info);
        file_transfer.notify["state"].connect(update_file_info);
        file_transfer.notify["mime-type"].connect(update_file_info);

        update_file_info();
    }

    private void update_file_info() {
        widget.update_file_info(file_transfer.mime_type, file_transfer.state, file_transfer.size);
    }

    private bool on_clicked(EventButton event_button) {
        switch (file_transfer.state) {
            case FileTransfer.State.COMPLETE:
                if (event_button.button == 1) {
                    try{
                        AppInfo.launch_default_for_uri(file_transfer.get_file().get_uri(), null);
                    } catch (Error err) {
                        print("Tried to open " + file_transfer.get_file().get_path());
                    }
                }
                break;
            case FileTransfer.State.NOT_STARTED:
                stream_interactor.get_module(FileManager.IDENTITY).download_file.begin(file_transfer);
                break;
        }
        return false;
    }
}

}
