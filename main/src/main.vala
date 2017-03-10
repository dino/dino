using Dino.Entities;
using Dino.Ui;

namespace Dino {

void main(string[] args) {
    Gtk.init(ref args);
    Dino.Ui.Application app = new Dino.Ui.Application();
    PluginLoader loader = new PluginLoader();
    foreach(string plugin in new string[]{}) {
        try {
            loader.load(plugin, app);
        } catch (Dino.PluginError e) {
            print(@"Error loading plugin $plugin: $(e.message)\n");
        }
    }
    app.run(args);
}

}