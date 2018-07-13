using Gtk;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class AccountSettingWidget : Plugins.AccountSettingsWidget, Box {
    private Plugin plugin;
    private Label fingerprint;
    private Account account;
    private Button btn;

    public AccountSettingWidget(Plugin plugin) {
        this.plugin = plugin;

        fingerprint = new Label("...");
        fingerprint.xalign = 0;
        Border border = new Button().get_style_context().get_padding(StateFlags.NORMAL);
        fingerprint.margin_top = border.top + 1;
        fingerprint.margin_start = border.left + 1;
        fingerprint.visible = true;
        pack_start(fingerprint);

        btn = new Button();
        btn.image = new Image.from_icon_name("view-list-symbolic", IconSize.BUTTON);
        btn.relief = ReliefStyle.NONE;
        btn.visible = false;
        btn.valign = Align.CENTER;
        btn.clicked.connect(() => {
            activated();
            ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, account, account.bare_jid);
            dialog.set_transient_for((Window) get_toplevel());
            dialog.present();
            dialog.response.connect((response_type) => {
                plugin.own_notifications.should_hide(account);
            });
        });
        pack_start(btn, false);
    }

    public void set_account(Account account) {
        this.account = account;
        btn.visible = false;
        Qlite.Row? row = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id).inner;
        if (row == null) {
            fingerprint.set_markup("%s\n<span font='8'>%s</span>".printf(_("Own fingerprint"), _("Will be generated on first connect")));
        } else {
            string res = fingerprint_markup(fingerprint_from_base64(((!)row)[plugin.db.identity.identity_key_public_base64]));
            fingerprint.set_markup("%s\n<span font_family='monospace' font='8'>%s</span>".printf(_("Own fingerprint"), res));
            btn.visible = true;
        }
    }

    public void deactivate() {
    }
}

}
