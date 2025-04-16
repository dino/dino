using Dino.Entities;
using Dino.Ui;

extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino {

void main(string[] args) {

    try{
#if _WIN32
        var pangocairoResult = Environment.set_variable("PANGOCAIRO_BACKEND", "fontconfig", false);
        if (!pangocairoResult) {
            warning("Unable to set PANGOCAIRO_BACKEND environment variable to fontconfig");
        }
#endif
        string? exec_path = args.length > 0 ? args[0] : null;
        SearchPathGenerator search_path_generator = new SearchPathGenerator(exec_path);
        Intl.textdomain(GETTEXT_PACKAGE);
        internationalize(GETTEXT_PACKAGE, search_path_generator.get_locale_path(GETTEXT_PACKAGE, LOCALE_INSTALL_DIR));

        Gtk.init();
        Dino.Ui.Application app = new Dino.Ui.Application() { search_path_generator=search_path_generator };
        Plugins.Loader loader = new Plugins.Loader(app);
        loader.load_all();

        app.run(args);
        loader.shutdown();
    } catch (Error e) {
        warning(@"Fatal error: $(e.message)");
    }
}

}
