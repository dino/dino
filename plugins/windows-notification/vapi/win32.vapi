[CCode (cheader_filename = "win32.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.Win32Api {
    [CCode (cname = "IsWindows10")]
    public bool IsWindows10();

    [CCode (cname = "SetProcessAumid")]
    public bool SetProcessAumid(string aumid);
}

