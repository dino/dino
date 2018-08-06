using Dino.Entities;
using Xmpp;
using Gtk;
using Gee;
using Qlite;

namespace Dino.Plugins.Omemo {

public class OwnNotifications {

    private StreamInteractor stream_interactor;
    private Plugin plugin;
    private Map<int, Notification> notifications = new HashMap<int, Notification>();

    public OwnNotifications (Plugin plugin, StreamInteractor stream_interactor) {
        this.stream_interactor = (!)stream_interactor;
        this.plugin = plugin;

        SimpleAction own_keys_action = new SimpleAction("own-keys", VariantType.INT32);
        own_keys_action.activate.connect((variant) => {
            RowOption row = plugin.app.db.account.row_with(plugin.app.db.account.id, variant.get_int32());
            Account account = new Account.from_row(this.plugin.app.db, row.inner);
            ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, account, account.bare_jid);
            Gtk.Application app = plugin.app as Gtk.Application;
            dialog.set_transient_for(app.get_active_window());
            dialog.present();
            dialog.response.connect((response_type) => {
                should_hide(account);
            });
        });
        plugin.app.add_action(own_keys_action);

        stream_interactor.account_added.connect(add_account);
    }

    public void add_account(Account account) {
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).bundle_fetched.connect_after((jid, device_id, bundle) => {
            if(jid.equals(account.bare_jid) && has_new_devices(account)) {
                display_notification(account);
            }
        });

        if (has_new_devices(account)) {
            display_notification(account);
        }
    }

    private bool has_new_devices(Account account) {
        return plugin.db.identity_meta.with_address(account.id, account.bare_jid.to_string()).with(plugin.db.identity_meta.trust_level, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64).count() > 0;
    }

    public void should_hide(Account account) {
        if (!has_new_devices(account) && notifications[account.id] != null){
            plugin.app.withdraw_notification(account.id.to_string()+"-new-device");
            notifications[account.id] = null;
        }
    }

    private void display_notification(Account account) {
        if(notifications[account.id] != null) {
            plugin.app.withdraw_notification(account.id.to_string()+"-new-device");
        }
        notifications[account.id] = new Notification("Trust decision required");
        notifications[account.id].set_body(@"A new OMEMO device has been added for the account $(account.bare_jid)");
        notifications[account.id].set_default_action_and_target_value("app.own-keys", new Variant.int32(account.id));
        plugin.app.send_notification(account.id.to_string()+"-new-device", notifications[account.id]);
    }
}
}
