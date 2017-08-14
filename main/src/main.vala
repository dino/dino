using Dino.Entities;
using Dino.Ui;

extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino {

void main(string[] args) {

    try{
        string? exec_path = args.length > 0 ? args[0] : null;
        SearchPathGenerator search_path_generator = new SearchPathGenerator(exec_path);
        if (exec_path != null && exec_path.contains(Path.DIR_SEPARATOR_S)) {
            string bindir = Path.get_dirname(exec_path);
            if (FileUtils.test(Path.build_filename(bindir, "gschemas.compiled"), FileTest.IS_REGULAR)) {
                Environment.set_variable("GSETTINGS_SCHEMA_DIR", Path.get_dirname(exec_path), false);
            }
        }
        Intl.textdomain(GETTEXT_PACKAGE);
        internationalize(GETTEXT_PACKAGE, search_path_generator.get_locale_path(GETTEXT_PACKAGE, LOCALE_INSTALL_DIR));

        Plugins.Loader loader = new Plugins.Loader(exec_path);
        Gtk.init(ref args);
        Dino.Ui.Application app = new Dino.Ui.Application() { search_path_generator=search_path_generator };

        app.add_main_option("plugin-paths", 0, 0, OptionArg.NONE, "Display plugin search paths and exit", null);
        app.handle_local_options.connect((options) => {
            Variant v = options.lookup_value("plugin-paths", VariantType.BOOLEAN);
            if (v != null && v.get_boolean()) {
                loader.print_search_paths();
                return 0;
            }
            return -1;
        });

        foreach (string plugin in new string[]{"omemo", "openpgp", "http-files"}) {
            try {
                loader.load(plugin, app);
            } catch (Error e) {
                print(@"Error loading plugin $plugin: $(e.message)\n");
            }
        }
        app.run(args);
        loader.shutdown();
    } catch (Error e) {
        print(@"Fatal error: $(e.message)\n");
    }
}

}
