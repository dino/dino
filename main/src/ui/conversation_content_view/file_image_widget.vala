using Gee;
using Gdk;
using Gtk;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui {

public class FileImageWidget : Widget {
    enum State {
        EMPTY,
        PREVIEW,
        IMAGE
    }
    private State state = State.EMPTY;

    private Stack stack = new Stack() { transition_duration=600, transition_type=StackTransitionType.CROSSFADE, hhomogeneous = false, vhomogeneous = false, interpolate_size = true };
    private Overlay overlay = new Overlay();

    private bool show_image_overlay_toolbar = false;
    private Gtk.Box image_overlay_toolbar = new Gtk.Box(Orientation.VERTICAL, 0) { halign=Align.END, valign=Align.START, margin_top=10, margin_start=10, margin_end=10, margin_bottom=10, vexpand=false, visible=false };
    private Label file_size_label = new Label(null) { halign=Align.START, valign=Align.END, margin_bottom=4, margin_start=4, visible=false };

    private int size = -1;

    private FileTransfer file_transfer;

    private FileTransmissionProgress transmission_progress = new FileTransmissionProgress() { halign=Align.CENTER, valign=Align.CENTER, visible=false };

    construct {
        layout_manager = new BinLayout();
        check_widget_leak(this);
    }

    public FileImageWidget(int MAX_WIDTH=600, int MAX_HEIGHT=300) {
        this.halign = Align.START;

        file_size_label.add_css_class("file-details");

        overlay.set_child(stack);
        overlay.set_measure_overlay(stack, true);
        overlay.add_overlay(file_size_label);
        overlay.add_overlay(transmission_progress);
        overlay.add_overlay(image_overlay_toolbar);
        overlay.set_clip_overlay(image_overlay_toolbar, true);

        overlay.insert_after(this, null);

        GestureClick gesture_click_controller = new GestureClick();
        gesture_click_controller.button = 1; // listen for left clicks
        gesture_click_controller.released.connect(on_image_clicked);
        stack.add_controller(gesture_click_controller);
    }

    public FileImageWidget.from_file_transfer(FileTransfer file_transfer, int size = -1) {
        this();

        this.file_transfer = file_transfer;
        this.size = size;

        this.file_transfer.bind_property("size", file_size_label, "label", BindingFlags.SYNC_CREATE, file_size_label_transform);
        this.file_transfer.bind_property("size", transmission_progress, "file-size", BindingFlags.SYNC_CREATE);
        this.file_transfer.bind_property("transferred-bytes", transmission_progress, "transferred-size");

        setup_signals(transmission_progress, file_transfer);
        setup_menu_button();

        file_transfer.notify["state"].connect(refresh_state);
        file_transfer.sources_changed.connect(refresh_state);
        refresh_state();
    }

    private static void setup_signals(FileTransmissionProgress transmission_progress, FileTransfer file_transfer) {
        var file_transfer_id = file_transfer.id;

        transmission_progress.start_download.connect(() => {
            Dino.Application.get_default().activate_action("file_start_download", new Variant.int32(file_transfer_id));
        });
        transmission_progress.cancel_transfer.connect(() => {
            Dino.Application.get_default().activate_action("file_cancel_transfer", new Variant.int32(file_transfer_id));
        });
    }

    private void setup_menu_button() {
        MenuButton button = new MenuButton();
        button.icon_name = "dino-view-more";
        Menu menu_model = new Menu();

        MenuItem open_file_item = new MenuItem(_("Open"), "app.file_open_externally");
        open_file_item.set_action_and_target_value("app.file_open_externally", new Variant.int32(file_transfer.id));

        MenuItem save_as_item = new MenuItem(_("Save as…"), "app.file_save_as");
        save_as_item.set_action_and_target_value("app.file_open_save_dialog", new Variant.int32(file_transfer.id));

        menu_model.append_item(open_file_item);
        menu_model.append_item(save_as_item);

        Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
        button.popover = popover_menu;
        image_overlay_toolbar.append(button);
        image_overlay_toolbar.add_css_class("card");
        image_overlay_toolbar.add_css_class("toolbar");
        image_overlay_toolbar.add_css_class("compact-card-toolbar");
        image_overlay_toolbar.set_cursor_from_name("default");

        EventControllerMotion this_motion_events = new EventControllerMotion();
        this.add_controller(this_motion_events);
        this_motion_events.enter.connect((controller, x, y) => {
            (controller.widget as FileImageWidget).on_motion_event_enter();
        });

        attach_on_motion_event_leave(this_motion_events, button);
    }

    private static void attach_on_motion_event_leave(EventControllerMotion this_motion_events, MenuButton button) {
        this_motion_events.leave.connect((controller) => {
            if (button.popover != null && button.popover.visible) return;

            (controller.widget as FileImageWidget).image_overlay_toolbar.visible = false;
            (controller.widget as FileImageWidget).file_size_label.visible = false;
        });
    }

    private void on_motion_event_enter() {
        image_overlay_toolbar.visible = show_image_overlay_toolbar;
        file_size_label.visible = file_transfer != null && file_transfer.direction == FileTransfer.DIRECTION_RECEIVED && file_transfer.state == FileTransfer.State.NOT_STARTED && !file_transfer.sfs_sources.is_empty;
    }

    private static bool file_size_label_transform(Binding binding, Value from_value, ref Value to_value) {
        to_value = FileDefaultWidget.get_size_string((int64) from_value);
        return true;
    }

    private void refresh_state() {
        if ((state == EMPTY || state == PREVIEW) && file_transfer.path != null) {
            load_from_file.begin(file_transfer.get_file(), file_transfer.file_name);
            show_image_overlay_toolbar = true;
            this.set_cursor_from_name("zoom-in");

            state = IMAGE;
        } else if (state == EMPTY && file_transfer.thumbnails.size > 0) {
            load_from_thumbnail.begin(file_transfer);

            transmission_progress.visible = true;
            show_image_overlay_toolbar = false;

            state = PREVIEW;
        }

        if (file_transfer.state == IN_PROGRESS || file_transfer.state == NOT_STARTED || file_transfer.state == FAILED) {
            transmission_progress.visible = true;
            show_image_overlay_toolbar = false;
        } else if (transmission_progress.visible) {
            Timeout.add(250, () => {
                transmission_progress.transferred_size = transmission_progress.file_size;
                transmission_progress.visible = false;
                show_image_overlay_toolbar = true;
                return false;
            });
        }

        if (file_transfer.direction == FileTransfer.DIRECTION_RECEIVED) {
            if (file_transfer.state == IN_PROGRESS) {
                transmission_progress.state = DOWNLOADING;
            } else if (file_transfer.sfs_sources.is_empty) {
                transmission_progress.state = UNKNOWN_SOURCE;
            } else if (file_transfer.state == NOT_STARTED) {
                transmission_progress.state = DOWNLOAD_NOT_STARTED;
            } else if (file_transfer.state == FAILED) {
                transmission_progress.state = DOWNLOAD_NOT_STARTED_FAILED_BEFORE;
            }
        } else if (file_transfer.direction == FileTransfer.DIRECTION_SENT) {
            if (file_transfer.state == IN_PROGRESS) {
                transmission_progress.state = UPLOADING;
            } else if (file_transfer.state == FAILED) {
                transmission_progress.state = UPLOAD_FAILED;
            }
        }
    }

    public async void load_from_file(File file, string file_name) throws GLib.Error {
        FixedRatioPicture image = create_picture();

        FileInputStream file_stream = null;
        try {
            file_stream = file.read();
            // Work-around because Gtk.Picture does not apply the orientation itself
            Gdk.Pixbuf? pixbuf = new Pixbuf.from_stream(file_stream);
            pixbuf = pixbuf.apply_embedded_orientation();
            image.paintable = Texture.for_pixbuf(pixbuf);
        } finally {
            try {
                if (file_stream != null) file_stream.close();
            } catch (Error e) {
                // Ignore
            }
        }

        stack.add_child(image);
        stack.set_visible_child(image);
    }

    public async void load_from_thumbnail(FileTransfer file_transfer) throws GLib.Error {
        this.file_transfer = file_transfer;

        Gdk.Pixbuf? pixbuf = null;
        foreach (Xep.JingleContentThumbnails.Thumbnail thumbnail in file_transfer.thumbnails) {
            pixbuf = parse_thumbnail(thumbnail);
            if (pixbuf != null) {
                break;
            }
        }
        if (pixbuf == null) {
            warning("Can't load thumbnails of file %s", file_transfer.file_name);
            throw new Error(-1, 0, "Error loading preview image");
        }
        // TODO: should this be executed? If yes, before or after scaling
        pixbuf = pixbuf.apply_embedded_orientation();

        if (file_transfer.width > 0 && file_transfer.height > 0) {
            pixbuf = pixbuf.scale_simple(file_transfer.width, file_transfer.height, InterpType.BILINEAR);
        } else {
            warning("Preview: Not scaling image, width: %d, height: %d\n", file_transfer.width, file_transfer.height);
        }
        if (pixbuf == null) {
            warning("Can't scale thumbnail %s", file_transfer.file_name);
            throw new Error(-1, 0, "Error scaling preview image");
        }

        FixedRatioPicture image = create_picture();
        image.paintable = Texture.for_pixbuf(pixbuf);
        stack.add_child(image);
        stack.set_visible_child(image);
    }

    public void on_image_clicked(GestureClick gesture_click_controller, int n_press, double x, double y) {
        if (this.file_transfer.state != COMPLETE) return;

        switch (gesture_click_controller.get_device().source) {
            case Gdk.InputSource.TOUCHSCREEN:
            case Gdk.InputSource.PEN:
                if (n_press == 1) {
                    image_overlay_toolbar.visible = !image_overlay_toolbar.visible;
                } else if (n_press == 2) {
                    Dino.Application.get_default().activate_action("file_open_externally", new Variant.int32(file_transfer.id));
                    image_overlay_toolbar.visible = false;
                }
                break;
            default:
                Dino.Application.get_default().activate_action("file_open_externally", new Variant.int32(file_transfer.id));
                image_overlay_toolbar.visible = false;
                break;
        }
    }

    public static Pixbuf? parse_thumbnail(Xep.JingleContentThumbnails.Thumbnail thumbnail) {
        MemoryInputStream input_stream = new MemoryInputStream.from_data(thumbnail.data.get_data());
        return new Pixbuf.from_stream(input_stream);
    }

    public static bool can_display(FileTransfer file_transfer) {
        return file_transfer.content_type != null && Dino.Util.is_pixbuf_supported_content_type(file_transfer.content_type) &&
                (file_transfer.state == FileTransfer.State.COMPLETE || file_transfer.thumbnails.size > 0);
    }

    private FixedRatioPicture create_picture() {
        if (size == -1) {
            return new FixedRatioPicture() {
                min_width=100, max_width=600,
                min_height=100, max_height=300
            };
        } else {
            return new FixedRatioPicture() {
                height_request = size, width_request = size,
                content_fit = ContentFit.COVER, halign = Align.START
            };
        }
    }

    public override void dispose() {
        if (overlay != null && overlay.parent != null) overlay.unparent();
        base.dispose();
    }
}

}
