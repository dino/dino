using Gee;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.Util {

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
