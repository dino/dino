using Gtk;

namespace Dino.Ui {
class SizeRequestBox : Box {
    public SizeRequestMode size_request_mode { get; set; default = SizeRequestMode.CONSTANT_SIZE; }

    public override Gtk.SizeRequestMode get_request_mode() {
        return size_request_mode;
    }
}
}