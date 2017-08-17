using Gtk;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/manage_accounts/account_row.ui")]
public class AccountRow :  Gtk.ListBoxRow {

    [GtkChild] public Image image;
    [GtkChild] public Label jid_label;
    [GtkChild] public Image icon;

    public Account account;
    private StreamInteractor stream_interactor;

    public AccountRow(StreamInteractor stream_interactor, Account account) {
        this.stream_interactor = stream_interactor;
        this.account = account;
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(40, 40, image.scale_factor)).draw_account(stream_interactor, account));
        jid_label.set_label(account.bare_jid.to_string());

        stream_interactor.connection_manager.connection_error.connect((account, error) => {
            Idle.add(() => {
                if (account.equals(this.account)) update_warning_icon();
                return false;
            });
        });
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            Idle.add(() => {
                if (account.equals(this.account)) update_warning_icon();
                return false;
            });
        });
    }

    private void update_warning_icon() {
        ConnectionManager.ConnectionError? error = stream_interactor.connection_manager.get_error(account);
        icon.visible = (error != null);
    }
}

}
