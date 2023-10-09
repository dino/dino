using Gee;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.Util {

public static ViewModel.PreferencesRow.Any? get_data_form_field_view_model(DataForms.DataForm.Field field) {
    if (field.type_ == null) return null;

    ViewModel.PreferencesRow.Any? view_model = null;

    string? label = null;
    string? desc = null;

    if (field.var != null) {
        switch (field.var) {
            case "muc#roomconfig_roomname":
                label = _("Name of the room");
                break;
            case "muc#roomconfig_roomdesc":
                label = _("Description of the room");
                break;
            case "muc#roomconfig_persistentroom":
                label = _("Persistent");
                desc = _("The room will persist after the last occupant leaves");
                break;
            case "muc#roomconfig_publicroom":
                label = _("Publicly searchable");
                break;
            case "muc#roomconfig_changesubject":
                label = _("Occupants may change the subject");
                break;
            case "muc#roomconfig_whois":
                label = _("Permission to view JIDs");
                desc = _("Who is allowed to view the occupants' JIDs?");
                break;
            case "muc#roomconfig_roomsecret":
                label = _("Password");
//                desc = _("A password to restrict access to the room");
                break;
            case "muc#roomconfig_moderatedroom":
                label = _("Moderated");
                desc = _("Only occupants with voice may send messages");
                break;
            case "muc#roomconfig_membersonly":
                label = _("Members only");
                desc = _("Only members may enter the room");
                break;
//            case "muc#roomconfig_historylength":
//                label = _("Message history");
//                desc = _("Maximum amount of backlog issued by the room");
//                break;
        }
    }

    if (label == null) label = field.label;

    switch (field.type_) {
        case DataForms.DataForm.Type.BOOLEAN:
            DataForms.DataForm.BooleanField boolean_field = field as DataForms.DataForm.BooleanField;
            var toggle_model = new ViewModel.PreferencesRow.Toggle() { subtitle = desc, state = boolean_field.value };
            boolean_field.bind_property("value", toggle_model, "state", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            view_model = toggle_model;
            break;
        case DataForms.DataForm.Type.JID_MULTI:
            return null;
        case DataForms.DataForm.Type.LIST_SINGLE:
            DataForms.DataForm.ListSingleField list_single_field = field as DataForms.DataForm.ListSingleField;
            var combobox_model = new ViewModel.PreferencesRow.ComboBox();
            for (int i = 0; i < list_single_field.options.size; i++) {
                DataForms.DataForm.Option option = list_single_field.options[i];
                combobox_model.items.add(option.label);
                if (option.value == list_single_field.value) combobox_model.active_item = i;
            }
            combobox_model.bind_property("active-item", list_single_field, "value", BindingFlags.DEFAULT, (binding, from, ref to) => {
                var active_item = (int) from;
                to = list_single_field.options[active_item].value;
                return true;
            });
            view_model = combobox_model;
            break;
        case DataForms.DataForm.Type.LIST_MULTI:
            return null;
        case DataForms.DataForm.Type.TEXT_PRIVATE:
            return null;
        case DataForms.DataForm.Type.TEXT_SINGLE:
            DataForms.DataForm.TextSingleField text_single_field = field as DataForms.DataForm.TextSingleField;
            var entry_model = new ViewModel.PreferencesRow.Entry() { text = text_single_field.value };
            text_single_field.bind_property("value", entry_model, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            view_model = entry_model;
            break;
        default:
            return null;
    }

    view_model.title = label;
    return view_model;
}

public static Widget? get_data_form_field_widget(DataForms.DataForm.Field field) {
    if (field.type_ == null) return null;
    switch (field.type_) {
        case DataForms.DataForm.Type.BOOLEAN:
            DataForms.DataForm.BooleanField boolean_field = field as DataForms.DataForm.BooleanField;
            Switch sw = new Switch() { active=boolean_field.value, halign=Align.START, valign=Align.CENTER };
            sw.state_set.connect((state) => {
                boolean_field.value = state;
                return false;
            });
            return sw;
        case DataForms.DataForm.Type.JID_MULTI:
            return null;
        case DataForms.DataForm.Type.LIST_SINGLE:
            DataForms.DataForm.ListSingleField list_single_field = field as DataForms.DataForm.ListSingleField;
            ComboBoxText combobox = new ComboBoxText() { valign=Align.CENTER };
            for (int i = 0; i < list_single_field.options.size; i++) {
                DataForms.DataForm.Option option = list_single_field.options[i];
                combobox.append(option.value, option.label);
                if (option.value == list_single_field.value) combobox.active = i;
            }
            combobox.changed.connect(() => {
                list_single_field.value = combobox.get_active_id();
            });
            return combobox;
        case DataForms.DataForm.Type.LIST_MULTI:
            return null;
        case DataForms.DataForm.Type.TEXT_PRIVATE:
            DataForms.DataForm.TextPrivateField text_private_field = field as DataForms.DataForm.TextPrivateField;
            PasswordEntry entry = new PasswordEntry() { text=text_private_field.value ?? "", valign=Align.CENTER };
            entry.changed.connect(() => { text_private_field.value = entry.text; });
            return entry;
        case DataForms.DataForm.Type.TEXT_SINGLE:
            DataForms.DataForm.TextSingleField text_single_field = field as DataForms.DataForm.TextSingleField;
            Entry entry = new Entry() { text=text_single_field.value ?? "", valign=Align.CENTER };
            entry.changed.connect(() => { text_single_field.value = entry.text; });
            return entry;
        default:
            return null;
    }
}

}
