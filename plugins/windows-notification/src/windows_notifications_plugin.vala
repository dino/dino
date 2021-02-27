using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private static string AUMID = "org.dino.Dino";
    private ToastNotifier notifier;
    private ToastNotification notification; // Notifications remove their actions when they go out of scope

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
            //var notificationBuilder = new ToastNotificationBuilder.from_string(template);
            this.notification = new ToastNotificationBuilder()
                .SetHeader("Hello")
                .SetBody("World")
                .SetImage("C:\\Users\\lfsaf\\Pictures\\14236067.png")
                .AddButton("Clique aqui", "argumento")
                .Build();
            
            this.notifier = new ToastNotifier(AUMID);
            var token = this.notification.Activated((c, d) => {
              stdout.printf("\nYay! Activated!\n");
              var tr = false;
              if (c != null && c == "argumento") {
                    tr = true;
              }
              
              stdout.flush();
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
