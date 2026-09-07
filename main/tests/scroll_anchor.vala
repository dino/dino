using Gtk;

// Real GTK allocations, synthetic messages: no account or database is needed.
private class Timeline : Object {
    public Fixed root = new Fixed();
    public Gee.List<Widget> rows = new Gee.ArrayList<Widget>();
    public Adjustment adjustment = new Adjustment(850, 0, 2000, 1, 100, 300);
    public Dino.Ui.ScrollAnchor anchor = new Dino.Ui.ScrollAnchor();
    private double previous_value;

    public Timeline() {
        for (int i = 0; i < 20; i++) {
            var row = new Label("Synthetic message %d".printf(i));
            rows.add(row);
            root.put(row, 0, i * 100);
        }
        root.allocate(600, 2000, -1, null);
        anchor.capture(root, rows);
    }

    public void grow(int first, int delta) {
        previous_value = adjustment.value;
        for (int i = first; i < rows.size; i++) {
            double x, y;
            rows[i].translate_coordinates(root, 0, 0, out x, out y);
            root.move(rows[i], 0, y + delta);
        }
        root.allocate(600, (int) adjustment.upper + delta, -1, null);
        adjustment.configure(adjustment.value, 0, adjustment.upper + delta, 1, 100, 300);
    }

    public void restore() {
        anchor.restore(adjustment, root, rows, previous_value);
        anchor.capture(root, rows);
    }
}

private void expect_position(double actual, double expected) {
    if (Math.fabs(actual - expected) > 0.5) {
        Test.message("expected %.1f, got %.1f", expected, actual);
        Test.fail();
    }
}

int main(string[] args) {
    Test.init(ref args);
    if (!Gtk.init_check()) {
        stderr.printf("A GTK display is required (e.g. xvfb-run -a meson test -C build).\n");
        return 77;
    }
    Test.add_func("/scroll/history-added-below", () => {
        var t = new Timeline();
        t.grow(15, 200);
        t.restore();
        expect_position(t.adjustment.value, 850);
    });
    Test.add_func("/scroll/history-added-above", () => {
        var t = new Timeline();
        t.grow(0, 200);
        t.restore();
        expect_position(t.adjustment.value, 1050);
    });
    Test.add_func("/scroll/repeated-image-expansion", () => {
        var t = new Timeline();
        for (int i = 0; i < 100; i++) {
            t.grow(i % 2 == 0 ? 0 : 15, 10);
            t.restore();
        }
        expect_position(t.adjustment.value, 1350);
    });
    Test.add_func("/scroll/user-scroll-before-reflow", () => {
        var t = new Timeline();
        t.adjustment.value = 1250;
        t.grow(11, 100);
        t.restore();
        expect_position(t.adjustment.value, 1350);
    });
    Test.add_func("/scroll/shrink-clamps-adjustment", () => {
        var t = new Timeline();
        t.adjustment.value = 1450;
        for (int i = 0; i < 7; i++) {
            var row = t.rows[0];
            t.anchor.forget(row);
            t.root.remove(row);
            t.rows.remove_at(0);
        }
        t.grow(0, -700);
        t.restore();
        expect_position(t.adjustment.value, 750);
    });
    Test.add_func("/scroll/clear-for-new-conversation", () => {
        var t = new Timeline();
        t.anchor.clear();
        t.grow(0, 200);
        t.restore();
        expect_position(t.adjustment.value, 850);
    });
    return Test.run();
}
