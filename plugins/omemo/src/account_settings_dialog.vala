using Gtk;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/omemo/account_settings_dialog.ui")]
public class AccountSettingsDialog : Gtk.Dialog {

    private Plugin plugin;
    private Account account;
    private string fingerprint;

    [GtkChild] private Label own_fingerprint;
    [GtkChild] private ListBox other_list;

    public AccountSettingsDialog(Plugin plugin, Account account) {
        Object(use_header_bar : 1);
        this.plugin = plugin;
        this.account = account;

        string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
        fingerprint = fingerprint_from_base64(own_b64);
        own_fingerprint.set_markup(fingerprint_markup(fingerprint));

        int own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];

        int i = 0;
        foreach (Row row in plugin.db.identity_meta.with_address(account.bare_jid.to_string())) {
            if (row[plugin.db.identity_meta.device_id] == own_id) continue;
            if (i == 0) {
                other_list.foreach((widget) => { widget.destroy(); });
            }
            string? other_b64 = row[plugin.db.identity_meta.identity_key_public_base64];
            Label lbl = new Label(other_b64 != null ? fingerprint_markup(fingerprint_from_base64(other_b64)) : _("Unknown device (0x%xd)").printf(row[plugin.db.identity_meta.device_id])) { use_markup = true, visible = true, margin = 8, selectable=true };
            if (row[plugin.db.identity_meta.now_active] && other_b64 != null) {
                other_list.insert(lbl, 0);
            } else {
                lbl.sensitive = false;
                other_list.insert(lbl, i);
            }
            i++;
        }
    }

    [GtkCallback]
    public void copy_button_clicked() {
        Clipboard.get_default(get_display()).set_text(fingerprint, fingerprint.length);
    }


}

}
