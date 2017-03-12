using Gtk;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class AccountSettingWidget : Plugins.AccountSettingsWidget, Box {
    private Plugin plugin;
    private Label fingerprint;
    private Account account;

    public AccountSettingWidget(Plugin plugin) {
        this.plugin = plugin;

        fingerprint = new Label("...");
        fingerprint.xalign = 0;
        Border border = new Button().get_style_context().get_padding(StateFlags.NORMAL);
        fingerprint.set_padding(border.left + 1, border.top + 1);
        fingerprint.visible = true;
        pack_start(fingerprint);

        Button btn = new Button();
        btn.image = new Image.from_icon_name("view-list-symbolic", IconSize.BUTTON);
        btn.relief = ReliefStyle.NONE;
        btn.visible = true;
        btn.valign = Align.CENTER;
        btn.clicked.connect(() => { activated(); });
        pack_start(btn, false);
    }

    public void set_account(Account account) {
        this.account = account;
        try {
            Qlite.Row? row = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id);
            if (row == null) {
                fingerprint.set_markup(@"Own fingerprint\n<span font='8'>Will be generated on first connect</span>");
            } else {
                uint8[] arr = Base64.decode(row[plugin.db.identity.identity_key_public_base64]);
                arr = arr[1:arr.length];
                string res = "";
                foreach (uint8 i in arr) {
                    string s = i.to_string("%x");
                    if (s.length == 1) s = "0" + s;
                    res = res + s;
                    if ((res.length % 9) == 8) {
                        if (res.length == 35) {
                            res += "\n";
                        } else {
                            res += " ";
                        }
                    }
                }
                fingerprint.set_markup(@"Own fingerprint\n<span font_family='monospace' font='8'>$res</span>");
            }
        } catch (Qlite.DatabaseError e) {
            fingerprint.set_markup(@"Own fingerprint\n<span font='8'>Database error</span>");
        }
    }

    public void deactivate() {
    }
}

}