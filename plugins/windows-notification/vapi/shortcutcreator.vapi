[CCode (cheader_filename = "shortcutcreator.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.ShortcutCreator {
    [CCode (cname = "TryCreateShortcut")]
    public bool TryCreateShortcut(string aumid);
}