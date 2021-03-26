using Gee;
using Dino.Entities;
using Win32Api;
using ShortcutCreator;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    public void registered(Dino.Application app) {
        var created = ShortcutCreator.TryCreateShortcut("org.dino.Dino");
        if (!created)
        {
            // log somewhere, return
        }

        var initialized = 

        if (!Win32Api.SupportsModernNotifications())
        {
            // limit types of notifications on template builder
        }

        //  var provider = WindowsNotificationProvider.try_create(app);
        //  if (provider != null) {
        //      app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
        //  }
    }

    public void shutdown() {
    }
}

}
