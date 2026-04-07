namespace Dino {
    private const string CHECK_WIDGET_LEAK_ID = "dino_check_widget_leak_id";
    private const string CHECK_WIDGET_LEAK_NAME = "dino_check_widget_leak_name";
    private const string CHECK_WIDGET_LEAK_ACTIVE = "dino_check_widget_leak_active";
    private static void check_widget_leak_timeout_reached(Gtk.Widget widget) {
        string name = widget.get_data(CHECK_WIDGET_LEAK_NAME) ?? widget.get_type().name();
        warning("%s likely leaked", name);
        widget.set_data(CHECK_WIDGET_LEAK_ID, 0);
    }
    private static void check_widget_leak_disposed(Object widget) {
        uint timeout_id = widget.get_data(CHECK_WIDGET_LEAK_ID);
        if (timeout_id != 0) Source.remove(timeout_id);
        widget.set_data(CHECK_WIDGET_LEAK_ID, 0);
    }
    private static void check_widget_leak_unrealized(Gtk.Widget widget) {
        widget.set_data(CHECK_WIDGET_LEAK_ID, WeakTimeout.add_seconds_once(1, widget, check_widget_leak_timeout_reached));
        widget.weak_ref(check_widget_leak_disposed);
    }
    private static void check_widget_leak_realized(Gtk.Widget widget) {
        uint timeout_id = widget.get_data(CHECK_WIDGET_LEAK_ID);
        if (timeout_id != 0) Source.remove(timeout_id);
        widget.set_data(CHECK_WIDGET_LEAK_ID, 0);
        string name = widget.get_type().name();
        Gtk.Widget parent = widget.parent;
        while (parent != null) {
            name = parent.get_type().name() + " > " + name;
            if (name.has_prefix("Dino")) break;
            parent = parent.parent;
        }
        widget.set_data(CHECK_WIDGET_LEAK_NAME, name);
    }
    public static Gtk.Widget check_widget_leak(Gtk.Widget widget) {
        if (is_leak_check_enabled() && !widget.get_data<bool>(CHECK_WIDGET_LEAK_ACTIVE)) {
            widget.set_data(CHECK_WIDGET_LEAK_ACTIVE, true);
            widget.set_data(CHECK_WIDGET_LEAK_ID, 0);
            widget.realize.connect(check_widget_leak_realized);
            widget.unrealize.connect(check_widget_leak_unrealized);
            if (widget.get_realized()) {
                check_widget_leak_realized(widget);
            }
        }
        return widget;
    }

    public static bool is_leak_check_enabled() {
        return Environment.get_variable("DINO_CHECK_LEAK") == "1";
    }
}