[CCode (cheader_filename = "DinoWinToastLib.h")]
namespace DinoWinToast {

    [CCode (cname = "dinoWinToastLib_Notification_Reason", cprefix = "Reason_")]
    public enum Reason {
        Activated,
        ApplicationHidden,
        TimedOut
    }

    [CCode (cname = "dinoWinToastLib_Notification_Callback_Simple", has_target = true)]
    public delegate void NotificationCallbackSimple();

    [CCode (cname = "dinoWinToastLib_Notification_Callback_ActivatedWithActionIndex", has_target = true)]
    public delegate void NotificationCallbackWithActionIndex(int actionId);

    [CCode (cname = "dinoWinToastLib_Notification_Callback_Dismissed", has_target = true)]
    public delegate void NotificationCallbackDismissed(Reason reason);

    [CCode (cname = "dinoWinToastLib_Notification_Callbacks", free_function = "dinoWinToastLib_DestroyCallbacks")]
    [Compact]
    public class Callbacks {
        [CCode (delegate_target_cname = "activated_context", destroy_notify_cname = "activated_free")]
        public NotificationCallbackSimple activated;

        [CCode (delegate_target_cname = "activatedWithIndex_context", destroy_notify_cname = "activatedWithIndex_free")]
        public NotificationCallbackWithActionIndex activatedWithIndex;

        [CCode (delegate_target_cname = "dismissed_context", destroy_notify_cname = "dismissed_free")]
        public NotificationCallbackDismissed dismissed;

        [CCode (delegate_target_cname = "failed_context", destroy_notify_cname = "failed_free")]
        public NotificationCallbackSimple failed;

        [CCode (cname = "dinoWinToastLib_NewCallbacks")]
        public Callbacks();
    }

    [CCode (cname = "dinoWinToastLib_Init")]
    public int Init();
    
    [CCode (cname = "dinoWinToastLib_ShowMessage")]
    public int64 ShowMessage(DinoWinToastTemplate templ, Callbacks callbacks);

    [CCode (cname = "dinoWinToastLib_RemoveNotification")]
    public bool RemoveNotification(int64 notification_id);
}

