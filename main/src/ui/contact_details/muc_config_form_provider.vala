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

            stream_interactor.get_module(MucManager.IDENTITY).get_config_form.begin(conversation.account, conversation.counterpart, (_, res) => {
                DataForms.DataForm? data_form = stream_interactor.get_module(MucManager.IDENTITY).get_config_form.end(res);
                if (data_form == null) return;

                for (int i = 0; i < data_form.fields.size; i++) {
                    DataForms.DataForm.Field field = data_form.fields[i];
                    add_field(field, contact_details);
                }

                string config_backup = data_form.stanza_node.to_string();
                contact_details.save.connect(() => {
                    // Only send the config form if something was changed
                    if (config_backup != data_form.stanza_node.to_string()) {
                        stream_interactor.get_module(MucManager.IDENTITY).set_config_form(conversation.account, conversation.counterpart, data_form);
                    }
                });
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
                    label = _("Permission to view JIDs");
                    desc = _("Who is allowed to view the occupants' JIDs?");
                    break;
                case "muc#roomconfig_roomsecret":
                    label = _("Password");
                    desc = _("A password to restrict access to the room");
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
                    desc = _("Maximum number of room messages to store");
                    break;
            }
        }

        Widget? widget = Util.get_data_form_field_widget(field);
        if (widget != null) contact_details.add(_("Room Configuration"), label, desc, widget);
    }
}

}
