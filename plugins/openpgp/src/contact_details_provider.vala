using Gtk;

using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class ContactDetailsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "pgp_info"; } }
    public string tab { get { return "encryption"; } }

    private StreamInteractor stream_interactor;

    public ContactDetailsProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, WidgetType type) { }

    public Object? get_widget(Conversation conversation) {
        var preferences_group = new Adw.PreferencesGroup() { title="OpenPGP" };

        if (conversation.type_ != Conversation.Type.CHAT) return null;

        string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
        if (key_id == null) return null;

        Gee.List<GPG.Key>? keys = null;
        try {
            keys = GPGHelper.get_keylist(key_id);
        } catch (Error e) { }

        var str = "";
        if (keys != null && keys.size > 0) {
            str = markup_id(keys[0].fpr, true);
        } else {
            str = _("Key not in keychain") + "\n" + markup_id(key_id, false);
        }

        var view = new Adw.ActionRow() {
            title = "Fingerprint",
            subtitle = str,
#if Adw_1_3
            subtitle_selectable = true,
#endif
        };

        preferences_group.add(view);

        return preferences_group;
    }
}

}
