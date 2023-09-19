using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class FileImageWidget : Box {

    Gtk.Box image_overlay_toolbar;
    MenuButton button;
    GestureClick gesture_click_controller;

    public FileImageWidget() {
        this.halign = Align.START;

        this.add_css_class("file-image-widget");
        this.set_cursor_from_name("zoom-in");
    }

    private void mouse_on_enter() {
        image_overlay_toolbar.visible = true;
    }

    private void mouse_on_leave() {
        if (button.popover != null && button.popover.visible) return;

        image_overlay_toolbar.visible = false;
    }

    private void on_click_release(int n_press, double x, double y) {
        switch (gesture_click_controller.get_device().source) {
            case Gdk.InputSource.TOUCHSCREEN:
            case Gdk.InputSource.PEN:
                if (n_press == 1) {
                    image_overlay_toolbar.visible = !image_overlay_toolbar.visible;
                } else if (n_press == 2) {
                    this.activate_action("file.open", null);
                    image_overlay_toolbar.visible = false;
                }
                break;
            default:
                this.activate_action("file.open", null);
                image_overlay_toolbar.visible = false;
                break;
        }
    }

    public async void load_from_file(File file, string file_name, int MAX_WIDTH=600, int MAX_HEIGHT=300) throws GLib.Error {
        image_overlay_toolbar = new Gtk.Box(Orientation.HORIZONTAL, 0) { halign=Gtk.Align.END, valign=Gtk.Align.START, margin_top=10, margin_start=10, margin_end=10, margin_bottom=10, vexpand=false, visible=false };
        image_overlay_toolbar.add_css_class("card");
        image_overlay_toolbar.add_css_class("toolbar");
        image_overlay_toolbar.add_css_class("overlay-toolbar");
        image_overlay_toolbar.set_cursor_from_name("default");

        FixedRatioPicture image = new FixedRatioPicture() { min_width=100, min_height=100, max_width=MAX_WIDTH, max_height=MAX_HEIGHT, file=file };
        gesture_click_controller = new GestureClick();
        gesture_click_controller.button = 1; // listen for left clicks
        gesture_click_controller.released.connect(on_click_release);
        image.add_controller(gesture_click_controller);

        FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        string? mime_type = file_info.get_content_type();

        button = new MenuButton();
        button.icon_name = "open-menu";
        Menu menu_model = new Menu();
        menu_model.append(_("Open"), "file.open");
        menu_model.append(_("Save as…"), "file.save_as");
        Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
        button.popover = popover_menu;

        image_overlay_toolbar.append(button);

        Overlay overlay = new Overlay();
        overlay.set_child(image);
        overlay.add_overlay(image_overlay_toolbar);
        overlay.set_measure_overlay(image, true);
        overlay.set_clip_overlay(image_overlay_toolbar, true);

        EventControllerMotion this_motion_events = new EventControllerMotion();
        this.add_controller(this_motion_events);
        this_motion_events.enter.connect(mouse_on_enter);
        this_motion_events.leave.connect(mouse_on_leave);

        this.append(overlay);
    }
}

}
