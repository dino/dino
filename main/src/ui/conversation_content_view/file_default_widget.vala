using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_default_widget.ui")]
public class FileDefaultWidget : EventBox {

    [GtkChild] public unowned Stack image_stack;
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label mime_label;
    [GtkChild] public unowned Image content_type_image;
    [GtkChild] public unowned Spinner spinner;
    [GtkChild] public unowned EventBox stack_event_box;
    [GtkChild] public unowned MenuButton file_menu;

    public ModelButton file_open_button;
    public ModelButton file_save_button;

    private FileTransfer.State state;

    public FileDefaultWidget() {
        this.enter_notify_event.connect(on_pointer_entered_event);
        this.leave_notify_event.connect(on_pointer_left_event);
        file_open_button = new ModelButton() { text=_("Open"), visible=true };
        file_save_button = new ModelButton() { text=_("Save as…"), visible=true };
    }

    public void update_file_info(string? mime_type, FileTransfer.State state, long size) {
        this.state = state;

        spinner.active = false; // A hidden spinning spinner still uses CPU. Deactivate asap

        content_type_image.icon_name = get_file_icon_name(mime_type);
        string? mime_description = mime_type != null ? ContentType.get_description(mime_type) : null;

        switch (state) {
            case FileTransfer.State.COMPLETE:
                mime_label.label = mime_description;
                image_stack.set_visible_child_name("content_type_image");

                // Create a menu
                Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu();
                Box file_menu_box = new Box(Orientation.VERTICAL, 0) { margin=10, visible=true };
                file_menu_box.add(file_open_button);
                file_menu_box.add(file_save_button);
                popover_menu.add(file_menu_box);
                file_menu.popover = popover_menu;
                file_menu.button_release_event.connect(() => {
                    popover_menu.visible = true;
                    return true;
                });
                popover_menu.closed.connect(on_pointer_left);
                break;
            case FileTransfer.State.IN_PROGRESS:
                mime_label.label = _("Downloading %s…").printf(get_size_string(size));
                spinner.active = true;
                image_stack.set_visible_child_name("spinner");
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

    private bool on_pointer_entered_event(Gdk.EventCrossing event) {
        event.get_window().set_cursor(new Cursor.for_display(Gdk.Display.get_default(), CursorType.HAND2));
        content_type_image.opacity = 0.7;
        if (state == FileTransfer.State.NOT_STARTED) {
            image_stack.set_visible_child_name("download_image");
        }
        if (state == FileTransfer.State.COMPLETE) {
            file_menu.opacity = 1;
        }
        return false;
    }

    private bool on_pointer_left_event(Gdk.EventCrossing event) {
        if (event.detail == Gdk.NotifyType.INFERIOR) return false;
        if (file_menu.popover != null && file_menu.popover.visible) return false;

        event.get_window().set_cursor(new Cursor.for_display(Gdk.Display.get_default(), CursorType.XTERM));
        on_pointer_left();
        return false;
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
