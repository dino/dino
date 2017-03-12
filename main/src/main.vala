using Dino.Entities;
using Dino.Ui;

namespace Dino {

void main(string[] args) {
    Gtk.init(ref args);
    Dino.Ui.Application app = new Dino.Ui.Application();
    Plugins.Loader loader = new Plugins.Loader();
    foreach(string plugin in new string[]{"omemo", "openpgp"}) {
        try {
            loader.load(plugin, app);
        } catch (Plugins.Error e) {
            print(@"Error loading plugin $plugin: $(e.message)\n");
        }
    }
    app.run(args);
    loader.shutdown();
}

}