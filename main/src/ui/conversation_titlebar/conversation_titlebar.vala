using Gtk;
using Gee;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public interface ConversationTitlebar: Widget {
    public abstract string? subtitle { get; set; }
    public abstract string? title { get; set; }
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

    private Box content_box = new Box(Orientation.HORIZONTAL, 0) { margin=5, margin_start=15, margin_end=5, hexpand=true, visible=true };
    private Label title_label = new Label("") { visible=true };
    private Label subtitle_label = new Label("") { use_markup=true, ellipsize=EllipsizeMode.END, visible=false };
    public GlobalSearchButton search_button = new GlobalSearchButton() { visible = true };

    construct {
        this.add(content_box);

        Box titles_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER, hexpand=true, visible=true };
        content_box.add(titles_box);

        titles_box.add(title_label);
        subtitle_label.attributes = new AttrList();
        subtitle_label.get_style_context().add_class("dim-label");
        titles_box.add(subtitle_label);

        Box placeholder_box = new Box(Orientation.VERTICAL, 0) { visible=true };
        placeholder_box.add(new Label("") { xalign=0, visible=true });
        placeholder_box.add(new Label("<span size='small'> </span>") { use_markup=true, xalign=0, visible=true });
        content_box.add(placeholder_box);
    }

    public ConversationTitlebarNoCsd() {
        this.get_style_context().add_class("dino-header-right");
        hexpand = true;
        search_button.set_image(new Gtk.Image.from_icon_name("system-search-symbolic", Gtk.IconSize.MENU) { visible = true });

        Application app = GLib.Application.get_default() as Application;
        foreach(var e in app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                Button gtk_widget = (Gtk.Button)widget;
                gtk_widget.relief = ReliefStyle.NONE;
                content_box.add(gtk_widget);
            }
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

        Application app = GLib.Application.get_default() as Application;
        ArrayList<Plugins.ConversationTitlebarWidget> widgets = new ArrayList<Plugins.ConversationTitlebarWidget>();
        foreach(var e in app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                widgets.insert(0, widget);
            }
        }
        foreach (var w in widgets) {
            Button gtk_widget = (Gtk.Button)w;
            this.pack_end(gtk_widget);
        }
    }
}

}
