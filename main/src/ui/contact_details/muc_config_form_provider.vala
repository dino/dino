using Gee;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.ContactDetails {

public class MucConfigFormProvider : Plugins.ContactDetailsProvider {
    public override string id { get { return "muc_config_form"; } }
    private StreamInteractor stream_interactor;

    public MucConfigFormProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public override void populate(Conversation conversation, Plugins.ContactDetails contact_details) {
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Xmpp.Core.XmppStream? stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) return;
            stream_interactor.get_module(MucManager.IDENTITY).get_config_form(conversation.account, conversation.counterpart, (jid, data_form, store) => {
                Plugins.ContactDetails contact_details_ = store as Plugins.ContactDetails;
                contact_details_.save.connect(() => {
                    data_form.submit();
                });
                Idle.add(() => {
                    for (int i = 0; i < data_form.fields.size; i++) {
                        DataForms.DataForm.Field field = data_form.fields[i];
                        add_field(field, contact_details_);
                    }
                    return false;
                });
            }, contact_details);
        }
    }

    public static void add_field(DataForms.DataForm.Field field, Plugins.ContactDetails contact_details) {
        string label = field.label ?? "";
        string? desc = null;
        switch (field.var) {
            case "muc#roomconfig_roomname":
                label = _("Name");
                desc = _("Name of the room");
                break;
            case "muc#roomconfig_roomdesc":
                label = _("Description");
                desc = _("Description of the room");
                break;
            case "muc#roomconfig_persistentroom":
                label = _("Persistent");
                break;
            case "muc#roomconfig_publicroom":
                label = _("Publicly searchable");
                break;
            case "muc#roomconfig_changesubject":
                label = _("Occupants may change subject");
                break;
            case "muc#roomconfig_whois":
                label = _("Discover real jids");
                desc = "Who may discover real jids";
                break;
            case "muc#roomconfig_roomsecret":
                label = _("Password");
                desc = _("Passwort required to enter the room. Leave empty for none.");
                break;
            case "muc#roomconfig_moderatedroom":
                label = _("Moderated");
                break;
            case "muc#roomconfig_membersonly":
                label = _("Members only");
                desc = _("Only members may enter the room");
                break;
            case "muc#roomconfig_historylength":
                label = _("Message History");
                desc = _("Maximum number of history messages returned by the room");
                break;
        }

        Widget? widget = get_widget(field);
        if (widget != null) contact_details.add(_("Room Configuration"), label, desc, widget);
    }

    private static Widget? get_widget(DataForms.DataForm.Field field) {
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