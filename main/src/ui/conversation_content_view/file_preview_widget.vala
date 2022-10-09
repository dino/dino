using Gee;
using Gdk;
using Gtk;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui {

    public class FilePreviewWidget : Box {

        private ScalingImage image;
        FileDefaultWidget file_default_widget;
        FileDefaultWidgetController file_default_widget_controller;

        public FilePreviewWidget() {
            this.halign = Align.START;

            this.add_css_class("file-preview-widget");
        }

        public async void load_from_thumbnail(FileTransfer file_transfer, StreamInteractor stream_interactor, int MAX_WIDTH=600, int MAX_HEIGHT=300) throws GLib.Error {
            Thread<ScalingImage?> thread = new Thread<ScalingImage?> (null, () => {
                ScalingImage image = new ScalingImage() { halign=Align.START, visible = true, max_width = MAX_WIDTH, max_height = MAX_HEIGHT };
                Gdk.Pixbuf? pixbuf = null;
                foreach (Xep.JingleContentThumbnails.Thumbnail thumbnail in file_transfer.thumbnails) {
                    pixbuf = ImageFileMetadataProvider.parse_thumbnail(thumbnail);
                    if (pixbuf != null) {
                        break;
                    }
                }
                if (pixbuf == null) {
                    warning("Can't load thumbnails of file %s", file_transfer.file_name);
                    Idle.add(load_from_thumbnail.callback);
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

                image.load(pixbuf);
                Idle.add(load_from_thumbnail.callback);
                return image;
            });
            yield;
            this.image = thread.join();

            file_default_widget = new FileDefaultWidget() { valign=Align.END, vexpand=false, visible=false };
            file_default_widget.image_stack.visible = false;
            file_default_widget_controller = new FileDefaultWidgetController(file_default_widget);
            file_default_widget_controller.set_file_transfer(file_transfer, stream_interactor);

            Overlay overlay = new Overlay();
            overlay.set_child(image);
            overlay.add_overlay(file_default_widget);
            overlay.set_measure_overlay(image, true);
            overlay.set_clip_overlay(file_default_widget, true);

            EventControllerMotion this_motion_events = new EventControllerMotion();
            this.add_controller(this_motion_events);
            this_motion_events.enter.connect(() => {
                file_default_widget.visible = true;
            });
            this_motion_events.leave.connect(() => {
                if (file_default_widget.file_menu.popover != null && file_default_widget.file_menu.popover.visible) return;

                file_default_widget.visible = false;
            });
            GestureClick gesture_click_controller = new GestureClick();
            gesture_click_controller.set_button(1); // listen for left clicks
            this.add_controller(gesture_click_controller);
            gesture_click_controller.pressed.connect((n_press, x, y) => {
                // Check whether the click was inside the file menu. Otherwise, open the file.
                this.file_default_widget.clicked();
            });

            this.append(overlay);
        }
    }

}
