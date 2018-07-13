using Dino.Entities;
using Xmpp;
using Gtk;

namespace Dino.Plugins.Omemo {

public class OwnNotifications {

    private StreamInteractor stream_interactor;
    private Plugin plugin;
    private Account account;

    public OwnNotifications (Plugin plugin, StreamInteractor stream_interactor, Account account) {
        this.stream_interactor = (!)stream_interactor;
        this.plugin = plugin;
        this.account = account;
        stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).bundle_fetched.connect_after((jid, device_id, bundle) => {
                if (jid.equals(account.bare_jid) && has_new_devices(account.bare_jid)) {
                    display_notification();
                }
            });
        if (has_new_devices(account.bare_jid)) {
            display_notification();
        }

    }

    public bool has_new_devices(Jid jid) {
        return plugin.db.identity_meta.with_address(account.id, jid.bare_jid.to_string()).with(plugin.db.identity_meta.trust_level, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64).count() > 0;
    }

    private void display_notification() {
        Notification notification = new Notification("Trust decision required");
        notification.set_body(@"A new OMEMO device has been added for the account $(account.bare_jid)");
        notification.set_default_action_and_target_value("app.own-keys", new Variant.int32(account.id));
        plugin.app.send_notification(account.id.to_string()+"-new-device", notification);
    }
}
}
