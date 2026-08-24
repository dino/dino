[CCode (cheader_filename = "enums.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.Enums {
    [CCode (cname = "Dismissed_Reason", cprefix = "Dismissed_Reason_")]
    public enum DismissedReason {
        Activated,
        ApplicationHidden,
        TimedOut
    }
}