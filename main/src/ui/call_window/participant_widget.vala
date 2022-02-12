using Pango;
using Gee;
using Xmpp;
using Dino.Entities;
using Gtk;

namespace Dino.Ui {

    public class ParticipantWidget : Gtk.Overlay {

        public Widget main_widget;
        public HeaderBar header_bar = new HeaderBar() { valign=Align.START, visible=true };
        public Box inner_box = new Box(Orientation.HORIZONTAL, 0) { margin_start=5, margin_top=5, hexpand=true, visible=true };
        public Box title_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER, hexpand=true, visible=true };
        public CallEncryptionButton encryption_button = new CallEncryptionButton() { opacity=0, relief=ReliefStyle.NONE, height_request=30, width_request=30, margin_end=5, visible=true };
        public MenuButton menu_button = new MenuButton() { relief=ReliefStyle.NONE, visible=true, image=new Image.from_icon_name("open-menu-symbolic", IconSize.MENU) };
        public Button invite_button = new Button.from_icon_name("dino-account-plus") { relief=ReliefStyle.NONE, visible=true };
        public bool shows_video = false;
        public string? participant_name;

        bool is_highest_row = false;
        bool is_start_row = false;
        public bool controls_active { get; set; }
        public bool may_show_invite_button { get; set; }

        public signal void debug_information_clicked();
        public signal void invite_button_clicked();

        public ParticipantWidget(string participant_name) {
            this.participant_name = participant_name;
            header_bar.title = participant_name;
            header_bar.get_style_context().add_class("participant-header-bar");
            header_bar.pack_start(invite_button);
            header_bar.pack_start(encryption_button);
            header_bar.pack_end(menu_button);

            menu_button.popover = create_menu();
            invite_button.clicked.connect(() => invite_button_clicked());

            this.add_overlay(header_bar);

            this.notify["controls-active"].connect(reveal_or_hide_controls);
            this.notify["may-show-invite-button"].connect(reveal_or_hide_controls);
        }

        public void on_row_changed(bool is_highest, bool is_lowest, bool is_start, bool is_end) {
            this.is_highest_row = is_highest;
            this.is_start_row = is_start;

            header_bar.show_close_button = is_highest_row;
            if (is_highest_row) {
                header_bar.get_style_context().add_class("call-header-background");
                Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
                if (gtk_settings != null) {
                    string[] buttons = gtk_settings.gtk_decoration_layout.split(":");
                    header_bar.decoration_layout = (is_start ? buttons[0] : "") + ":" + (is_end && buttons.length == 2 ? buttons[1] : "");
                }
            } else {
                header_bar.get_style_context().remove_class("call-header-background");
            }
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

        private PopoverMenu create_menu() {
            PopoverMenu menu = new PopoverMenu();
            Box box = new Box(Orientation.VERTICAL, 0) { margin=10, visible=true };
            ModelButton debug_information_button = new ModelButton() { text=_("Debug information"), visible=true };
            debug_information_button.clicked.connect(() => debug_information_clicked());
            box.add(debug_information_button);
            menu.add(box);
            return menu;
        }

        public void set_status(string state) {
            if (state == "requested") {
                header_bar.subtitle =  _("Calling…");
            } else if (state == "ringing") {
                header_bar.subtitle = _("Ringing…");
            } else if (state == "establishing") {
                header_bar.subtitle = _("Connecting…");
            } else {
                header_bar.subtitle = "";
            }
        }

        private void reveal_or_hide_controls() {
            header_bar.opacity = controls_active ? 1.0 : 0.0;
            invite_button.visible = may_show_invite_button && is_highest_row && is_start_row;
        }
    }
}