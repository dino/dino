using Gtk;

public class Dino.Ui.ViewModel.DateSeparatorModel : Object {
    public string date_label { get; set; }
}

public class Dino.Ui.ViewModel.CompatDateSeparatorModel : DateSeparatorModel {
    private DateTime date;
    private uint time_update_timeout = 0;

    public CompatDateSeparatorModel(DateTime date) {
        this.date = date;
        update_time_label();
    }

    private static string get_relative_time(DateTime time) {
        DateTime time_local = time.to_local();
        DateTime now_local = new DateTime.now_local();
        if (time_local.get_year() == now_local.get_year() &&
                time_local.get_month() == now_local.get_month() &&
                time_local.get_day_of_month() == now_local.get_day_of_month()) {
            return _("Today");
        }
        DateTime now_local_minus = now_local.add_days(-1);
        if (time_local.get_year() == now_local_minus.get_year() &&
                time_local.get_month() == now_local_minus.get_month() &&
                time_local.get_day_of_month() == now_local_minus.get_day_of_month()) {
            return _("Yesterday");
        }
        if (time_local.get_year() != now_local.get_year()) {
            return /* xgettext:no-c-format */ time_local.format("%x");
        }
        TimeSpan timespan = now_local.difference(time_local);
        if (timespan < 7 * TimeSpan.DAY) {
            return /* xgettext:no-c-format */ time_local.format(_("%a, %b %d"));
        } else {
            return /* xgettext:no-c-format */ time_local.format(_("%b %d"));
        }
    }

    private static void on_time_update_timeout(CompatDateSeparatorModel self) {
        if (self.time_update_timeout != 0) self.update_time_label();
    }

    private void update_time_label() {
        date_label = get_relative_time(date);
        time_update_timeout = Dino.WeakTimeout.add_seconds_once(get_next_time_change(), this, on_time_update_timeout);
    }

    private int get_next_time_change() {
        DateTime now = new DateTime.now_local();
        return (23 - now.get_hour()) * 3600 + (59 - now.get_minute()) * 60 + (59 - now.get_second()) + 1;
    }

    public override void dispose() {
        base.dispose();

        if (time_update_timeout != 0) {
            Source.remove(time_update_timeout);
            time_update_timeout = 0;
        }
    }
}

public class Dino.Ui.DateSeparator : Gtk.Widget {
    public ViewModel.DateSeparatorModel? model { get; set; }
    public string date_label { get { return label.get_text(); } set { label.set_text(value); } }

    private Label label = new Label("") { halign = Align.CENTER, hexpand = false };
    private Binding? label_text_binding;

    construct {
        layout_manager = new BinLayout();
        halign = Align.CENTER;
        hexpand = true;

        label.add_css_class("dim-label");
        label.attributes = new Pango.AttrList();
        label.attributes.insert(Pango.attr_scale_new(Pango.Scale.SMALL));

        Box box = new Box(Orientation.HORIZONTAL, 10);
        box.append(new Separator(Orientation.HORIZONTAL) { valign=Align.CENTER, hexpand=true });
        box.append(label);
        box.append(new Separator(Orientation.HORIZONTAL) { valign=Align.CENTER, hexpand=true });

        Adw.Clamp clamp = new Adw.Clamp() { maximum_size = 300, tightening_threshold = 300, child = box, halign = Align.CENTER };
        clamp.insert_after(this, null);

        notify["model"].connect(on_model_changed);
    }

    private void on_model_changed() {
        if (label_text_binding != null) label_text_binding.unbind();
        if (model != null) {
            label_text_binding = model.bind_property("date-label", this, "date-label", BindingFlags.SYNC_CREATE);
        } else {
            label_text_binding = null;
        }
    }

    public override void dispose() {
        if (label_text_binding != null) label_text_binding.unbind();
        label_text_binding = null;
        var clamp = get_first_child();
        if (clamp != null) {
            clamp.unparent();
            clamp.dispose();
        }
        base.dispose();
    }
}
