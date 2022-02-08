using Pango;
using Gee;
using Xmpp;
using Dino.Entities;
using Gtk;

namespace Dino.Ui {

    public class ParticipantWidget : Gtk.Overlay {

        public Widget main_widget;
        public Box outer_box = new Box(Orientation.HORIZONTAL, 0) { valign=Align.START, visible=true };
        public Box inner_box = new Box(Orientation.HORIZONTAL, 0) { margin_start=5, margin_top=5, hexpand=true, visible=true };
        public Box title_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER, hexpand=true, visible=true };
        public CallEncryptionButton encryption_button = new CallEncryptionButton() { opacity=0, relief=ReliefStyle.NONE, height_request=30, width_request=30, margin_end=5, visible=true };
        public Label status_label = new Label("") { ellipsize=EllipsizeMode.MIDDLE };
        public Label name_label = new Label("") { ellipsize=EllipsizeMode.MIDDLE, visible=true };
        public Button menu_button = new Button.from_icon_name("view-more-horizontal-symbolic") { relief=ReliefStyle.NONE, visible=true };
        public bool shows_video = false;
        public string? participant_name;

        bool is_highest_row = false;
        bool is_lowest_row = false;
        public bool controls_active { get; set; }

        public ParticipantWidget(string participant_name) {
            this.participant_name = participant_name;
            name_label.label = participant_name;

            name_label.attributes = new AttrList();
            name_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));

            name_label.attributes = new AttrList();
            name_label.attributes.filter((attr) => attr.equal(attr_scale_new(0.9)));
            status_label.get_style_context().add_class("dim-label");

            Util.force_css(outer_box, "* { color: white; text-shadow: 1px 1px black; }");
            menu_button.get_style_context().add_class("participant-title-button");
            encryption_button.get_style_context().add_class("participant-title-button");

            title_box.add(name_label);
            title_box.add(status_label);

            outer_box.add(inner_box);

            inner_box.add(menu_button);
            inner_box.add(encryption_button);
            inner_box.add(title_box);
            inner_box.add(new Button.from_icon_name("go-up-symbolic") { opacity=0, visible=true });
            inner_box.add(new Button.from_icon_name("go-up-symbolic") { opacity=0, visible=true });

            this.add_overlay(outer_box);

            this.notify["controls-active"].connect(reveal_or_hide_controls);
        }

        public void on_show_names_changed(bool show) {
            name_label.visible = show;
            reveal_or_hide_controls();
        }

        public void on_highest_row_changed(bool is_highest) {
            is_highest_row = is_highest;
            reveal_or_hide_controls();
        }

        public void on_lowest_row_changed(bool is_lowest) {
            is_lowest_row = is_lowest;
            reveal_or_hide_controls();
        }

        public void set_video(Widget widget) {
            shows_video = true;
            widget.visible = true;
            set_participant_widget(widget);
        }

        public void set_placeholder(Conversation? conversation, StreamInteractor stream_interactor) {
            shows_video = false;
            Box box = new Box(Orientation.HORIZONTAL, 0) { visible=true };
            box.get_style_context().add_class("video-placeholder-box");
            AvatarImage avatar = new AvatarImage() { allow_gray=false, hexpand=true, vexpand=true, halign=Align.CENTER, valign=Align.CENTER, height=100, width=100, visible=true };
            if (conversation != null) {
                avatar.set_conversation(stream_interactor, conversation);
            } else {
                avatar.set_text("?", false);
            }
            box.add(avatar);

            set_participant_widget(box);
        }

        private void set_participant_widget(Widget widget) {
            widget.expand = true;
            if (main_widget != null) this.remove(main_widget);
            main_widget = widget;
            this.add(main_widget);
        }

        public void set_status(string state) {
            status_label.visible = true;

            if (state == "requested") {
                status_label.label =  _("Calling…");
            } else if (state == "ringing") {
                status_label.label = _("Ringing…");
            } else if (state == "establishing") {
                status_label.label = _("Connecting…");
            } else {
                status_label.visible = false;
            }
        }

        private void reveal_or_hide_controls() {
            if (controls_active && name_label.visible) {
                title_box.opacity = 1;
                menu_button.opacity = 1;
            } else {
                title_box.opacity = 0;
                menu_button.opacity = 0;
            }
            if (is_highest_row && controls_active) {
                outer_box.get_style_context().add_class("call-header-bar");
            } else {
                outer_box.get_style_context().remove_class("call-header-bar");
            }
        }
    }
}