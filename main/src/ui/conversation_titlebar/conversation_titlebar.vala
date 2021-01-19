using Gtk;
using Gee;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public interface ConversationTitlebar : Widget {
    public abstract string? subtitle { get; set; }
    public abstract string? title { get; set; }

    public abstract void insert_entry(Plugins.ConversationTitlebarEntry entry);
}

public class ConversationTitlebarNoCsd : ConversationTitlebar, Gtk.Box {

    public string? title {
        get { return title_label.label; }
        set { this.title_label.label = value; }
    }

    public string? subtitle {
        get { return subtitle_label.label; }
        set {
            this.subtitle_label.label = "<span size='small'>" + value + "</span>";
            this.subtitle_label.visible = (value != null);
        }
    }

    private Box widgets_box = new Box(Orientation.HORIZONTAL, 0) { margin_start=15, valign=Align.END, visible=true };
    private Label title_label = new Label("") { ellipsize=EllipsizeMode.END, visible=true };
    private Label subtitle_label = new Label("") { use_markup=true, ellipsize=EllipsizeMode.END, visible=false };

    construct {
        Box content_box = new Box(Orientation.HORIZONTAL, 0) { margin=5, margin_start=15, margin_end=10, hexpand=true, visible=true };
        this.add(content_box);

        Box titles_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER, hexpand=true, visible=true };
        content_box.add(titles_box);

        titles_box.add(title_label);
        subtitle_label.attributes = new AttrList();
        subtitle_label.get_style_context().add_class("dim-label");
        titles_box.add(subtitle_label);

        content_box.add(widgets_box);
    }

    public ConversationTitlebarNoCsd() {
        this.get_style_context().add_class("dino-header-right");
    }

    public void insert_entry(Plugins.ConversationTitlebarEntry entry) {
        Plugins.ConversationTitlebarWidget widget = entry.get_widget(Plugins.WidgetType.GTK);
        if (widget != null) {
            Button gtk_widget = (Gtk.Button) widget;
            gtk_widget.relief = ReliefStyle.NONE;
            widgets_box.pack_end(gtk_widget);
        }
    }
}

public class ConversationTitlebarCsd : ConversationTitlebar, Gtk.HeaderBar {

    public new string? title { get { return this.get_title(); } set { base.set_title(value); } }
    public new string? subtitle { get { return this.get_subtitle(); } set { base.set_subtitle(value); } }

    public ConversationTitlebarCsd() {
        this.get_style_context().add_class("dino-right");
        show_close_button = true;
        hexpand = true;
    }

    public void insert_entry(Plugins.ConversationTitlebarEntry entry) {
        Plugins.ConversationTitlebarWidget widget = entry.get_widget(Plugins.WidgetType.GTK);
        Button gtk_widget = (Gtk.Button)widget;
        this.pack_end(gtk_widget);
    }
}

}
