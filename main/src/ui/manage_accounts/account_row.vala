using Gtk;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/account_row.ui")]
public class AccountRow :  Gtk.ListBoxRow {

    [GtkChild] public unowned AvatarImage image;
    [GtkChild] public unowned Label jid_label;
    [GtkChild] public unowned Image icon;

    public Account account;
    private StreamInteractor stream_interactor;

    public AccountRow(StreamInteractor stream_interactor, Account account) {
        this.stream_interactor = stream_interactor;
        this.account = account;
        image.set_conversation(stream_interactor, new Conversation(account.bare_jid, account, Conversation.Type.CHAT));
        jid_label.set_label(account.bare_jid.to_string());

        stream_interactor.connection_manager.connection_error.connect((account, error) => {
            if (account.equals(this.account)) {
                update_warning_icon();
            }
        });
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            if (account.equals(this.account)) {
                update_warning_icon();
            }
        });
    }

    private void update_warning_icon() {
        ConnectionManager.ConnectionError? error = stream_interactor.connection_manager.get_error(account);
        icon.visible = (error != null);
    }
}

}
