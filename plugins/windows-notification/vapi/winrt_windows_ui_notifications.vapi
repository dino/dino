[CCode (cheader_filename = "gobject/winrt-glib.h")]
namespace winrt.Windows.UI.Notifications {
    [CCode (cname = "NotificationCallbackSimple", has_target = true)]
    public delegate void NotificationCallbackSimple();

    [CCode (cname = "NotificationCallbackActivated", has_target = true)]
    public delegate void NotificationCallbackActivated(string? arguments, string[]? userInput);

    //  [CCode (cname = "Notification_Callback_Dismissed", has_target = true)]
    //  public delegate void NotificationCallbackDismissed(DismissedReason reason);

    [CCode (type_id = "winrt_windows_ui_notifications_toast_notification_get_type ()")]
	public class ToastNotification : GLib.Object {
		public ToastNotification(string doc);
        public bool ExpiresOnReboot { get; set; }
        public string Tag { get; set; } // TODO: check if valac is cleaning this string
        public string Group { get; set; }
        public winrt.EventToken Activated(owned NotificationCallbackActivated handler);
        public void RemoveActivatedAction(winrt.EventToken token);
    }
}