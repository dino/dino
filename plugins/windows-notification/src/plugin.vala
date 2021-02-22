using Gee;
using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private static string AUMID = "org.dino.Dino";

    public int m { get; set; }

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

        {
            var m = new winrt.Windows.UI.Notifications.ToastNotification("Test");
            var token = m.Activated((c, d) => {
                var i = 2;
            });
            m.RemoveActivatedAction(token);


            var h = m.ExpiresOnReboot;
            m.ExpiresOnReboot = false;

            var a = m.Tag;
            m.Tag = "a";

            a = m.Group;
            m.Group = "a";
        }
        
        //  var provider = new WindowsNotificationProvider(app, Win32Api.SupportsModernNotifications());
        //  app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
    }

    public void shutdown() {
    }
}

}
