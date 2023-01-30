using Gtk;
using Gee;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public interface ConversationTitlebar : Object {
    public abstract string? subtitle { get; set; }
    public abstract string? title { get; set; }

    public abstract void insert_button(Widget button);
    public abstract Widget get_widget();

    public abstract bool back_button_visible{ get; set; }
    public signal void back_pressed();
}

public class ConversationTitlebarNoCsd : ConversationTitlebar, Object {

    public Box main = new Box(Orientation.HORIZONTAL, 0);

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

    public bool back_button_visible {
        get { return back_revealer.reveal_child; }
        set { back_revealer.reveal_child = value; }
    }

    private Box widgets_box = new Box(Orientation.HORIZONTAL, 7) { margin_start=15, valign=Align.END };
    private Label title_label = new Label("") { ellipsize=EllipsizeMode.END };
    private Label subtitle_label = new Label("") { use_markup=true, ellipsize=EllipsizeMode.END, visible=false };
    private Revealer back_revealer;

    construct {
        Box content_box = new Box(Orientation.HORIZONTAL, 0) { margin_start=15, margin_end=10, hexpand=true };
        main.append(content_box);

        back_revealer = new Revealer() { visible = true, transition_type = RevealerTransitionType.SLIDE_RIGHT, transition_duration = 200, can_focus = false, reveal_child = false };
        Button back_button = new Button.from_icon_name("go-previous-symbolic") { visible = true, valign = Align.CENTER, use_underline = true };
        back_button.get_style_context().add_class("image-button");
        back_button.clicked.connect(() => back_pressed());
        back_revealer.set_child(back_button);
        content_box.append(back_revealer);

        Box titles_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER, hexpand=true };
        content_box.append(titles_box);

        titles_box.append(title_label);
        subtitle_label.attributes = new AttrList();
        subtitle_label.add_css_class("dim-label");
        titles_box.append(subtitle_label);

        content_box.append(widgets_box);
    }

    public ConversationTitlebarNoCsd() {
        main.add_css_class("dino-header-right");
    }

    public void insert_button(Widget button) {
        widgets_box.prepend(button);
    }

    public Widget get_widget() {
        return main;
    }
}

public class ConversationTitlebarCsd : ConversationTitlebar, Object {

    public new string? title { get { return title_label.label; } set { title_label.label = value; } }
    public new string? subtitle { get { return subtitle_label.label; } set { subtitle_label.label = value; subtitle_label.visible = (value != null); } }
    public bool back_button_visible {
        get { return back_revealer.reveal_child; }
        set { back_revealer.reveal_child = value; }
    }

    public Adw.HeaderBar header_bar = new Adw.HeaderBar();
    private Label title_label = new Label("") { ellipsize=EllipsizeMode.END };
    private Label subtitle_label = new Label("") { ellipsize=EllipsizeMode.END, visible=false };
    private Revealer back_revealer;

    public ConversationTitlebarCsd() {
        Box titles_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER };
        title_label.attributes = new AttrList();
        title_label.attributes.insert(Pango.attr_weight_new(Weight.BOLD));
        titles_box.append(title_label);
        subtitle_label.attributes = new AttrList();
        subtitle_label.attributes.insert(Pango.attr_scale_new(Pango.Scale.SMALL));
        subtitle_label.add_css_class("dim-label");
        titles_box.append(subtitle_label);

        back_revealer = new Revealer() { visible = true, transition_type = RevealerTransitionType.SLIDE_RIGHT, transition_duration = 200, can_focus = false, reveal_child = false };
        Button back_button = new Button.from_icon_name("go-previous-symbolic") { visible = true, valign = Align.CENTER, use_underline = true };
        back_button.get_style_context().add_class("image-button");
        back_button.clicked.connect(() => back_pressed());
        back_revealer.set_child(back_button);
        header_bar.pack_start(back_revealer);

        header_bar.set_title_widget(titles_box);
    }

    public void insert_button(Widget button) {
        header_bar.pack_end(button);
    }

    public Widget get_widget() {
        return header_bar;
    }
}

}
