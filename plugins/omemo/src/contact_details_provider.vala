using Gtk;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class ContactDetailsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "omemo_info"; } }

    private Plugin plugin;

    public ContactDetailsProvider(Plugin plugin) {
        this.plugin = plugin;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, WidgetType type) {
        if (conversation.type_ == Conversation.Type.CHAT && type == WidgetType.GTK) {
            string res = "";
            int i = 0;
            foreach (Row row in plugin.db.identity_meta.with_address(conversation.counterpart.to_string())) {
                if (row[plugin.db.identity_meta.identity_key_public_base64] != null) {
                    if (i != 0) {
                        res += "\n\n";
                    }
                    res += fingerprint_markup(fingerprint_from_base64(row[plugin.db.identity_meta.identity_key_public_base64]));
                    i++;
                }
            }
            if (i > 0) {
                Label label = new Label(res) { use_markup=true, justify=Justification.RIGHT, selectable=true, visible=true };
                contact_details.add(_("Encryption"), "OMEMO", n("%d OMEMO device", "%d OMEMO devices", i).printf(i), label);
            }
        }
    }
}

}
