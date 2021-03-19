using Dino.Entities;
using Gtk;

namespace Dino.Ui {

    public class CallWindow : Gtk.Window {
        public string counterpart_display_name { get; set; }

        // TODO should find another place for this
        public CallWindowController controller;

        public Overlay overlay = new Overlay() { visible=true };
        public EventBox event_box = new EventBox() { visible=true };
        public CallBottomBar bottom_bar = new CallBottomBar() { visible=true };
        public Revealer bottom_bar_revealer = new Revealer() { valign=Align.END, transition_type=RevealerTransitionType.CROSSFADE, transition_duration=200, visible=true };
        public HeaderBar header_bar = new HeaderBar() { show_close_button=true, visible=true };
        public Revealer header_bar_revealer = new Revealer() { valign=Align.START, transition_type=RevealerTransitionType.CROSSFADE, transition_duration=200, visible=true };
        public Stack stack = new Stack() { visible=true };
        public Box own_video_box = new Box(Orientation.HORIZONTAL, 0) { expand=true, visible=true };
        private Widget? own_video = null;
        private Box? own_video_border = new Box(Orientation.HORIZONTAL, 0) { expand=true }; // hack to draw a border around our own video, since we apparently can't draw a border around the Gst widget

        private int own_video_width = 150;
        private int own_video_height = 100;

        private bool hide_controll_elements = false;
        private uint hide_controll_handler = 0;
        private Widget? main_widget = null;

        construct {
            header_bar.get_style_context().add_class("call-header-bar");
            header_bar_revealer.add(header_bar);

            this.get_style_context().add_class("dino-call-window");

            bottom_bar_revealer.add(bottom_bar);

            overlay.add_overlay(own_video_box);
            overlay.add_overlay(own_video_border);
            overlay.add_overlay(bottom_bar_revealer);
            overlay.add_overlay(header_bar_revealer);

            event_box.add(overlay);
            add(event_box);

            Util.force_css(own_video_border, "* { border: 1px solid #616161; background-color: transparent; }");
        }

        public CallWindow() {
            event_box.events |= Gdk.EventMask.POINTER_MOTION_MASK;
            event_box.events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
            event_box.events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;

            this.bind_property("counterpart-display-name", header_bar, "title", BindingFlags.SYNC_CREATE);
            this.bind_property("counterpart-display-name", bottom_bar, "counterpart-display-name", BindingFlags.SYNC_CREATE);

            event_box.motion_notify_event.connect(reveal_control_elements);
            event_box.enter_notify_event.connect(reveal_control_elements);
            event_box.leave_notify_event.connect(reveal_control_elements);
            this.configure_event.connect(reveal_control_elements); // upon resizing
            this.configure_event.connect(update_own_video_position);

            this.set_titlebar(new OutsideHeaderBar(this.header_bar) { visible=true });

            reveal_control_elements();
        }

        public void set_video_fallback(StreamInteractor stream_interactor, Conversation conversation) {
            hide_controll_elements = false;

            Box box = new Box(Orientation.HORIZONTAL, 0) { visible=true };
            box.get_style_context().add_class("video-placeholder-box");
            AvatarImage avatar = new AvatarImage() { hexpand=true, vexpand=true, halign=Align.CENTER, valign=Align.CENTER, height=100, width=100, visible=true };
            avatar.set_conversation(stream_interactor, conversation);
            box.add(avatar);

            set_new_main_widget(box);
        }

        public void set_video(Widget widget) {
            hide_controll_elements = true;

            widget.visible = true;
            set_new_main_widget(widget);
        }

        public void set_own_video(Widget? widget_) {
            own_video_box.foreach((widget) => { own_video_box.remove(widget); });

            own_video = widget_;
            if (own_video == null) {
                own_video = new Box(Orientation.HORIZONTAL, 0) { expand=true };
            }
            own_video.visible = true;
            own_video.width_request = 150;
            own_video.height_request = 100;
            own_video_box.add(own_video);

            own_video_border.visible = true;

            update_own_video_position();
        }

