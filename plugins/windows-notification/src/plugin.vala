using Gee;
using Dino.Entities;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    public void registered(Dino.Application app) {
        var provider = WindowsNotificationProvider.try_create(app);
        if (provider != null) {
            app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
        }
    }

    public void shutdown() {
    }
}

}
