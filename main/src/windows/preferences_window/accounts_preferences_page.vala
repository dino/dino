using Dino.Entities;
using Gee;
using Gtk;

public class Dino.Ui.PreferencesWindowAccounts : Adw.PreferencesPage {

    public signal void account_chosen(Account account);

    public Adw.PreferencesGroup active_accounts;
    public Adw.PreferencesGroup disabled_accounts;

    public ViewModel.PreferencesDialog model { get; set; }

    construct  {
        this.title = _("Accounts");
        this.icon_name = "system-users-symbolic";

        this.notify["model"].connect(() => {
            model.update.connect(refresh);
        });
    }

    private void refresh() {
        if (active_accounts != null) this.remove(active_accounts);
        if (disabled_accounts != null) this.remove(disabled_accounts);

        active_accounts = new Adw.PreferencesGroup() { title=_("Accounts")};
        disabled_accounts = new Adw.PreferencesGroup() { title=_("Disabled accounts")};
        Button add_account_button = new Button.from_icon_name("list-add-symbolic");
        add_account_button.add_css_class("flat");
        add_account_button.tooltip_text = _("Add Account");
        active_accounts.header_suffix = add_account_button;

        this.add(active_accounts);
        this.add(disabled_accounts);

        add_account_button.clicked.connect(() => {
            Ui.ManageAccounts.AddAccountDialog add_account_dialog = new Ui.ManageAccounts.AddAccountDialog(model.stream_interactor, model.db);
            add_account_dialog.added.connect((account) => {
                refresh();
            });
            add_account_dialog.present((Window)this.get_root());
        });

        disabled_accounts.visible = false; // Only display disabled section if it contains accounts
        var enabled_account_added = false;

        foreach (ViewModel.AccountDetails account_details in model.account_details.values) {
            var row = new Adw.ActionRow() {
                title = account_details.bare_jid.to_string()
            };
            row.add_prefix(new AvatarPicture() { valign=Align.CENTER, height_request=35, width_request=35, model = account_details.avatar_model });
            row.add_suffix(new Image.from_icon_name("go-next-symbolic"));
            row.activatable = true;

            if (account_details.account.enabled) {
                active_accounts.add(row);
                enabled_account_added = true;
            } else {
                disabled_accounts.add(row);
                disabled_accounts.visible = true;
            }

            row.activated.connect(() => {
                account_chosen(account_details.account);
            });
        }

        // We always have to show the active accounts group for the add new button. Display placeholder if there are no active accounts
        if (!enabled_account_added) {
            active_accounts.add(new Adw.ActionRow() { title=_("No active accounts") });
        }
    }
}
