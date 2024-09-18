using Gtk;
using Gee;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public class ConversationTitlebar : Object {

    public signal void back_pressed();

    public new string? title { get { return title_label.label; } set { title_label.label = value; } }
    public new string? subtitle { get { return subtitle_label.label; } set { subtitle_label.label = value; subtitle_label.visible = (value != null); } }
    public bool back_button_visible {
        get { return back_revealer.reveal_child; }
        set { back_revealer.reveal_child = value; }
    }

    public Adw.HeaderBar header_bar = new Adw.HeaderBar();
    private Label title_label = new Label("") { ellipsize=EllipsizeMode.END };
    private Label subtitle_label = new Label("") { use_markup=true, ellipsize=EllipsizeMode.END, visible=false };
    private Revealer back_revealer;

    public ConversationTitlebar() {
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
