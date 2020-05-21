using Gtk;

namespace Dino.Plugins.Win32Fonts {

public class Plugin : RootInterface, Object {

    public void registered(Dino.Application app) {
        CssProvider larger_fonts = new CssProvider();
        larger_fonts.load_from_resource("/im/dino/Dino/win32-fonts/larger.css");
        StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), larger_fonts, STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void shutdown() { }
}

}
