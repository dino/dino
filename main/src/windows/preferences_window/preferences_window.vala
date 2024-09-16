using Gdk;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/preferences_window.ui")]
public class Dino.Ui.PreferencesWindow : Adw.PreferencesWindow {
    [GtkChild] public unowned Dino.Ui.PreferencesWindowAccounts accounts_page;
    [GtkChild] public unowned Dino.Ui.PreferencesWindowEncryption encryption_page;
    [GtkChild] public unowned Dino.Ui.GeneralPreferencesPage general_page;
    public Dino.Ui.AccountPreferencesSubpage account_page = new Dino.Ui.AccountPreferencesSubpage();

    [GtkChild] public unowned ViewModel.PreferencesWindow model { get; }

    construct {
        this.can_navigate_back = true; // remove once we require Adw > 1.4
        this.bind_property("model", accounts_page, "model", BindingFlags.SYNC_CREATE);
        this.bind_property("model", account_page, "model", BindingFlags.SYNC_CREATE);
        this.bind_property("model", encryption_page, "model", BindingFlags.SYNC_CREATE);

        accounts_page.account_chosen.connect((account) => {
            model.selected_account = model.account_details[account];
            this.present_subpage(account_page);
//            this.present_subpage(new Adw.NavigationPage(account_page, "Account: %s".printf(account.bare_jid.to_string())));
        });
    }
}