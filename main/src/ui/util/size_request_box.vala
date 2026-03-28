using Gtk;

namespace Dino.Ui {
public class SizeRequestBox : Box {
    public SizeRequestMode size_request_mode { get; set; default = SizeRequestMode.CONSTANT_SIZE; }

    public override Gtk.SizeRequestMode get_request_mode() {
        return size_request_mode;
    }
}

public class SizeRequestBin : Widget {
    public SizeRequestMode size_request_mode { get; set; default = SizeRequestMode.CONSTANT_SIZE; }

    construct {
        this.layout_manager = new BinLayout();
    }

    public override void compute_expand_internal(out bool hexpand, out bool vexpand) {
        hexpand = false;
        vexpand = false;
        Widget child = get_first_child();
        while (child != null) {
            hexpand = hexpand || child.compute_expand(Orientation.HORIZONTAL);
            vexpand = vexpand || child.compute_expand(Orientation.VERTICAL);
            child = child.get_next_sibling();
        }
    }

    public override Gtk.SizeRequestMode get_request_mode() {
        return size_request_mode;
    }
}
}
