using winrt;

[CCode (cheader_filename = "gobject/winrt-glib.h")]
namespace winrt.Windows.UI.Notifications {

    [CCode (cname = "winrt_Windows_UI_Notifications_Toast_Dismissal_Reason", cprefix = "WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_", type_id = "winrt_windows_ui_notifications_toast_dismissal_reason_get_type ()")]
    public enum ToastDismissalReason
    {
        Activated,
        ApplicationHidden,
        TimedOut
    }

    [CCode (cname = "NotificationCallbackFailed", has_target = true)]
    public delegate void NotificationCallbackFailed();

    [CCode (cname = "NotificationCallbackActivated", has_target = true)]
    public delegate void NotificationCallbackActivated(string? arguments, string[]? userInput);

    [CCode (cname = "NotificationCallbackDismissed", has_target = true)]
    public delegate void NotificationCallbackDismissed(ToastDismissalReason reason);

    [CCode (type_id = "winrt_windows_ui_notifications_toast_notification_get_type ()")]
	public class ToastNotification : GLib.Object {
		public ToastNotification(string doc);
        public bool ExpiresOnReboot { get; set; }
        public string Tag { get; set; } // TODO: check if valac is cleaning this string
        public string Group { get; set; }

        public EventToken Activated(owned NotificationCallbackActivated handler);
        public void RemoveActivated(EventToken token);

        public EventToken Failed(owned NotificationCallbackFailed handler);
        public void RemoveFailed(EventToken token);

        public EventToken Dismissed(owned NotificationCallbackDismissed handler);
        public void RemoveDismissed(EventToken token);
    }

    [CCode (type_id = "winrt_windows_ui_notifications_toast_notifier_get_type ()")]
	public class ToastNotifier : GLib.Object {
		public ToastNotifier(string aumid);
        public void Show(ToastNotification notification);
        public void Hide(ToastNotification notification);
    }
}