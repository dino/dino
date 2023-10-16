using Gtk;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class SettingsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "chat_settings"; } }

    private StreamInteractor stream_interactor;

    private string DETAILS_HEADLINE_CHAT = "Settings";
    private string DETAILS_HEADLINE_ROOM = "Local Settings";

    public SettingsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return;

        if (!stream_interactor.get<MucManager>().is_public_room(conversation.account, conversation.counterpart)) {
            string details_headline = conversation.type_ == Conversation.Type.GROUPCHAT ? DETAILS_HEADLINE_ROOM : DETAILS_HEADLINE_CHAT;

            ComboBoxText combobox_typing = get_combobox(Dino.Application.get_default().settings.send_typing);
            combobox_typing.active_id = get_setting_id(conversation.send_typing);
            combobox_typing.changed.connect(() => { conversation.send_typing = get_setting(combobox_typing.active_id); } );
            contact_details.add(details_headline, _("Send typing notifications"), "", combobox_typing);
        }

        if (conversation.type_ == Conversation.Type.CHAT) {
            ComboBoxText combobox_marker = get_combobox(Dino.Application.get_default().settings.send_marker);
            contact_details.add(DETAILS_HEADLINE_CHAT, _("Send read receipts"), "", combobox_marker);
            combobox_marker.active_id = get_setting_id(conversation.send_marker);
            combobox_marker.changed.connect(() => { conversation.send_marker = get_setting(combobox_marker.active_id); } );
        }
    }

    private Conversation.Setting get_setting(string id) {
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

    private string get_setting_id(Conversation.Setting setting) {
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

    private ComboBoxText get_combobox(bool default_val) {
        ComboBoxText combobox = new ComboBoxText();
        combobox = new ComboBoxText();
        string default_setting = default_val ? _("On") : _("Off");
        combobox.append("default", _("Default: %s").printf(default_setting) );
        combobox.append("on", _("On"));
        combobox.append("off", _("Off"));
        return combobox;
    }
}

}
