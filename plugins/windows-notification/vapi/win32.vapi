[CCode (cheader_filename = "win32.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.Win32Api {
    [CCode (cname = "SupportsModernNotifications")]
    public bool SupportsModernNotifications();

    [CCode (cname = "SetAppModelID")]
    public bool SetAppModelID(string aumid);
}

