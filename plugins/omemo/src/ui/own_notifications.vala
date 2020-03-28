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
        stream_interactor.module_manager.get_module(account, Legacy.StreamModule.IDENTITY).bundle_fetched.connect_after((jid, device_id, bundle) => {
            if (jid.equals(account.bare_jid) && plugin.has_new_devices(account, account.bare_jid)) {
                display_notification();
            }
        });
        stream_interactor.module_manager.get_module(account, V1.StreamModule.IDENTITY).bundle_fetched.connect_after((jid, device_id, bundle) => {
            if (jid.equals(account.bare_jid) && plugin.has_new_devices(account, account.bare_jid)) {
                display_notification();
            }
        });

        if (plugin.has_new_devices(account, account.bare_jid)) {
            display_notification();
        }
    }

    private void display_notification() {
        Notification notification = new Notification(_("OMEMO trust decision required"));
        notification.set_default_action_and_target_value("app.own-keys", new Variant.int32(account.id));
        notification.set_body(_("Did you add a new device for account %s?").printf(@"$(account.bare_jid.to_string())"));
        plugin.app.send_notification(account.id.to_string()+"-new-device", notification);
    }
}
}
