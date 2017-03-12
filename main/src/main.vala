using Dino.Entities;
using Dino.Ui;

namespace Dino {

void main(string[] args) {
    try{
        Plugins.Loader loader = new Plugins.Loader(args.length > 0 ? args[0] : null);
        Gtk.init(ref args);
        Dino.Ui.Application app = new Dino.Ui.Application();
        foreach (string plugin in new string[]{"omemo", "openpgp"}) {
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