using Gee;
using Xmpp;
using Dino.Entities;
using Gtk;

namespace Dino.Ui {

    public class CallWindow : Gtk.Window {

        public signal void menu_dump_dot();

        public CallWindowController controller;

        public Overlay overlay = new Overlay() { visible=true };
        public Grid grid = new Grid() { visible=true };
        public CallBottomBar bottom_bar = new CallBottomBar() { visible=true };
        public Revealer bottom_bar_revealer = new Revealer() { valign=Align.END, transition_type=RevealerTransitionType.CROSSFADE, transition_duration=200, visible=true };
        public HeaderBar header_bar = new HeaderBar() { valign=Align.START, halign=Align.END, show_close_button=true, visible=true, opacity=0.0 };
        public Revealer header_bar_revealer = new Revealer() { halign=Align.END, valign=Align.START, transition_type=RevealerTransitionType.SLIDE_LEFT, transition_duration=200, visible=true, reveal_child=false };
        public Box own_video_box = new Box(Orientation.HORIZONTAL, 0) { halign=Align.END, valign=Align.END, visible=true };
        private Widget? own_video = null;
        private HashMap<string, ParticipantWidget> participant_widgets = new HashMap<string, ParticipantWidget>();
        private ArrayList<string> participants = new ArrayList<string>();

        private int own_video_width = 150;
        private int own_video_height = 100;

        private bool hide_control_elements = false;
        private uint hide_control_handler = 0;
        public bool controls_active { get; set; default=true; }

        construct {
            header_bar.get_style_context().add_class("call-header-bar");
            header_bar.custom_title = new Box(Orientation.VERTICAL, 0);
            header_bar.spacing = 0;
            header_bar_revealer.add(header_bar);
            bottom_bar_revealer.add(bottom_bar);
            own_video_box.get_style_context().add_class("own-video");

            this.get_style_context().add_class("dino-call-window");

            overlay.add(grid);
            overlay.add_overlay(own_video_box);
            overlay.add_overlay(bottom_bar_revealer);
            overlay.add_overlay(header_bar_revealer);
            overlay.get_child_position.connect(on_get_child_position);

            add(overlay);
        }

        public CallWindow() {
            this.bind_property("controls-active", bottom_bar_revealer, "reveal-child", BindingFlags.SYNC_CREATE);

            this.motion_notify_event.connect(reveal_control_elements);
            this.enter_notify_event.connect(reveal_control_elements);
            this.leave_notify_event.connect(reveal_control_elements);
            this.configure_event.connect(reveal_control_elements); // upon resizing

            this.configure_event.connect(reposition_participant_widgets);

            this.set_titlebar(new OutsideHeaderBar(this.header_bar) { visible=true });

            reveal_control_elements();
        }

        public void add_participant(string participant, ParticipantWidget participant_widget) {
            participant_widget.visible = true;
            this.bind_property("controls-active", participant_widget, "controls-active", BindingFlags.SYNC_CREATE);
            this.bind_property("controls-active", participant_widget.encryption_button, "controls-active", BindingFlags.SYNC_CREATE);

            participants.add(participant);
            participant_widgets[participant] = participant_widget;
            grid.attach(participant_widget, 0, 0);

            reposition_participant_widgets();
        }

        public void remove_participant(string participant) {
            participants.remove(participant);
            grid.remove(participant_widgets[participant]);
            participant_widgets.unset(participant);

            reposition_participant_widgets();
        }

        public void set_video(string participant, Widget widget) {
            participant_widgets[participant].set_video(widget);
            hide_control_elements = true;
            timeout_hide_control_elements();
        }

        public void set_placeholder(string participant, Conversation? conversation, StreamInteractor stream_interactor) {
            participant_widgets[participant].set_placeholder(conversation, stream_interactor);
            hide_control_elements = false;
            foreach (ParticipantWidget participant_widget in participant_widgets.values) {
                if (participant_widget.shows_video) {
                    hide_control_elements = true;
                }
            }

            if (!hide_control_elements) {
                reveal_control_elements();
            }
        }

        private bool reposition_participant_widgets() {
            int width, height;
            this.get_size(out width,out height);
            reposition_participant_widgets_rec(participants, width, height, 0, 0, 0, 0);
            return false;
        }

