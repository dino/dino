using Gee;
using Gtk;
using Dino.Entities;

public class Dino.Ui.AudioSettingsPopover : Gtk.Popover {

    public signal void microphone_selected(Plugins.MediaDevice device);
    public signal void speaker_selected(Plugins.MediaDevice device);

    public Plugins.MediaDevice? current_microphone_device { get; set; }
    public Plugins.MediaDevice? current_speaker_device { get; set; }

    private HashMap<ListBoxRow, Plugins.MediaDevice> row_microphone_device = new HashMap<ListBoxRow, Plugins.MediaDevice>();
    private HashMap<ListBoxRow, Plugins.MediaDevice> row_speaker_device = new HashMap<ListBoxRow, Plugins.MediaDevice>();

    public AudioSettingsPopover() {
        Box box = new Box(Orientation.VERTICAL, 15) { margin=18, visible=true };
        box.add(create_microphone_box());
        box.add(create_speaker_box());

        this.add(box);
    }

    private Widget create_microphone_box() {
        Plugins.VideoCallPlugin call_plugin = Dino.Application.get_default().plugin_registry.video_call_plugin;
        Gee.List<Plugins.MediaDevice> devices = call_plugin.get_devices("audio", false);

        Box micro_box = new Box(Orientation.VERTICAL, 10) { visible=true };
        micro_box.add(new Label("<b>" + _("Microphones") + "</b>") { use_markup=true, xalign=0, visible=true, can_focus=true /* grab initial focus*/ });

        if (devices.size == 0) {
            micro_box.add(new Label(_("No microphones found.")));
        } else {
            ListBox micro_list_box = new ListBox() { activate_on_single_click=true, selection_mode=SelectionMode.SINGLE, visible=true };
            micro_list_box.set_header_func(listbox_header_func);
            Frame micro_frame = new Frame(null) { visible=true };
            micro_frame.add(micro_list_box);
            foreach (Plugins.MediaDevice device in devices) {
                Label display_name_label = new Label(device.display_name) { xalign=0, visible=true };
                Label detail_name_label = new Label(device.detail_name) { xalign=0, visible=true };
                detail_name_label.get_style_context().add_class("dim-label");
                detail_name_label.attributes = new Pango.AttrList();
                detail_name_label.attributes.insert(Pango.attr_scale_new(0.8));
                Image image = new Image.from_icon_name("object-select-symbolic", IconSize.BUTTON) { visible=true };
                if (current_microphone_device == null || current_microphone_device.id != device.id) {
                    image.opacity = 0;
                }
                this.notify["current-microphone-device"].connect(() => {
                    if (current_microphone_device == null || current_microphone_device.id != device.id) {
                        image.opacity = 0;
                    } else {
                        image.opacity = 1;
                    }
                });
                Box device_box = new Box(Orientation.HORIZONTAL, 0) { spacing=7, margin=7, visible=true };
                device_box.add(image);
                Box label_box = new Box(Orientation.VERTICAL, 0) { visible = true };
                label_box.add(display_name_label);
                label_box.add(detail_name_label);
                device_box.add(label_box);
                ListBoxRow list_box_row = new ListBoxRow() { visible=true };
                list_box_row.add(device_box);
                micro_list_box.add(list_box_row);

                row_microphone_device[list_box_row] = device;
            }
            micro_list_box.row_activated.connect((row) => {
                if (!row_microphone_device.has_key(row)) return;
                microphone_selected(row_microphone_device[row]);
                micro_list_box.unselect_row(row);
            });
            micro_box.add(micro_frame);
        }

        return micro_box;
    }

    private Widget create_speaker_box() {
        Plugins.VideoCallPlugin call_plugin = Dino.Application.get_default().plugin_registry.video_call_plugin;
        Gee.List<Plugins.MediaDevice> devices = call_plugin.get_devices("audio", true);

        Box speaker_box = new Box(Orientation.VERTICAL, 10) { visible=true };
        speaker_box.add(new Label("<b>" + _("Speakers") +"</b>") { use_markup=true, xalign=0, visible=true });

        if (devices.size == 0) {
            speaker_box.add(new Label(_("No speakers found.")));
        } else {
            ListBox speaker_list_box = new ListBox() { activate_on_single_click=true, selection_mode=SelectionMode.SINGLE, visible=true };
            speaker_list_box.set_header_func(listbox_header_func);
            speaker_list_box.row_selected.connect((row) => {

            });
            Frame speaker_frame = new Frame(null) { visible=true };
            speaker_frame.add(speaker_list_box);
            foreach (Plugins.MediaDevice device in devices) {
                Label display_name_label = new Label(device.display_name) { xalign=0, visible=true };
                Label detail_name_label = new Label(device.detail_name) { xalign=0, visible=true };
                detail_name_label.get_style_context().add_class("dim-label");
                detail_name_label.attributes = new Pango.AttrList();
                detail_name_label.attributes.insert(Pango.attr_scale_new(0.8));
                Image image = new Image.from_icon_name("object-select-symbolic", IconSize.BUTTON) { visible=true };
                if (current_speaker_device == null || current_speaker_device.id != device.id) {
                    image.opacity = 0;
                }
                this.notify["current-speaker-device"].connect(() => {
                    if (current_speaker_device == null || current_speaker_device.id != device.id) {
                        image.opacity = 0;
                    } else {
                        image.opacity = 1;
                    }
                });
                Box device_box = new Box(Orientation.HORIZONTAL, 0) { spacing=7, margin=7, visible=true };
                device_box.add(image);
                Box label_box = new Box(Orientation.VERTICAL, 0) { visible = true };
                label_box.add(display_name_label);
                label_box.add(detail_name_label);
                device_box.add(label_box);
                ListBoxRow list_box_row = new ListBoxRow() { visible=true };
                list_box_row.add(device_box);
                speaker_list_box.add(list_box_row);

                row_speaker_device[list_box_row] = device;
            }
            speaker_list_box.row_activated.connect((row) => {
                if (!row_speaker_device.has_key(row)) return;
                speaker_selected(row_speaker_device[row]);
                speaker_list_box.unselect_row(row);
            });
            speaker_box.add(speaker_frame);
        }

        return speaker_box;
    }

    private void listbox_header_func(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

}