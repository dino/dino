using Gee;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.ContactDetails {

public class MucConfigFormProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "muc_config_form"; } }
    private StreamInteractor stream_interactor;

    public MucConfigFormProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK) return;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Xmpp.XmppStream? stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) return;
            stream_interactor.get_module(MucManager.IDENTITY).get_config_form(conversation.account, conversation.counterpart, (jid, data_form) => {
                contact_details.save.connect(() => { data_form.submit(); });
                for (int i = 0; i < data_form.fields.size; i++) {
                    DataForms.DataForm.Field field = data_form.fields[i];
                    add_field(field, contact_details);
                }
            });
        }
    }

    public static void add_field(DataForms.DataForm.Field field, Plugins.ContactDetails contact_details) {
        string label = field.label ?? "";
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
                    label = _("Discover real JIDs");
                    desc = _("Who may discover real JIDs?");
                    break;
                case "muc#roomconfig_roomsecret":
                    label = _("Password");
                    desc = _("Password required for room entry, if any");
                    break;
                case "muc#roomconfig_moderatedroom":
                    label = _("Moderated");
                    desc = _("Only occupants with voice may send messages");
                    break;
                case "muc#roomconfig_membersonly":
                    label = _("Members only");
                    desc = _("Only members may enter the room");
                    break;
                case "muc#roomconfig_historylength":
                    label = _("Message history");
                    desc = _("Maximum amount of backlog issued by the room");
                    break;
            }
        }

        Widget? widget = get_widget(field);
        if (widget != null) contact_details.add(_("Room Configuration"), label, desc, widget);
    }

    private static Widget? get_widget(DataForms.DataForm.Field field) {
        if (field.type_ == null) return null;
        switch (field.type_) {
            case DataForms.DataForm.Type.BOOLEAN:
                DataForms.DataForm.BooleanField boolean_field = field as DataForms.DataForm.BooleanField;
                Switch sw = new Switch() { active=boolean_field.value, valign=Align.CENTER, visible=true };
                sw.state_set.connect((state) => {
                    boolean_field.value = state;
                    return false;
                });
                return sw;
            case DataForms.DataForm.Type.JID_MULTI:
                return null;
            case DataForms.DataForm.Type.LIST_SINGLE:
                DataForms.DataForm.ListSingleField list_single_field = field as DataForms.DataForm.ListSingleField;
                ComboBoxText combobox = new ComboBoxText() { valign=Align.CENTER, visible=true };
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
                Entry entry = new Entry() { text=text_private_field.value ?? "", valign=Align.CENTER, visible=true, visibility=false };
                entry.key_release_event.connect(() => {
                    text_private_field.value = entry.text;
                    return false;
                });
                return entry;
            case DataForms.DataForm.Type.TEXT_SINGLE:
                DataForms.DataForm.TextSingleField text_single_field = field as DataForms.DataForm.TextSingleField;
                Entry entry = new Entry() { text=text_single_field.value ?? "", valign=Align.CENTER, visible=true };
                entry.key_release_event.connect(() => {
                    text_single_field.value = entry.text;
                    return false;
                });
                return entry;
            default:
                return null;
        }
    }
}

}
