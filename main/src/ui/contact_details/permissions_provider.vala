using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class PermissionsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "permissions"; } }
    public string tab { get { return "about"; } }

    private StreamInteractor stream_interactor;

    public PermissionsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return;
        
        Xmpp.Jid? own_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (own_jid == null) return;

        if (true || stream_interactor.get_module(MucManager.IDENTITY).get_role(own_jid, conversation.account) == Xmpp.Xep.Muc.Role.VISITOR) {
            var view_model = new Ui.ViewModel.PreferencesRow.Button() {
                title = _("Request permission to send messages"),
                button_text = _("Request")
            };
            view_model.clicked.connect(()=> {
                stream_interactor.get_module(MucManager.IDENTITY).request_voice(conversation.account, conversation.counterpart);
            });
            contact_details.add_settings_action_row(view_model);
        }
    }

    public Object? get_widget(Conversation conversation) {
        return null;
    }
}

}
