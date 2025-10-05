using Gtk;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class SettingsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "chat_settings"; } }
    public string tab { get { return "about"; } }

    private StreamInteractor stream_interactor;

    public SettingsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return;

        if (!stream_interactor.get<MucManager>().is_public_room(conversation.account, conversation.counterpart)) {
            string typing_default_setting = Dino.Application.get_default().settings.send_typing ? _("On") : _("Off");
            var setting_model = new Dino.Ui.ViewModel.PreferencesRow.ComboBox() { title = _("Send typing notifications") };
            setting_model.items.add(_("Default: %s").printf(typing_default_setting));
            setting_model.items.add(_("On"));
            setting_model.items.add(_("Off"));
            conversation.bind_property("send-typing", setting_model, "active-item", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            contact_details.add_settings_action_row(setting_model);
        }

        if (conversation.type_ == Conversation.Type.CHAT) {
            string marker_default_setting = Dino.Application.get_default().settings.send_marker ? _("On") : _("Off");
            var setting_model = new Dino.Ui.ViewModel.PreferencesRow.ComboBox() { title = _("Send read receipts") };
            setting_model.items.add(_("Default: %s").printf(marker_default_setting));
            setting_model.items.add(_("On"));
            setting_model.items.add(_("Off"));
            conversation.bind_property("send-marker", setting_model, "active-item", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            contact_details.add_settings_action_row(setting_model);
        }
    }

    public Object? get_widget(Conversation conversation) {
        return null;
    }
}

}
