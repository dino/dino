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
        if (conversation.type_ == Conversation.Type.CHAT && type == WidgetType.GTK) {
            string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
            if (key_id != null) {
                Gee.List<GPG.Key> keys = GPGHelper.get_keylist(key_id);
                if (keys.size > 0) {
                    Label label = new Label(markup_colorize_id(keys[0].fpr, true)) { use_markup=true, justify=Justification.RIGHT, visible=true };
                    contact_details.add(_("Encryption"), _("OpenPGP"), "", label);
                } else {
                    string s = _("Key not in keychain") + "\n" + markup_colorize_id(key_id, false);
                    Label label = new Label(s) { use_markup=true, justify=Justification.RIGHT, visible=true };
                    contact_details.add(_("Encryption"), _("OpenPGP"), "", label);
                }
            }
        }
    }
}

}
