using Dino.Plugins.WindowsNotification.Vapi.Enums;

[CCode (cheader_filename = "callbacks.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.Callbacks {
    [CCode (cname = "Notification_Callback_Simple", has_target = true)]
    public delegate void NotificationCallbackSimple();

    [CCode (cname = "Notification_Callback_ActivatedWithActionIndex", has_target = true)]
    public delegate void NotificationCallbackWithActionIndex(int actionId);

    [CCode (cname = "Notification_Callback_Dismissed", has_target = true)]
    public delegate void NotificationCallbackDismissed(DismissedReason reason);

    [CCode (cname = "SimpleNotificationCallback", free_function = "DestroySimpleNotificationCallback")]
    [Compact]
    public class SimpleNotificationCallback {
        [CCode (cname = "NewSimpleNotificationCallback")]
        public SimpleNotificationCallback();

        [CCode (delegate_target_cname = "context", destroy_notify_cname = "free")]
        public NotificationCallbackSimple callback;
    }

    [CCode (cname = "ActivatedWithActionIndexNotificationCallback", free_function = "DestroyActivatedWithActionIndexNotificationCallback")]
    [Compact]
    public class ActivatedWithActionIndexNotificationCallback {
        [CCode (cname = "NewActivatedWithActionIndexNotificationCallback")]
        public ActivatedWithActionIndexNotificationCallback();

        [CCode (delegate_target_cname = "context", destroy_notify_cname = "free")]
        public NotificationCallbackWithActionIndex callback;
    }

    [CCode (cname = "DismissedNotificationCallback", free_function = "DestroyDismissedNotificationCallback")]
    [Compact]
    public class DismissedNotificationCallback {
        [CCode (cname = "NewDismissedNotificationCallback")]
        public DismissedNotificationCallback();

        [CCode (delegate_target_cname = "context", destroy_notify_cname = "free")]
        public NotificationCallbackDismissed callback;
    }
}