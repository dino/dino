using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

//[GtkTemplate (ui = "/im/dino/Dino/preferences_window_encryption.ui")]
public class Dino.Ui.PreferencesWindowEncryption : Adw.PreferencesPage {

    private DropDown drop_down = null;
    private Adw.PreferencesGroup accounts_group = new Adw.PreferencesGroup();
    private ArrayList<Adw.PreferencesGroup> added_widgets = new ArrayList<Adw.PreferencesGroup>();

    public ViewModel.PreferencesWindow model { get; set; }

    construct {
        this.add(accounts_group);

        this.notify["model"].connect(() => {
            this.model.update.connect(() => {
                if (drop_down != null) {
                    accounts_group.remove(drop_down);
                    drop_down = null;
                }

                if (model.active_accounts_selection.get_n_items() > 0) {
                    drop_down = new DropDown(model.active_accounts_selection, null) { halign=Align.CENTER };
                    drop_down.factory = new BuilderListItemFactory.from_resource(null, "/im/dino/Dino/account_picker_row.ui");

                    drop_down.notify["selected-item"].connect(() => {
                        var account_details = (ViewModel.AccountDetails) drop_down.selected_item;
                        if (account_details == null) return;
                        set_account(account_details.account);
                    });

                    drop_down.selected = 0;
                    set_account(((ViewModel.AccountDetails)model.active_accounts_selection.get_item(0)).account);
                } else {
                    drop_down = new DropDown.from_strings(new string[] { _("No active accounts")}) { halign=Align.CENTER };
                }
                accounts_group.add(drop_down);
            });
        });
    }

    public void set_account(Account account) {
        foreach (var widget in added_widgets) {
            this.remove(widget);
        }
        added_widgets.clear();

        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.EncryptionPreferencesEntry e in app.plugin_registry.encryption_preferences_entries) {
            var widget = (Adw.PreferencesGroup) e.get_widget(account, Plugins.WidgetType.GTK4);
            this.add(widget);
            this.added_widgets.add(widget);
        }
    }
}