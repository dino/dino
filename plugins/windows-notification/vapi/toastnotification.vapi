using Dino.Plugins.WindowsNotification.Vapi.Callbacks;

[CCode (cheader_filename = "toastnotification.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.ToastNotification {
    [CCode (cname = "DinoToastNotification_t", copy_function = "CopyNotification", free_function = "DestroyNotification")]
    [Compact]
    public class ToastNotification {
        [CCode (cname = "NewNotification")]
        public ToastNotification();

        public SimpleNotificationCallback Activated
        {
            [CCode (cname = "set_Activated")]
            set;
        }

        public ActivatedWithActionIndexNotificationCallback ActivatedWithIndex
        {
            [CCode (cname = "set_ActivatedWithIndex")]
            set;
        }

        public DismissedNotificationCallback Dismissed
        {
            [CCode (cname = "set_Dismissed")]
            set;
        }

        public SimpleNotificationCallback Failed
        {
            [CCode (cname = "set_Failed")]
            set;
        }
    }
}

