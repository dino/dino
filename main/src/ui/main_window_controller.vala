using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class MainWindowController : Object {

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private Application app;
    private Database db;
    private MainWindow window;

    private ConversationViewController conversation_view_controller;

    public MainWindowController(Application application, StreamInteractor stream_interactor, Database db) {
        this.app = application;
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(check_unset_conversation);
        stream_interactor.account_removed.connect(check_unset_conversation);
    }

    public void set_window(MainWindow window) {
        this.window = window;

        this.conversation_view_controller = new ConversationViewController(window.conversation_view, window.conversation_titlebar, stream_interactor);

        conversation_view_controller.search_menu_entry.search_button.bind_property("active", window.search_revealer, "reveal_child");

        window.search_revealer.notify["child-revealed"].connect(() => {
            if (window.search_revealer.child_revealed) {
                if (window.conversation_view.conversation_frame.conversation != null && window.search_box.search_entry.text == "") {
                    reset_search_entry();
                }
                window.search_box.search_entry.grab_focus_without_selecting();
                window.search_box.search_entry.set_position((int)window.search_box.search_entry.text_length);
            }
        });
        window.search_box.selected_item.connect((item) => {
            select_conversation(item.conversation, false, false);
            window.conversation_view.conversation_frame.initialize_around_message(item.conversation, item);
            close_search();
        });

        window.welcome_placeholder.primary_button.clicked.connect(() => {
            ManageAccounts.AddAccountDialog dialog = new ManageAccounts.AddAccountDialog(stream_interactor, db);
            dialog.set_transient_for(app.get_active_window());
            dialog.present();
        });
        window.accounts_placeholder.primary_button.clicked.connect(() => { app.activate_action("accounts", null); });
        window.conversation_selector.conversation_selected.connect((conversation) => select_conversation(conversation));

        window.event.connect((event) => {
            if (event.type == EventType.BUTTON_PRESS) {
                int dest_x, dest_y;
                bool ret = window.search_box.translate_coordinates(window, 0, 0, out dest_x, out dest_y);
                int geometry_x, geometry_y, geometry_width, geometry_height;
                window.get_window().get_geometry(out geometry_x, out geometry_y, out geometry_width, out geometry_height);
                if (ret && event.button.x_root - geometry_x < dest_x || event.button.y_root - geometry_y < dest_y) {
                    close_search();
                }
            } else if (event.type == EventType.KEY_RELEASE) {
                if (event.key.keyval == Gdk.Key.Escape) {
                    close_search();
                }
            }
            return false;
        });
        window.focus_in_event.connect(() => {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_in(conversation);
            window.urgency_hint = false;
            return false;
        });
        window.focus_out_event.connect(() => {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_out(conversation);
            return false;
        });

        window.conversation_selected.connect(conversation => select_conversation(conversation));

        stream_interactor.account_added.connect((account) => { update_stack_state(true); });
        stream_interactor.account_removed.connect((account) => { update_stack_state(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(() => update_stack_state());
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(() => update_stack_state());
        update_stack_state();

        AccelGroup accel_group = new AccelGroup();
        accel_group.connect(Gdk.Key.F, ModifierType.CONTROL_MASK, AccelFlags.VISIBLE, () => {
            window.search_revealer.reveal_child = true;
            return false;
        });
        window.add_accel_group(accel_group);
    }

    public void select_conversation(Conversation? conversation, bool do_reset_search = true, bool default_initialize_conversation = true) {
        this.conversation = conversation;

        conversation_view_controller.select_conversation(conversation, default_initialize_conversation);

        stream_interactor.get_module(ChatInteraction.IDENTITY).on_conversation_selected(conversation);
        conversation.active = true; // only for conversation_selected
        window.conversation_selector.on_conversation_selected(conversation); // In case selection was not via ConversationSelector

        if (do_reset_search) {
            reset_search_entry();
        }
    }

    private void check_unset_conversation() {
        if (stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations().size == 0) {
            unset_conversation();
        }
    }

    private void unset_conversation() {
        this.conversation = null;

        conversation_view_controller.unset_conversation();

        foreach(var e in this.app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                widget.unset_conversation();
            }
        }
    }

    private void update_stack_state(bool know_exists = false) {
        ArrayList<Account> accounts = stream_interactor.get_accounts();
        if (!know_exists && accounts.size == 0) {
            if (db.get_accounts().size == 0) {
                window.set_stack_state(MainWindow.StackState.CLEAN_START);
            } else {
                window.set_stack_state(MainWindow.StackState.NO_ACTIVE_ACCOUNTS);
            }
        } else if (stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations().size == 0) {
            window.set_stack_state(MainWindow.StackState.NO_ACTIVE_CONVERSATIONS);
        } else {
            window.set_stack_state(MainWindow.StackState.CONVERSATION);
        }
    }

    private void reset_search_entry() {
        if (window.conversation_view.conversation_frame.conversation != null) {
            switch (conversation.type_) {
                case Conversation.Type.CHAT:
                case Conversation.Type.GROUPCHAT_PM:
                    window.search_box.search_entry.text = @"with:$(conversation.counterpart) ";
                    break;
                case Conversation.Type.GROUPCHAT:
                    window.search_box.search_entry.text = @"in:$(conversation.counterpart) ";
                    break;
            }
        }
    }

    private void close_search() {
        conversation_view_controller.search_menu_entry.search_button.active = false;
        window.search_revealer.reveal_child = false;
    }
}

}
