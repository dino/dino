using Xmpp;
using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

    public class CallTitlebarEntry : Plugins.ConversationTitlebarEntry, Object {
        public string id { get { return "call"; } }

        public CallButton call_button;

        private StreamInteractor stream_interactor;

        public CallTitlebarEntry(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            call_button = new CallButton(stream_interactor) { tooltip_text=_("Start call") };
            call_button.set_image(new Gtk.Image.from_icon_name("dino-phone-symbolic", Gtk.IconSize.MENU) { visible=true });
        }

        public double order { get { return 4; } }
        public Plugins.ConversationTitlebarWidget? get_widget(Plugins.WidgetType type) {
            if (type == Plugins.WidgetType.GTK) {
                return call_button;
            }
            return null;
        }
    }

    public class CallButton : Plugins.ConversationTitlebarWidget, Gtk.MenuButton {

        private StreamInteractor stream_interactor;
        private Conversation conversation;

        public CallButton(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            use_popover = true;
            image = new Gtk.Image.from_icon_name("dino-phone-symbolic", Gtk.IconSize.MENU) { visible=true };

            Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu();
            Box box = new Box(Orientation.VERTICAL, 0) { margin=10, visible=true };
            ModelButton audio_button = new ModelButton() { text="Audio call", visible=true };
            audio_button.clicked.connect(() => {
                stream_interactor.get_module(Calls.IDENTITY).initiate_call.begin(conversation, false, (_, res) => {
                    Call call = stream_interactor.get_module(Calls.IDENTITY).initiate_call.end(res);
                    open_call_window(call);
                });
            });
            box.add(audio_button);
            ModelButton video_button = new ModelButton() { text="Video call", visible=true };
            video_button.clicked.connect(() => {
                stream_interactor.get_module(Calls.IDENTITY).initiate_call.begin(conversation, true, (_, res) => {
                    Call call = stream_interactor.get_module(Calls.IDENTITY).initiate_call.end(res);
                    open_call_window(call);
                });
            });
            box.add(video_button);
            popover_menu.add(box);

            popover = popover_menu;

            clicked.connect(() => {
                popover_menu.visible = true;
            });

            stream_interactor.get_module(Calls.IDENTITY).call_incoming.connect((call, conversation) => {
                update_button_state();
            });

            stream_interactor.get_module(Calls.IDENTITY).call_terminated.connect((call) => {
                update_button_state();
            });
            stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect((jid, account) => {
                if (this.conversation.counterpart.equals_bare(jid) && this.conversation.account.equals(account)) {
                    update_visibility.begin();
                }
            });
            stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
                update_visibility.begin();
            });
        }

        private void open_call_window(Call call) {
            var call_window = new CallWindow();
            var call_controller = new CallWindowController(call_window, call, stream_interactor);
            call_window.controller = call_controller;
            call_window.present();

            update_button_state();
            call_controller.terminated.connect(() => {
                update_button_state();
            });
        }

        public new void set_conversation(Conversation conversation) {
            this.conversation = conversation;

            update_visibility.begin();
            update_button_state();
        }

        private void update_button_state() {
            Jid? call_counterpart = stream_interactor.get_module(Calls.IDENTITY).is_call_in_progress();
            this.sensitive = call_counterpart == null;

            if (call_counterpart != null && call_counterpart.equals_bare(conversation.counterpart)) {
                this.set_image(new Gtk.Image.from_icon_name("dino-phone-in-talk-symbolic", Gtk.IconSize.MENU) { visible=true });
            } else {
                this.set_image(new Gtk.Image.from_icon_name("dino-phone-symbolic", Gtk.IconSize.MENU) { visible=true });
            }
        }

        private async void update_visibility() {
            if (conversation.type_ == Conversation.Type.CHAT) {
                Conversation conv_bak = conversation;
                bool can_do_calls = yield stream_interactor.get_module(Calls.IDENTITY).can_do_calls(conversation);
                if (conv_bak != conversation) return;
                visible = can_do_calls;
            } else {
                visible = false;
            }
        }

        public new void unset_conversation() { }
    }

}