        private void reposition_participant_widgets_rec(ArrayList<string> participants, int width, int height, int margin_top, int margin_right, int margin_bottom, int margin_left) {
            if (participants.size == 0) return;

            if (participants.size == 1) {
                participant_widgets[participants[0]].margin_top = margin_top;
                participant_widgets[participants[0]].margin_end = margin_right;
                participant_widgets[participants[0]].margin_bottom = margin_bottom;
                participant_widgets[participants[0]].margin_start = margin_left;

                participant_widgets[participants[0]].on_row_changed(margin_top == 0, margin_bottom == 0, margin_left == 0, margin_right == 0);
                return;
            }

            ArrayList<string> first_part = new ArrayList<string>();
            ArrayList<string> last_part = new ArrayList<string>();

            for (int i = 0; i < participants.size; i++) {
                if (i < Math.ceil((double)participants.size / (double)2)) {
                    first_part.add(participants[i]);
                } else {
                    last_part.add(participants[i]);
                }
            }

            if (width > height) {
                reposition_participant_widgets_rec(first_part, width / 2, height, margin_top, margin_right + width / 2, margin_bottom, margin_left);
                reposition_participant_widgets_rec(last_part, width / 2, height, margin_top, margin_right, margin_bottom, margin_left + width / 2);
            } else {
                reposition_participant_widgets_rec(first_part, width, height / 2, margin_top, margin_right, margin_bottom + height / 2, margin_left);
                reposition_participant_widgets_rec(last_part, width, height / 2, margin_top + height / 2, margin_right, margin_bottom, margin_left);
            }
        }

        public void set_own_video(Widget? widget_) {
            own_video_box.foreach((widget) => { own_video_box.remove(widget); });

            own_video = widget_;
            if (own_video == null) {
                own_video = new Box(Orientation.HORIZONTAL, 0) { expand=true };
            }
            own_video.visible = true;
            own_video_box.add(own_video);
        }

        public void set_own_video_ratio(int width, int height) {
            if (width / height > 150 / 100) {
                this.own_video_width = 150;
                this.own_video_height = height * 150 / width;
            } else {
                this.own_video_width = width * 100 / height;
                this.own_video_height = 100;
            }
        }

        public void unset_own_video() {
            own_video_box.foreach((widget) => { own_video_box.remove(widget); });
        }

        public void set_status(string participant_id, string state) {
            participant_widgets[participant_id].set_status(state);
        }

        public void show_counterpart_ended(string who_terminated, string? reason_name, string? reason_text) {
            hide_control_elements = false;
            reveal_control_elements();

            string text = "";
            if (reason_name == Xmpp.Xep.Jingle.ReasonElement.SUCCESS) {
                text = _("%s ended the call").printf(who_terminated);
            } else if (reason_name == Xmpp.Xep.Jingle.ReasonElement.DECLINE || reason_name == Xmpp.Xep.Jingle.ReasonElement.BUSY) {
                text = _("%s declined the call").printf(who_terminated);
            } else {
                if (reason_text == null) {
                    text = "The call has been terminated" + " " + (reason_name ?? "");
                } else {
                    text = reason_text + " " + (reason_name ?? "");
                }
            }

            bottom_bar.show_counterpart_ended(text);
        }

        private bool reveal_control_elements() {
            if (!bottom_bar_revealer.child_revealed) {
                controls_active = true;
            }

            timeout_hide_control_elements();
            return false;
        }

        private void timeout_hide_control_elements() {
            if (hide_control_handler != 0) {
                Source.remove(hide_control_handler);
                hide_control_handler = 0;
            }

            if (!hide_control_elements) {
                return;
            }

            hide_control_handler = Timeout.add_seconds(3, () => {
                if (!hide_control_elements) {
                    return false;
                }

                if (bottom_bar.is_menu_active()) {
                    return false;
                }

                controls_active = false;

                hide_control_handler = 0;
                return false;
            });
        }

        private bool on_get_child_position(Widget widget, out Gdk.Rectangle allocation) {
            if (widget == own_video_box) {
                int width, height;
                this.get_size(out width,out height);

                allocation = Gdk.Rectangle();
                allocation.width = own_video_width;
                allocation.height = own_video_height;
                allocation.x = width - own_video_width - 20;
                allocation.y = height - own_video_height - 20;
                return true;
            }
            return false;
        }
    }

    /* Hack to make the CallHeaderBar feel like a HeaderBar (right click menu, double click, ..) although it isn't set as headerbar.
     * OutsideHeaderBar is set as a headerbar and it doesn't take any space, but claims to take space (which is actually taken by CallHeaderBar).
     */
    public class OutsideHeaderBar : Gtk.Box {
        HeaderBar header_bar;

        public OutsideHeaderBar(HeaderBar header_bar) {
            this.header_bar = header_bar;

            size_allocate.connect_after(on_header_bar_size_allocate);
            header_bar.size_allocate.connect(on_header_bar_size_allocate);
        }

        public void on_header_bar_size_allocate() {
            Allocation header_bar_alloc;
            header_bar.get_allocation(out header_bar_alloc);

            Allocation alloc;
            get_allocation(out alloc);
            alloc.height = header_bar_alloc.height;
            set_allocation(alloc);
        }
    }
}