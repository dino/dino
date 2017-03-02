using Dino.Entities;
using Dino.Ui;

namespace Dino {

    void main(string[] args) {
        Notify.init("dino");
        Gtk.init(ref args);
        Dino.Ui.Application app = new Dino.Ui.Application();
        app.run(args);
    }
}