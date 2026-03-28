using Gee;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.Util {
    public static GLib.ListStore get_data_form_view_model(DataForms.DataForm data_form) {
        var list_store = new GLib.ListStore(typeof(ViewModel.PreferencesRow.Any));

        foreach (var field in data_form.fields) {
            var field_view_model = Util.get_data_form_field_view_model(field);
            if (field_view_model != null) {
                list_store.append(field_view_model);
            }
        }
        return list_store;
    }

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
        case DataForms.DataForm.Type.FIXED:
            var fixed_field = field as DataForms.DataForm.FixedField;
            var fixed_model = new ViewModel.PreferencesRow.Text() { text=fixed_field.value };
            view_model = fixed_model;
            break;
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
            DataForms.DataForm.TextPrivateField text_private_field = field as DataForms.DataForm.TextPrivateField;
            var private_entry_model = new ViewModel.PreferencesRow.PrivateText() { text = text_private_field.value };
            text_private_field.bind_property("value", private_entry_model, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            view_model = private_entry_model;
            break;
        case DataForms.DataForm.Type.TEXT_SINGLE:
            DataForms.DataForm.TextSingleField text_single_field = field as DataForms.DataForm.TextSingleField;
            var entry_model = new ViewModel.PreferencesRow.Entry() { text = text_single_field.value };
            text_single_field.bind_property("value", entry_model, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            view_model = entry_model;
            break;
        default:
            return null;
    }

    var media_node = field.node.get_subnode("media", "urn:xmpp:media-element");
    if (media_node != null) {
        view_model.media_type = media_node.get_attribute("type", "urn:xmpp:media-element");
        view_model.media_uri = media_node.get_deep_string_content("uri");
    }

    view_model.title = label;
    return view_model;
}
}
