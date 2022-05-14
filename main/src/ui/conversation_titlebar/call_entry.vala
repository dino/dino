using Xmpp;
using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

    public class CallTitlebarEntry : Plugins.ConversationTitlebarEntry, Object {
        public string id { get { return "call"; } }
        public double order { get { return 4; } }

        private MenuButton button = new MenuButton() { tooltip_text=_("Start call") };

        private StreamInteractor stream_interactor;
        private Conversation conversation;

        public CallTitlebarEntry(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            button.set_icon_name("dino-phone-symbolic");

            Menu menu_model = new Menu();
            menu_model.append(_("Audio call"), "call.audio");
            menu_model.append(_("Video call"), "call.video");
            Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
            button.popover = popover_menu;

            SimpleActionGroup action_group = new SimpleActionGroup();
            SimpleAction audio_call_action = new SimpleAction("audio", null);
            audio_call_action.activate.connect((parameter) => {
                stream_interactor.get_module(Calls.IDENTITY).initiate_call.begin(conversation, false, (_, res) => {
                    CallState call_state = stream_interactor.get_module(Calls.IDENTITY).initiate_call.end(res);
                    open_call_window(call_state);
                });
            });
            action_group.insert(audio_call_action);
            SimpleAction video_call_action = new SimpleAction("video", null);
            video_call_action.activate.connect((parameter) => {
                stream_interactor.get_module(Calls.IDENTITY).initiate_call.begin(conversation, true, (_, res) => {
                    CallState call_state = stream_interactor.get_module(Calls.IDENTITY).initiate_call.end(res);
                    open_call_window(call_state);
                });
            });
            action_group.insert(video_call_action);
            button.insert_action_group("call", action_group);

            stream_interactor.get_module(Calls.IDENTITY).call_incoming.connect((call, state,conversation) => {
                update_button_state();
            });

            stream_interactor.get_module(Calls.IDENTITY).call_terminated.connect((call) => {
                update_button_state();
            });
            stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect((jid, account) => {
                if (this.conversation == null) return;
                if (this.conversation.counterpart.equals_bare(jid) && this.conversation.account.equals(account)) {
                    update_visibility.begin();
                }
            });
            stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
                update_visibility.begin();
            });
        }

        private void open_call_window(CallState call_state) {
            var call_window = new CallWindow();
            var call_controller = new CallWindowController(call_window, call_state, stream_interactor);
            call_window.controller = call_controller;
            call_window.present();

            update_button_state();
        }

        public new void set_conversation(Conversation conversation) {
            this.conversation = conversation;

            update_visibility.begin();
            update_button_state();
        }

        private void update_button_state() {
            button.sensitive = !stream_interactor.get_module(Calls.IDENTITY).is_call_in_progress();
        }

        private async void update_visibility() {
            if (conversation == null) {
                button.visible = false;
                return;
            }

            Conversation conv_bak = conversation;
            bool can_do_calls = yield stream_interactor.get_module(Calls.IDENTITY).can_conversation_do_calls(conversation);
            if (conv_bak != conversation) return;

            button.visible = can_do_calls;
        }

        public new void unset_conversation() { }

        public Object? get_widget(Plugins.WidgetType type) {
            if (type != Plugins.WidgetType.GTK4) return null;
            return button;
        }
    }

}
