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
                <image placement=\"appLogoOverride\" hint-crop=\"circle\" src=\"C:\\Users\\user\\Pictures\\dino\\669-64x64\"/>
                <text>Adam Wilson tagged you in a photo</text>
                <text>On top of McClellan Butte - with Andrew Bares</text>
                <image src=\"C:\\Users\\user\\Pictures\\dino\\883-360x202.jpg\"/>
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

          text = "<toast launch=\"action=viewEvent&amp;eventId=63851\">
          <visual>
            <binding template=\"ToastGeneric\">
              <text>Surface Launch Party</text>
              <text>Studio S / Ballroom</text>
              <text>4:00 PM, 10/26/2015</text>
            </binding>
          </visual>
          <actions>
            <input id=\"status\" type=\"selection\" defaultInput=\"yes\">
              <selection id=\"yes\" content=\"Going\"/>
              <selection id=\"maybe\" content=\"Maybe\"/>
              <selection id=\"no\" content=\"Decline\"/>
            </input>
            <action
              activationType=\"background\"
              arguments=\"action=rsvpEvent&amp;eventId=63851\"
              content=\"RSVP\"/>
            <action
              activationType=\"system\"
              arguments=\"dismiss\"
              content=\"\"/>
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

            var token2 = notification.Failed(() => {
              stdout.printf("Failed! :/\n");
            });
            notification.RemoveFailed(token2);

            var give_me_reason = ToastDismissalReason.TimedOut;
            var give_me_template = ToastTemplateType.ToastText01;
            var template = ToastNotificationManager.GetTemplateContent(give_me_template);

            var token3 = notification.Dismissed((reason) => {
              stdout.printf("Dismissed! :(\n");
              var r = reason;
              var m = 2;
            });
            notification.RemoveDismissed(token3);

            notifier.Show(notification);
        }
        
        //  var provider = new WindowsNotificationProvider(app, Win32Api.SupportsModernNotifications());
        //  app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
    }

    public void shutdown() {
    }
}

}
