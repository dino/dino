using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui {

    public class CallMetaItem : ConversationSummary.ContentMetaItem {

        private StreamInteractor stream_interactor;

        public CallMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
            base(content_item);
            this.stream_interactor = stream_interactor;
        }

        public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
            CallItem call_item = content_item as CallItem;
            CallState? call_state = stream_interactor.get_module(Calls.IDENTITY).call_states[call_item.call];
            return new CallWidget(stream_interactor, call_item.call, call_state, call_item.conversation);
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
    }

    [GtkTemplate (ui = "/im/dino/Dino/call_widget.ui")]
    public class CallWidget : SizeRequestBox {

        [GtkChild] public unowned Image image;
        [GtkChild] public unowned Label title_label;
        [GtkChild] public unowned Label subtitle_label;
        [GtkChild] public unowned Revealer incoming_call_revealer;
        [GtkChild] public unowned Box outer_additional_box;
        [GtkChild] public unowned Box incoming_call_box;
        [GtkChild] public unowned Box multiparty_peer_box;
        [GtkChild] public unowned Button accept_call_button;
        [GtkChild] public unowned Button reject_call_button;

        private StreamInteractor stream_interactor;
        private CallState call_manager;
        private Call call;
        private Conversation conversation;
        public Call.State call_state { get; set; } // needs to be public for binding
        private uint time_update_handler_id = 0;
        private ArrayList<Widget> multiparty_peer_widgets = new ArrayList<Widget>();

        construct {
            margin_top = 4;
            size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
        }

        /** @param call_state Null if it's an old call and we can't interact with it anymore */
        public CallWidget(StreamInteractor stream_interactor, Call call, CallState? call_state, Conversation conversation) {
            this.stream_interactor = stream_interactor;
            this.call_manager = call_state;
            this.call = call;
            this.conversation = conversation;

//            size_allocate.connect((allocation) => {
//                if (allocation.height > parent.get_allocated_height()) {
//                    Idle.add(() => { parent.queue_resize(); return false; });
//                }
//            });

            call.bind_property("state", this, "call-state");
            this.notify["call-state"].connect(update_call_state);

            if (call_manager != null && (call.state == Call.State.ESTABLISHING || call.state == Call.State.IN_PROGRESS)) {
                call_manager.peer_joined.connect(update_counterparts);
            }

            accept_call_button.clicked.connect(() => {
                call_manager.accept();

                var call_window = new CallWindow();
                call_window.controller = new CallWindowController(call_window, call_state, stream_interactor);
                call_window.present();
            });

            reject_call_button.clicked.connect(call_manager.reject);

            update_call_state();
        }

        private void update_counterparts() {
            if (call.state != Call.State.IN_PROGRESS && call.state != Call.State.ENDED) return;
            if (call.counterparts.size <= 1 && conversation.type_ == Conversation.Type.CHAT) return;

            foreach (Widget peer_widget in multiparty_peer_widgets) {
                multiparty_peer_box.remove(peer_widget);
            }

            foreach (Jid counterpart in call.counterparts) {
                AvatarImage image = new AvatarImage() { force_gray=true, margin_top=2 };
                image.set_conversation_participant(stream_interactor, conversation, counterpart.bare_jid);
                multiparty_peer_box.append(image);
                multiparty_peer_widgets.add(image);
            }
            AvatarImage image2 = new AvatarImage() { force_gray=true, margin_top=2 };
            image2.set_conversation_participant(stream_interactor, conversation, call.account.bare_jid);
            multiparty_peer_box.append(image2);
            multiparty_peer_widgets.add(image2);

            outer_additional_box.add_css_class("multiparty-participants");

            multiparty_peer_box.visible = true;
            incoming_call_box.visible = false;
            incoming_call_revealer.reveal_child = true;
        }

        private static void update_call_state_lambda(CallWidget self) {
            if (self.time_update_handler_id != 0) self.update_call_state();
        }

        private void update_call_state() {
            incoming_call_revealer.reveal_child = false;
            incoming_call_revealer.remove_css_class("incoming");
            outer_additional_box.remove_css_class("incoming-call-box");

            // It doesn't make sense to display MUC calls as missed or declined by the whole MUC. Just display as ended.
            // TODO: maybe not let them be missed/declined in first place.
            Call.State relevant_state = call.state;
            if (conversation.type_ == Conversation.Type.GROUPCHAT && call.direction == Call.DIRECTION_OUTGOING &&
                    (relevant_state == Call.State.MISSED || relevant_state == Call.State.DECLINED)) {
                relevant_state = Call.State.ENDED;
            }

            switch (relevant_state) {
                case Call.State.RINGING:
                    image.set_from_icon_name("dino-phone-ring-symbolic");
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        bool video = call_manager.should_we_send_video();

                        title_label.label = video ? _("Incoming video call") : _("Incoming call");
                        if (call_manager.invited_to_group_call != null) {
                            title_label.label = video ? _("Incoming video group call") : _("Incoming group call");
                        }

                        if (stream_interactor.get_module(Calls.IDENTITY).can_we_do_calls(call.account)) {
                            subtitle_label.label = "Ring ring…!";
                            incoming_call_box.visible = true;
                            incoming_call_revealer.reveal_child = true;
                            incoming_call_revealer.add_css_class("incoming");
                            outer_additional_box.add_css_class("incoming-call-box");
                        } else {
                            subtitle_label.label = "Dependencies for call support not met";
                        }
                    } else {
                        title_label.label = _("Calling…");
                        subtitle_label.label = "Ring ring…?";
                    }
                    break;
                case Call.State.ESTABLISHING:
                case Call.State.IN_PROGRESS:
                    image.set_from_icon_name("dino-phone-in-talk-symbolic");
                    title_label.label = _("Call started");
                    string duration = get_duration_string((new DateTime.now_utc()).difference(call.local_time));
                    subtitle_label.label = _("Started %s ago").printf(duration);

                    time_update_handler_id = Dino.WeakTimeout.add_seconds_once(get_next_time_change() + 1, this, update_call_state_lambda);

                    break;
                case Call.State.OTHER_DEVICE:
                    image.set_from_icon_name("dino-phone-hangup-symbolic");
                    title_label.label = call.direction == Call.DIRECTION_INCOMING ? _("Incoming call") : _("Outgoing call");
                    subtitle_label.label = _("You handled this call on another device");

                    break;
                case Call.State.ENDED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic");
                    title_label.label = _("Call ended");
                    string formated_end = Util.format_time(call.end_time.to_local(), _("%H∶%M"), _("%l∶%M %p"));
                    string duration = get_duration_string(call.end_time.difference(call.local_time));
                    subtitle_label.label = _("Ended at %s").printf(formated_end) +
                            " · " +
                            _("Lasted %s").printf(duration);
                    break;
                case Call.State.MISSED:
                    image.set_from_icon_name("dino-phone-missed-symbolic");
                    title_label.label = _("Call missed");
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        subtitle_label.label = _("You missed this call");
                    } else {
                        string who = Util.get_conversation_display_name(stream_interactor, conversation);
                        subtitle_label.label = _("%s missed this call").printf(who);
                    }
                    break;
                case Call.State.DECLINED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic");
                    title_label.label = _("Call declined");
                    if (call.direction == Call.DIRECTION_INCOMING) {
                        subtitle_label.label = _("You declined this call");
                    } else {
                        string who = Util.get_conversation_display_name(stream_interactor, conversation);
                        subtitle_label.label = _("%s declined this call").printf(who);
                    }
                    break;
                case Call.State.FAILED:
                    image.set_from_icon_name("dino-phone-hangup-symbolic");
                    title_label.label = _("Call failed");
                    subtitle_label.label = "Call failed to establish";
                    break;
            }

            update_counterparts();
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

            return _("a few seconds");
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
            if (call_manager != null) {
                call_manager.peer_joined.disconnect(update_counterparts);
            }
        }
    }
}
