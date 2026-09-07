using Gee;
using Gtk;

namespace Dino.Ui {

public class ScrollAnchor : Object {
    private Gee.HashMap<Widget, int> widget_positions = new Gee.HashMap<Widget, int>();

    public void forget(Widget widget) {
        widget_positions.unset(widget);
    }

    public void clear() {
        widget_positions.clear();
    }

    public void restore(Adjustment adjustment, Widget coordinate_root, Gee.List<Widget> widget_order, double previous_value) {
        // GtkAdjustment may already have clamped value to a smaller range.
        // Both the anchor and its viewport offset refer to the old layout.
        Widget? anchor = find(previous_value, widget_order);
        if (anchor == null) return;

        int old_y = widget_positions[anchor];
        double x, new_y;
        if (anchor.translate_coordinates(coordinate_root, 0, 0, out x, out new_y)) {
            adjustment.value = previous_value + new_y - old_y;
        }
    }

    public void capture(Widget coordinate_root, Gee.List<Widget> widget_order) {
        widget_positions.clear();
        foreach (Widget widget in widget_order) {
            double x, y;
            if (widget.translate_coordinates(coordinate_root, 0, 0, out x, out y)) {
                widget_positions[widget] = (int) Math.round(y);
            }
        }
    }

    private Widget? find(double viewport_top, Gee.List<Widget> widget_order) {
        Widget? first = null;
        Widget? anchor = null;

        foreach (Widget widget in widget_order) {
            if (!widget_positions.has_key(widget)) continue;
            if (first == null) first = widget;

            if (widget_positions[widget] <= viewport_top + 1) {
                anchor = widget;
            } else {
                break;
            }
        }
        return anchor ?? first;
    }
}

}
