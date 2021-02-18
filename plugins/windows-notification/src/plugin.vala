using Gee;
using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private static string AUMID = "org.dino.Dino";

    public int m { get; set; }

    public void registered(Dino.Application app) {
        if (!WinRTApi.Initialize())
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

        var notification = new ToastNotification.ToastNotification();
        int test = 2;
        notification.Activated = new Callbacks.SimpleNotificationCallback()
        {
            callback = () => {
                test = 3;
            }
        };

        notification.ActivatedWithIndex = new Callbacks.ActivatedWithActionIndexNotificationCallback()
        {
            callback = (index) => {
                test = index;
            }
        };

        notification.Dismissed = new Callbacks.DismissedNotificationCallback()
        {
            callback = (reason) => {
                var m = reason;
            }
        };

        notification.Failed = new Callbacks.SimpleNotificationCallback()
        {
            callback = () => {
                var m = 2;
            }
        };
        
        //  var provider = new WindowsNotificationProvider(app, Win32Api.SupportsModernNotifications());
        //  app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
    }

    public void shutdown() {
    }
}

}
