using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

    public class CallMetaItem : ConversationSummary.ContentMetaItem {

        private StreamInteractor stream_interactor;

        public CallMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
            base(content_item);
            this.stream_interactor = stream_interactor;
        }

        public override Object? get_widget(Plugins.WidgetType type) {
            CallItem call_item = content_item as CallItem;
            return new CallWidget(stream_interactor, call_item.call, call_item.conversation) { visible=true };
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
    }

    [GtkTemplate (ui = "/im/dino/Dino/call_widget.ui")]
    public class CallWidget : SizeRequestBox {

        [GtkChild] public Image image;
        [GtkChild] public Label title_label;
        [GtkChild] public Label subtitle_label;
        [GtkChild] public Revealer incoming_call_revealer;
        [GtkChild] public Button accept_call_button;
        [GtkChild] public Button reject_call_button;

        private StreamInteractor stream_interactor;
        private Call call;
        private Conversation conversation;
        public Call.State call_state { get; set; } // needs to be public for binding
        private uint time_update_handler_id = 0;

        construct {
            margin_top = 4;
            size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
        }

        public CallWidget(StreamInteractor stream_interactor, Call call, Conversation conversation) {
            this.stream_interactor = stream_interactor;
            this.call = call;
            this.conversation = conversation;

            size_allocate.connect((allocation) => {
                if (allocation.height > parent.get_allocated_height()) {
                    Idle.add(() => { parent.queue_resize(); return false; });
                }
            });

            call.bind_property("state", this, "call-state");
            this.notify["call-state"].connect(update_widget);

            accept_call_button.clicked.connect(() => {
                stream_interactor.get_module(Calls.IDENTITY).accept_call(call);

                var call_window = new CallWindow();
                call_window.controller = new CallWindowController(call_window, call, stream_interactor);
                call_window.present();
            });

            reject_call_button.clicked.connect(() => {
                stream_interactor.get_module(Calls.IDENTITY).reject_call(call);
            });

            update_widget();
        }

        private void update_widget() {
            incoming_call_revealer.reveal_child = false;
            incoming_call_revealer.get_style_context().remove_class("incoming");

            switch (call.state) {
                case Call.State.RINGING:
                    image.set_from_icon_name("dino-phone-ring-symbolic", IconSize.LARGE_TOOLBAR);
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        bool video = stream_interactor.get_module(Calls.IDENTITY).should_we_send_video(call);
                        title_label.label = video ? _("Video call incoming") : _("Call incoming");
                        subtitle_label.label = "Ring ring…!";
                        incoming_call_revealer.reveal_child = true;
                        incoming_call_revealer.get_style_context().add_class("incoming");
                    } else {
                        title_label.label = _("Establishing call");
                        subtitle_label.label = "Ring ring…?";
                    }
                    break;
                case Call.State.ESTABLISHING:
                    image.set_from_icon_name("dino-phone-ring-symbolic", IconSize.LARGE_TOOLBAR);
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        bool video = stream_interactor.get_module(Calls.IDENTITY).should_we_send_video(call);
                        title_label.label = video ? _("Video call establishing") : _("Call establishing");
                        subtitle_label.label = "Connecting…";
                    }
                    break;
                case Call.State.IN_PROGRESS:
                    image.set_from_icon_name("dino-phone-in-talk-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = _("Call in progress…");
                    string duration = get_duration_string((new DateTime.now_utc()).difference(call.local_time));
                    subtitle_label.label = _("Started %s ago").printf(duration);

                    time_update_handler_id = Timeout.add_seconds(get_next_time_change() + 1, () => {
                        Source.remove(time_update_handler_id);
                        time_update_handler_id = 0;
                        update_widget();
                        return true;
                    });

                    break;
                case Call.State.OTHER_DEVICE_ACCEPTED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = call.direction == Call.DIRECTION_INCOMING ? _("Incoming call") : _("Outgoing call");
                    subtitle_label.label = _("You handled this call on another device");

                    break;
                case Call.State.ENDED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = _("Call ended");
                    string formated_end = Util.format_time(call.end_time, _("%H∶%M"), _("%l∶%M %p"));
                    string duration = get_duration_string(call.end_time.difference(call.local_time));
                    subtitle_label.label = _("Ended at %s").printf(formated_end) +
                            " · " +
                            _("Lasted for %s").printf(duration);
                    break;
                case Call.State.MISSED:
                    image.set_from_icon_name("dino-phone-missed-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = _("Call missed");
                    string who = null;
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        who = "You";
                    } else {
                        who = Util.get_participant_display_name(stream_interactor, conversation, call.to);
                    }
                    subtitle_label.label = "%s missed this call".printf(who);
                    break;
                case Call.State.DECLINED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = _("Call declined");
                    string who = null;
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        who = "You";
                    } else {
                        who = Util.get_participant_display_name(stream_interactor, conversation, call.to);
                    }
                    subtitle_label.label = "%s declined this call".printf(who);
                    break;
                case Call.State.FAILED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic", IconSize.LARGE_TOOLBAR);
                    title_label.label = _("Call failed");
                    subtitle_label.label = "This call failed to establish";
                    break;
            }
        }

        private string get_duration_string(TimeSpan duration) {
            DateTime a = new DateTime.now_utc();
            DateTime b = new DateTime.now_utc();
            a.difference(b);

            TimeSpan remainder_duration = duration;

            int hours = (int) Math.floor(remainder_duration / TimeSpan.HOUR);
            remainder_duration -= hours * TimeSpan.HOUR;

            int minutes = (int) Math.floor(remainder_duration / TimeSpan.MINUTE);
            remainder_duration -= minutes * TimeSpan.MINUTE;

            string ret = "";

            if (hours > 0) {
                ret += n("%i hour", "%i hours", hours).printf(hours);
            }

            if (minutes > 0) {
                if (ret.length > 0) {
                    ret += " ";
                }
                ret += n("%i minute", "%i minutes", minutes).printf(minutes);
            }

            if (ret.length > 0) {
                return ret;
            }

            return _("seconds");
        }

        private int get_next_time_change() {
            DateTime now = new DateTime.now_local();
            DateTime item_time = call.local_time;

            if (now.get_second() < item_time.get_second()) {
                return item_time.get_second() - now.get_second();
            } else {
                return 60 - (now.get_second() - item_time.get_second());
            }
        }

        public override void dispose() {
            base.dispose();

            if (time_update_handler_id != 0) {
                Source.remove(time_update_handler_id);
                time_update_handler_id = 0;
            }
        }
    }
}
