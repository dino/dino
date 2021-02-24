using Gee;
using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private static string AUMID = "org.dino.Dino";
    private ToastNotifier notifier;
    private ToastNotification notification; // Notifications remove their actions when they get out of scope

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
            var text = "<toast launch=\"action=viewPhoto&amp;photoId=92187\">
            <visual>
              <binding template=\"ToastGeneric\">
                <image placement=\"appLogoOverride\" hint-crop=\"circle\" src=\"https://unsplash.it/64?image=669\"/>
                <text>Adam Wilson tagged you in a photo</text>
                <text>On top of McClellan Butte - with Andrew Bares</text>
                <image src=\"https://unsplash.it/360/202?image=883\"/>
              </binding>
            </visual>
            <actions>
              <action
                content=\"Like\"
                activationType=\"background\"
                arguments=\"likePhoto&amp;photoId=92187\"/>
              <action
                content=\"Comment\"
                arguments=\"action=commentPhoto&amp;photoId=92187\"/>
            </actions>
          </toast>";

            this.notifier = new ToastNotifier(AUMID);
            this.notification = new ToastNotification(text);
            var token = notification.Activated((c, d) => {
                var i = 2;
                stdout.printf("Yay! Activated 1!\n");
            });
            notification.RemoveActivated(token);

            token = notification.Activated((c, d) => {
              var i = 2;
              stdout.printf("Yay! Activated 2!\n");
            });

            notifier.Show(notification);
        }
        
        //  var provider = new WindowsNotificationProvider(app, Win32Api.SupportsModernNotifications());
        //  app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
    }

    public void shutdown() {
    }
}

}