        public void set_own_video_ratio(int width, int height) {
            if (width / height > 150 / 100) {
                this.own_video_width = 150;
                this.own_video_height = height * 150 / width;
            } else {
                this.own_video_width = width * 100 / height;
                this.own_video_height = 100;
            }

            own_video.width_request = own_video_width;
            own_video.height_request = own_video_height;

            update_own_video_position();
        }

        public void unset_own_video() {
            own_video_box.foreach((widget) => { own_video_box.remove(widget); });

            own_video_border.visible = false;
        }

        public void set_test_video() {
            hide_controll_elements = true;

            var pipeline = new Gst.Pipeline(null);
            var src = Gst.ElementFactory.make("videotestsrc", null);
            pipeline.add(src);
            Gst.Video.Sink sink = (Gst.Video.Sink) Gst.ElementFactory.make("gtksink", null);
            Gtk.Widget widget;
            sink.get("widget", out widget);
            widget.unparent();
            pipeline.add(sink);
            src.link(sink);
            widget.visible = true;

            pipeline.set_state(Gst.State.PLAYING);

            sink.get_static_pad("sink").notify["caps"].connect(() => {
                int width, height;
                sink.get_static_pad("sink").caps.get_structure(0).get_int("width", out width);
                sink.get_static_pad("sink").caps.get_structure(0).get_int("height", out height);
                widget.width_request = width;
                widget.height_request = height;
            });

            set_new_main_widget(widget);
        }

        private void set_new_main_widget(Widget widget) {
            if (main_widget != null) overlay.remove(main_widget);
            overlay.add(widget);
            main_widget = widget;
        }

        public void set_status(string state) {
            switch (state) {
                case "requested":
                    header_bar.subtitle = _("Sending a call request…");
                    break;
                case "ringing":
                    header_bar.subtitle = _("Ringing…");
                    break;
                case "establishing":
                    header_bar.subtitle = _("Establishing a (peer-to-peer) connection…");
                    break;
                default:
                    header_bar.subtitle = null;
                    break;
            }
        }

        public void show_counterpart_ended(string? reason_name, string? reason_text) {
            hide_controll_elements = false;
            reveal_control_elements();

            string text = "";
            if (reason_name == Xmpp.Xep.Jingle.ReasonElement.SUCCESS) {
                text = _("%s ended the call").printf(counterpart_display_name);
            } else if (reason_name == Xmpp.Xep.Jingle.ReasonElement.DECLINE || reason_name == Xmpp.Xep.Jingle.ReasonElement.BUSY) {
                text = _("%s declined the call").printf(counterpart_display_name);
            } else {
                text = "The call has been terminated: " + (reason_name ?? "") + " " + (reason_text ?? "");
            }

            bottom_bar.show_counterpart_ended(text);
        }

        public bool reveal_control_elements() {
            if (!bottom_bar_revealer.child_revealed) {
                bottom_bar_revealer.set_reveal_child(true);
                header_bar_revealer.set_reveal_child(true);
            }

            if (hide_controll_handler != 0) {
                Source.remove(hide_controll_handler);
                hide_controll_handler = 0;
            }

            if (!hide_controll_elements) {
                return false;
            }

            hide_controll_handler = Timeout.add_seconds(3, () => {
                if (!hide_controll_elements) {
                    return false;
                }

                if (bottom_bar.is_menu_active()) {
                    return true;
                }

                header_bar_revealer.set_reveal_child(false);
                bottom_bar_revealer.set_reveal_child(false);
                hide_controll_handler = 0;
                return false;
            });
            return false;
        }

        private bool update_own_video_position() {
            if (own_video == null) return false;

            int width, height;
            this.get_size(out width,out height);

            own_video.margin_end = own_video.margin_bottom = own_video_border.margin_end = own_video_border.margin_bottom = 20;
            own_video.margin_start = own_video_border.margin_start = width - own_video_width - 20;
            own_video.margin_top = own_video_border.margin_top = height - own_video_height - 20;

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