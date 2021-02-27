using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
    public class Plugin : RootInterface, Object {

        private static string AUMID = "org.dino.Dino";

        public void registered(Dino.Application app) {

            if (!winrt.InitApartment())
            {
                // log error, return
            }

            if (!Win32Api.SetAppModelID(AUMID))
            {
                // log error, return
            }

            if (!ShortcutCreator.TryCreateShortcut(AUMID))
            {
                // log error, return
            }

            app.stream_interactor.get_module(NotificationEvents.IDENTITY)
                .register_notification_provider(new WindowsNotificationProvider(app, new ToastNotifier(AUMID)));
        }

        public void shutdown() {
        }
    }
}
