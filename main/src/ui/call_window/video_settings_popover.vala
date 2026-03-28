using Gee;
using Gtk;
using Dino.Entities;

public class Dino.Ui.VideoSettingsPopover : Gtk.Popover {

    public signal void camera_selected(Plugins.MediaDevice device);

    public Plugins.MediaDevice? current_device { get; set; }

    private HashMap<ListBoxRow, Plugins.MediaDevice> row_device = new HashMap<ListBoxRow, Plugins.MediaDevice>();

    public VideoSettingsPopover() {
        Box box = new Box(Orientation.VERTICAL, 15);
        box.append(create_camera_box());

        this.set_child(box);
    }

    private Widget create_camera_box() {
        Plugins.VideoCallPlugin call_plugin = Dino.Application.get_default().plugin_registry.video_call_plugin;
        Gee.List<Plugins.MediaDevice> devices = call_plugin.get_devices("video", false);

        Box camera_box = new Box(Orientation.VERTICAL, 10);
        camera_box.append(new Label("<b>" + _("Cameras") + "</b>") { use_markup=true, xalign=0, can_focus=true /* grab initial focus*/ });

        if (devices.size == 0) {
            camera_box.append(new Label(_("No camera found.")));
        } else {
            ListBox list_box = new ListBox() { activate_on_single_click=true, selection_mode=SelectionMode.SINGLE };
            list_box.set_header_func(listbox_header_func);
            Frame frame = new Frame(null);
            frame.set_child(list_box);
            foreach (Plugins.MediaDevice device in devices) {
                Label display_name_label = new Label(device.display_name) { xalign=0 };
                Image image = new Image.from_icon_name("object-select-symbolic");
                if (current_device == null || current_device.id != device.id) {
                    image.opacity = 0;
                }
                this.notify["current-device"].connect(() => {
                    if (current_device == null || current_device.id != device.id) {
                        image.opacity = 0;
                    } else {
                        image.opacity = 1;
                    }
                });
                Box device_box = new Box(Orientation.HORIZONTAL, 0) { spacing=7 };
                device_box.append(image);
                Box label_box = new Box(Orientation.VERTICAL, 0) { visible = true };
                label_box.append(display_name_label);
                if (device.detail_name != null) {
                    Label detail_name_label = new Label(device.detail_name) { xalign=0 };
                    detail_name_label.add_css_class("dim-label");
                    detail_name_label.attributes = new Pango.AttrList();
                    detail_name_label.attributes.insert(Pango.attr_scale_new(0.8));
                    label_box.append(detail_name_label);
                }
                device_box.append(label_box);
                ListBoxRow list_box_row = new ListBoxRow();
                list_box_row.set_child(device_box);
                list_box.append(list_box_row);

                row_device[list_box_row] = device;
            }
            list_box.row_activated.connect((row) => {
                if (!row_device.has_key(row)) return;
                camera_selected(row_device[row]);
                list_box.unselect_row(row);
            });
            camera_box.append(frame);
        }

        return camera_box;
    }

    private void listbox_header_func(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

}