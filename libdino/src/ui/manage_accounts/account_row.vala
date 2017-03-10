using Gtk;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/org/dino-im/manage_accounts/account_row.ui")]
public class AccountRow :  Gtk.ListBoxRow {

    [GtkChild]
    public Image image;

    [GtkChild]
    public Label jid_label;

    public Account account;

    public AccountRow(StreamInteractor stream_interactor, Account account) {
        this.account = account;
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(40, 40, image.scale_factor)).draw_account(stream_interactor, account));
        jid_label.set_label(account.bare_jid.to_string());
    }
}
}