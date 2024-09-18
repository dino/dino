using Gtk;
using Gee;
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
        if (conversation.type_ == Conversation.Type.CHAT && type == WidgetType.GTK4) {

            int identity_id = plugin.db.identity.get_id(conversation.account.id);
            if (identity_id < 0) return;

            int i = 0;
            foreach (Row row in plugin.db.identity_meta.with_address(identity_id, conversation.counterpart.to_string())) {
                if (row[plugin.db.identity_meta.identity_key_public_base64] != null) {
                    i++;
                }
            }

            if (i > 0) {
                Button btn = new Button.from_icon_name("view-list-symbolic") { visible = true, valign = Align.CENTER, has_frame = false };
                btn.tooltip_text = _("OMEMO Key Management");
                btn.clicked.connect(() => {
                    btn.activate();
                    ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, conversation.account, conversation.counterpart);
                    dialog.set_transient_for((Window) btn.get_root());
                    dialog.response.connect((response_type) => {
                        plugin.device_notification_populator.should_hide();
                    });
                    dialog.present();
                });

                contact_details.add(_("Encryption"), "OMEMO", n("%d OMEMO device", "%d OMEMO devices", i).printf(i), btn);
            }
        }
    }
}

}
