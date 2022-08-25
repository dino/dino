using Gtk;

using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class ContactDetailsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "pgp_info"; } }

    private StreamInteractor stream_interactor;

    public ContactDetailsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, WidgetType type) {
        if (conversation.type_ == Conversation.Type.CHAT && type == WidgetType.GTK4) {
            string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
            if (key_id != null) {
                Label label = new Label("") { use_markup=true, justify=Justification.RIGHT, selectable=true };
                Gee.List<GPG.Key>? keys = null;
                try {
                    keys = GPGHelper.get_keylist(key_id);
                } catch (Error e) { }
                if (keys != null && keys.size > 0) {
                    label.label = markup_colorize_id(keys[0].fpr, true);
                } else {
                    label.label = _("Key not in keychain") + "\n" + markup_colorize_id(key_id, false);
                }
                contact_details.add(_("Encryption"), "OpenPGP", "", label);
            }
        }
    }
}

}
