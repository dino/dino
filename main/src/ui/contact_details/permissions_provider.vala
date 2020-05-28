using Gtk;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class PermissionsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "permissions"; } }

    private StreamInteractor stream_interactor;

    public PermissionsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK) return;
        
        Xmpp.Jid? own_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (own_jid == null) return;

        if (stream_interactor.get_module(MucManager.IDENTITY).get_role(own_jid, conversation.account) == Xmpp.Xep.Muc.Role.VISITOR){
            Button voice_request = new Button() {visible=true, label=_("Request")};
            voice_request.clicked.connect(()=>stream_interactor.get_module(MucManager.IDENTITY).request_voice(conversation.account, conversation.counterpart));
            contact_details.add(_("Permissions"), _("Request permission to send messages"), "", voice_request);
        }
    }
}

}
