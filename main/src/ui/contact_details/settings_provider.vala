using Gtk;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class SettingsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "chat_settings"; } }

    private StreamInteractor stream_interactor;

    public SettingsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK) return;
        if (conversation.type_ == Conversation.Type.CHAT) {
            ComboBoxText[] comboboxes = new ComboBoxText[2];
            for (int i = 0; i < 3; i++) {
                comboboxes[i] = new ComboBoxText() { visible=true };
                comboboxes[i].append("default", _("Default"));
                comboboxes[i].append("on", _("On"));
                comboboxes[i].append("off", _("Off"));
            }

            contact_details.add(_("Settings"), _("Send typing notifications"), "", comboboxes[0]);
            comboboxes[0].active_id = get_setting_id(conversation.get_send_typing_setting());
            comboboxes[0].changed.connect(() => { print("changed!\n"); conversation.send_typing = get_setting(comboboxes[0].active_id); } );

            contact_details.add(_("Settings"), _("Send message marker"), "", comboboxes[1]);
            comboboxes[1].active_id = get_setting_id(conversation.get_send_marker_setting());
            comboboxes[1].changed.connect(() => { conversation.send_marker = get_setting(comboboxes[1].active_id); } );

            contact_details.add(_("Settings"), _("Notifications"), "", comboboxes[2]);
            comboboxes[2].active_id = get_notify_setting_id(conversation.get_notification_setting(stream_interactor));
            comboboxes[2].changed.connect(() => { conversation.notify_setting = get_notify_setting(comboboxes[2].active_id); } );
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            ComboBoxText combobox = new ComboBoxText() { visible=true };
            combobox.append("default", _("Default"));
            combobox.append("highlight", _("Only when mentioned"));
            combobox.append("on", _("On"));
            combobox.append("off", _("Off"));
            contact_details.add(_("Local Settings"), _("Notifications"), "", combobox);
            combobox.active_id = get_notify_setting_id(conversation.get_notification_setting(stream_interactor));
            combobox.changed.connect(() => { conversation.notify_setting = get_notify_setting(combobox.active_id); } );
        }
    }

    public Conversation.Setting get_setting(string id) {
        switch (id) {
            case "default":
                return Conversation.Setting.DEFAULT;
            case "on":
                return Conversation.Setting.ON;
            case "off":
                return Conversation.Setting.OFF;
        }
        assert_not_reached();
    }

    public Conversation.NotifySetting get_notify_setting(string id) {
        switch (id) {
            case "default":
                return Conversation.NotifySetting.DEFAULT;
            case "on":
                return Conversation.NotifySetting.ON;
            case "off":
                return Conversation.NotifySetting.OFF;
            case "highlight":
                return Conversation.NotifySetting.HIGHLIGHT;
        }
        assert_not_reached();
    }

    public string get_setting_id(Conversation.Setting setting) {
        switch (setting) {
            case Conversation.Setting.DEFAULT:
                return "default";
            case Conversation.Setting.ON:
                return "on";
            case Conversation.Setting.OFF:
                return "off";
        }
        assert_not_reached();
    }

    public string get_notify_setting_id(Conversation.NotifySetting setting) {
        switch (setting) {
            case Conversation.NotifySetting.DEFAULT:
                return "default";
            case Conversation.NotifySetting.ON:
                return "on";
            case Conversation.NotifySetting.OFF:
                return "off";
            case Conversation.NotifySetting.HIGHLIGHT:
                return "highlight";
        }
        assert_not_reached();
    }
}

}