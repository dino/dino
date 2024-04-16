using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_default_widget.ui")]
public class FileDefaultWidget : Box {

    public signal void clicked();

    [GtkChild] public unowned Stack image_stack;
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label mime_label;
    [GtkChild] public unowned Image content_type_image;
    [GtkChild] public unowned Spinner spinner;
    [GtkChild] public unowned MenuButton file_menu;

    private FileTransfer.State state;

    public FileDefaultWidget() {
        EventControllerMotion this_motion_events = new EventControllerMotion();
        this.add_controller(this_motion_events);
        this_motion_events.enter.connect(on_pointer_entered_event);
        this_motion_events.leave.connect(on_pointer_left_event);

        GestureClick gesture_click_controller = new GestureClick();
        gesture_click_controller.set_button(1); // listen for left clicks
        this.add_controller(gesture_click_controller);
        gesture_click_controller.pressed.connect((n_press, x, y) => {
            // Check whether the click was inside the file menu. Otherwise, open the file.
            double x_button, y_button;
            this.translate_coordinates(file_menu, x, y, out x_button, out y_button);
            if (file_menu.contains(x_button, y_button)) return;

            this.clicked();
        });
    }

    public void update_file_info(string? mime_type, uint64 transferred_bytes,
        bool direction, FileTransfer.State state, long size) {
        this.state = state;

        spinner.stop(); // A hidden spinning spinner still uses CPU. Deactivate asap

        content_type_image.icon_name = get_file_icon_name(mime_type);
        string? mime_description = mime_type != null ? ContentType.get_description(mime_type) : null;

        switch (state) {
            case FileTransfer.State.COMPLETE:
                mime_label.label = _("%s offered: %s").printf(mime_description, get_size_string(size));
                image_stack.set_visible_child_name("content_type_image");

                // Create a menu
                Menu menu_model = new Menu();
                menu_model.append(_("Open"), "file.open");
                menu_model.append(_("Save as…"), "file.save_as");
                Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
                file_menu.popover = popover_menu;
                popover_menu.closed.connect(on_pointer_left);
                break;
            case FileTransfer.State.IN_PROGRESS:
                uint progress = 0;

                if (size > 0)
                    progress = (uint)((transferred_bytes * (uint64)100) / (uint64)size);

                if (direction == FileTransfer.DIRECTION_SENT) {
                    mime_label.label = _("Uploading %s (%u%%)…").printf(get_size_string(size), progress);
                }
                else {
                    mime_label.label = _("Downloading %s (%u%%)…").printf(get_size_string(size), progress);
                }
                spinner.start();
                image_stack.set_visible_child_name("spinner");

                // Create a menu
                Menu menu_model = new Menu();
                menu_model.append(_("Cancel"), "file.cancel_download");
                Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
                file_menu.popover = popover_menu;
                popover_menu.closed.connect(on_pointer_left);
                break;
            case FileTransfer.State.NOT_STARTED:
                if (mime_description != null) {
                    mime_label.label =  _("%s offered: %s").printf(mime_description, get_size_string(size));
                } else if (size != -1) {
                    mime_label.label = _("File offered: %s").printf(get_size_string(size));
                } else {
                    mime_label.label = _("File offered");
                }
                image_stack.set_visible_child_name("content_type_image");
                break;
            case FileTransfer.State.FAILED:
                mime_label.use_markup = true;
                mime_label.label = "<span foreground=\"#f44336\">" + _("File transfer failed") + "</span>";
                image_stack.set_visible_child_name("content_type_image");
                break;
        }
    }

    private void on_pointer_entered_event() {
        this.set_cursor_from_name("pointer");
        content_type_image.opacity = 0.7;
        if (state == FileTransfer.State.NOT_STARTED) {
            image_stack.set_visible_child_name("download_image");
        }
        if (state == FileTransfer.State.COMPLETE || state == FileTransfer.State.IN_PROGRESS) {
            file_menu.opacity = 1;
        }
    }

    private void on_pointer_left_event() {
        if (file_menu.popover != null && file_menu.popover.visible) return;

        this.set_cursor(null);
        on_pointer_left();
    }

    private void on_pointer_left() {
        content_type_image.opacity = 0.5;
        if (state == FileTransfer.State.NOT_STARTED) {
            image_stack.set_visible_child_name("content_type_image");
        }
        file_menu.opacity = 0;
    }

    private static string get_file_icon_name(string? mime_type) {
        if (mime_type == null) return "dino-file-symbolic";

        string generic_icon_name = ContentType.get_generic_icon_name(mime_type) ?? "";
        switch (generic_icon_name) {
            case "audio-x-generic": return "dino-file-music-symbolic";
            case "image-x-generic": return "dino-file-image-symbolic";
            case "text-x-generic": return "dino-file-document-symbolic";
            case "text-x-generic-template": return "dino-file-document-symbolic";
            case "video-x-generic": return "dino-file-video-symbolic";
            case "x-office-document": return "dino-file-document-symbolic";
            case "x-office-spreadsheet": return "dino-file-table-symbolic";
            default: return "dino-file-symbolic";
        }
    }

    private static string get_size_string(long size) {
        if (size < 1024) {
            return @"$(size) B";
        } else if (size < 1000 * 1000) {
            return @"$(size / 1000) kB";
        } else if (size < 1000 * 1000 * 1000) {
            return @"$(size / 1000  / 1000) MB";
        } else {
            return @"$(size  / 1000  / 1000  / 1000) GB";
        }
    }
}

}
