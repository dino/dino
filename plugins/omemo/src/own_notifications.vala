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
        int identity_id = plugin.db.identity.get_id(account.id);
        if (identity_id < 0) return false;

        return plugin.db.identity_meta.get_new_devices(identity_id, jid.bare_jid.to_string()).count() > 0;
    }

    private void display_notification() {
        Notification notification = new Notification(_("Trust decision required"));
        notification.set_body(_("A new OMEMO device has been added for the account %s").printf("$(account.jid.bare_jid)"));
        plugin.app.send_notification(account.id.to_string()+"-new-device", notification);
    }
}
}
