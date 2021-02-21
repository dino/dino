[CCode (cheader_filename = "gobject/winrt-glib.h")]
namespace winrt.Windows.UI.Notifications {
    [CCode (cname = "Notification_Callback_Simple", has_target = true)]
    public delegate void NotificationCallbackSimple();

    //  [CCode (cname = "Notification_Callback_ActivatedWithActionIndex", has_target = true)]
    //  public delegate void NotificationCallbackWithActionIndex(int actionId);

    //  [CCode (cname = "Notification_Callback_Dismissed", has_target = true)]
    //  public delegate void NotificationCallbackDismissed(DismissedReason reason);

    [CCode (type_id = "winrt_windows_ui_notifications_toast_notification_get_type ()")]
	public class ToastNotification : GLib.Object {
		public ToastNotification(string doc);
        public bool ExpiresOnReboot { get; set; }
        public string Tag { get; set; } // TODO: check if valac is cleaning this string
        public string Group { get; set; }
        public winrt.EventToken Activated(owned NotificationCallbackSimple handler);
        public void RemoveActivatedAction(winrt.EventToken token);
    }
}