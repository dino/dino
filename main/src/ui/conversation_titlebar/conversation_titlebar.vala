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
    private Label title_label = new Label("") { visible=true };
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
    private Revealer back_revealer;
    public bool back_button {
        get { return back_revealer.reveal_child; }
        set { back_revealer.reveal_child = value; }
    }
    public signal void back_pressed();

    public ConversationTitlebarCsd() {
        this.get_style_context().add_class("dino-right");
        show_close_button = true;
        hexpand = true;
        back_revealer = new Revealer() { visible = true, transition_type = RevealerTransitionType.SLIDE_RIGHT, transition_duration = 200, can_focus = false, reveal_child = false };
        Button back_button = new Button.from_icon_name("go-previous-symbolic") { visible = true, valign = Align.CENTER, use_underline = true };
        back_button.get_style_context().add_class("image-button");
        back_button.clicked.connect(() => back_pressed());
        back_revealer.add(back_button);
        this.pack_start(back_revealer);
    }

    public void insert_entry(Plugins.ConversationTitlebarEntry entry) {
        Plugins.ConversationTitlebarWidget widget = entry.get_widget(Plugins.WidgetType.GTK);
        Button gtk_widget = (Gtk.Button)widget;
        this.pack_end(gtk_widget);
    }

    /*
     * HdyLeaflet collapses based on natural_width, but labels set natural_width to the width required to have the full
     * text in a single line, thus if the label gets longer, HdyLeaflet would collapse. Work around is to just use the
     * minimum_width as natural_width.
     */
    public override void get_preferred_width(out int minimum_width, out int natural_width) {
        base.get_preferred_width(out minimum_width, out natural_width);
        natural_width = minimum_width;
    }
}

}
