using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;

public class Dino.Ui.ViewModel.PreferencesWindow : Object {
    public signal void update();

    public HashMap<Account, AccountDetails> account_details = new HashMap<Account, AccountDetails>(Account.hash_func, Account.equals_func);
    public AccountDetails selected_account { get; set; }
    public Gtk.SingleSelection active_accounts_selection { get; default=new Gtk.SingleSelection(new GLib.ListStore(typeof(ViewModel.AccountDetails))); }

    public StreamInteractor stream_interactor;
    public Database db;

    public GeneralPreferencesPage general_page { get; set; default=new GeneralPreferencesPage(); }

    public void populate(Database db, StreamInteractor stream_interactor) {
        this.db = db;
        this.stream_interactor = stream_interactor;

        stream_interactor.connection_manager.connection_error.connect((account, error) => {
            var account_detail = account_details[account];
            if (account_details != null) {
                account_detail.connection_error = error;
            }
        });
        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            var account_detail = account_details[account];
            if (account_details != null) {
                account_detail.connection_state = state;
                account_detail.connection_error = stream_interactor.connection_manager.get_error(account);
            }
        });
        stream_interactor.account_added.connect(update_data);
        stream_interactor.account_removed.connect(update_data);

        bind_general_page();
        update_data();
    }

    private void update_data() {
        // account_details should hold the correct set of accounts (add or remove some if needed), but do not override remaining ones (would destroy bindings)
        var current_accounts = db.get_accounts();
        var remove_accounts = new ArrayList<Account>();
        foreach (var account in account_details.keys) {
            if (!current_accounts.contains(account)) remove_accounts.add(account);
        }
        foreach (var account in remove_accounts) {
            account_details.unset(account);
        }
        foreach (var account in current_accounts) {
            if (!account_details.has_key(account)) {
                account_details[account] = new AccountDetails(account, stream_interactor);
            }
            if (selected_account == null && account.enabled) selected_account = account_details[account];
        }

        // Update account picker model with currently active accounts
        var list_model = (GLib.ListStore) active_accounts_selection.model;
        list_model.remove_all();
        foreach (var account in stream_interactor.get_accounts()) {
            list_model.append(new ViewModel.AccountDetails(account, stream_interactor));
        }

        update();
    }

    public void set_avatar_uri(Account account, string uri) {
        stream_interactor.get_module(AvatarManager.IDENTITY).publish(account, uri);
    }

    public void remove_avatar(Account account) {
        stream_interactor.get_module(AvatarManager.IDENTITY).unset_avatar(account);
    }

    public void remove_account(Account account) {
        stream_interactor.disconnect_account.begin(account, () => {
            account.remove();
            update_data();
        });
    }

    public void reconnect_account(Account account) {
        stream_interactor.disconnect_account.begin(account, () => {
            stream_interactor.connect_account(account);
        });
    }

    public void enable_disable_account(Account account) {
        if (account.enabled) {
            account.enabled = false;
            stream_interactor.disconnect_account.begin(account);
        } else {
            account.enabled = true;
            stream_interactor.connect_account(account);
        }
        update_data();
    }

    public ChangePasswordDialog get_change_password_dialog_model() {
        return new ChangePasswordDialog() {
            account = selected_account.account,
            stream_interactor = stream_interactor
        };
    }

    private void bind_general_page() {
        var settings = Dino.Application.get_default().settings;
        settings.bind_property("send-typing", general_page, "send-typing", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        settings.bind_property("send-marker", general_page, "send-marker", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        settings.bind_property("notifications", general_page, "notifications", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        settings.bind_property("convert-utf8-smileys", general_page, "convert-emojis", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
    }
}

public class Dino.Ui.ViewModel.ChangePasswordDialog : Object {
    public Entities.Account account { get; set; }
    public StreamInteractor stream_interactor { get; set; }

    public async string? change_password(string new_password) {
        var res = yield stream_interactor.get_module(Register.IDENTITY).change_password(account, new_password);
        if (res == null) {
            account.set_password(new_password);
        }
        return res;
    }
}

