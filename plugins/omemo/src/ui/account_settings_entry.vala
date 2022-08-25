using Dino.Entities;
using Gtk;

namespace Dino.Plugins.Omemo {

public class AccountSettingsEntry : Plugins.AccountSettingsEntry {
    private Plugin plugin;
    private Account account;

    private Box box = new Box(Orientation.HORIZONTAL, 0);
    private Label fingerprint = new Label("...") { xalign=0 };
    private Button btn = new Button.from_icon_name("view-list-symbolic") { has_frame=false, valign=Align.CENTER, visible=false };

    public override string id { get { return "omemo_identity_key"; }}

    public override string name { get { return "OMEMO"; }}

    public AccountSettingsEntry(Plugin plugin) {
        this.plugin = plugin;

        Border border = new Button().get_style_context().get_padding();
        fingerprint.margin_top = border.top + 1;
        fingerprint.margin_start = border.left + 1;
        fingerprint.visible = true;
        box.append(fingerprint);

        btn.clicked.connect(() => {
            activated();
            ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, account, account.bare_jid);
            dialog.set_transient_for((Window) box.get_root());
            dialog.present();
        });
        // TODO expand=false?
        box.append(btn);
    }

    public override Object? get_widget(WidgetType type) {
        if (type != WidgetType.GTK4) return null;
        return box;
    }

    public override void set_account(Account account) {
        this.account = account;
        btn.visible = false;
        Qlite.Row? row = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id).inner;
        if (row == null) {
            fingerprint.set_markup("%s\n<span font='8'>%s</span>".printf(_("Own fingerprint"), _("Will be generated on first connection")));
        } else {
            string res = fingerprint_markup(fingerprint_from_base64(((!)row)[plugin.db.identity.identity_key_public_base64]));
            fingerprint.set_markup("%s\n<span font_family='monospace' font='8'>%s</span>".printf(_("Own fingerprint"), res));
            btn.visible = true;
        }
    }

    public override void deactivate() { }
}

}