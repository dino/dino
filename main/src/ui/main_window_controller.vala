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

        SimpleAction jump_to_conversatio_message_action = new SimpleAction("jump-to-conversation-message", new VariantType.tuple(new VariantType[]{VariantType.INT32, VariantType.INT32}));
        jump_to_conversatio_message_action.activate.connect((variant) => {
            int conversation_id = variant.get_child_value(0).get_int32();
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(conversation_id);
            if (conversation == null || !this.conversation.equals(conversation)) return;

            int item_id = variant.get_child_value(1).get_int32();
            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, item_id);

            select_conversation(conversation, false, false);
            window.conversation_view.conversation_frame.initialize_around_message(conversation, content_item);
        });
        app.add_action(jump_to_conversatio_message_action);

        SimpleAction select_messages_action = new SimpleAction("select-messages", VariantType.INT32);
        select_messages_action.activate.connect((variant) => {
            if (window.conversation_view == null || this.conversation == null) return;

            int conversation_id = variant.get_int32();
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(conversation_id);
            if (conversation == null || !this.conversation.equals(conversation)) return;

            toggle_selection_mode(true);
        });
        app.add_action(select_messages_action);
    }

    public void set_window(MainWindow window) {
        this.window = window;

        this.conversation_view_controller = new ConversationViewController(window.conversation_view, window.conversation_titlebar, stream_interactor);

        conversation_view_controller.search_menu_entry.button.bind_property("active", window.search_flap, "reveal-flap", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        window.search_flap.notify["reveal-flap"].connect(() => {
            if (window.search_flap.reveal_flap) {
                if (window.conversation_view.conversation_frame.conversation != null && window.global_search.search_entry.text == "") {
                    reset_search_entry();
                }
                window.global_search.search_entry.grab_focus();
                window.global_search.search_entry.set_position((int)window.global_search.search_entry.text.length);
            }
        });
        window.global_search.selected_item.connect((item) => {
            select_conversation(item.conversation, false, false);
            window.conversation_view.conversation_frame.initialize_around_message(item.conversation, item);
            if (window.search_flap.folded) {
                close_search();
            }
        });

        window.welcome_placeholder.primary_button.clicked.connect(() => {
            ManageAccounts.AddAccountDialog dialog = new ManageAccounts.AddAccountDialog(stream_interactor, db);
            dialog.set_transient_for(app.get_active_window());
            dialog.present();
        });
        window.accounts_placeholder.primary_button.clicked.connect(() => { app.activate_action("preferences", null); });
        window.conversation_selector.conversation_selected.connect((conversation) => select_conversation(conversation));

        window.selection_cancel.clicked.connect(() => { toggle_selection_mode(false); });
        window.selection_copy.clicked.connect(() => {
            toggle_selection_mode(false);
        });

//        ConversationListModel list_model = new ConversationListModel(stream_interactor);
//        list_model.closed_conversation.connect((conversation) => {
//            print(@"closed $(conversation.counterpart.bare_jid)\n");
//            stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
//        });
//        SingleSelection selection_model = new SingleSelection(list_model) { autoselect=false };
//        selection_model.notify["selected-item"].connect(() => {
//            ConversationViewModel view_model = (ConversationViewModel) selection_model.selected_item;
//            if (view_model.conversation.equals(conversation)) return;
//            print(@"selected conversation $(view_model.conversation.counterpart)\n");
//            select_conversation(view_model.conversation);
//        });
//        window.conversation_list_view.set_model(selection_model);
//        print(list_model.get_n_items().to_string() + " " + selection_model.get_n_items().to_string() + "<<");
//        print(selection_model.get_selected().to_string() + "<<");
//        window.conversation_list_view.realize.connect(() => {
//            selection_model.set_selected(0);
//        });

        Widget window_widget = ((Widget) window);

        EventControllerKey key_event_controller = new EventControllerKey();
        window_widget.add_controller(key_event_controller);
        // TODO GTK4: Why doesn't this work with key_pressed signal
        key_event_controller.key_released.connect((keyval) => {
            if (keyval == Gdk.Key.Escape) {
                close_search();
            }
        });

        EventControllerFocus focus_event_controller = new EventControllerFocus();
        window_widget.add_controller(focus_event_controller);
        focus_event_controller.enter.connect(() => {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_in(conversation);
        });
        focus_event_controller.leave.connect(() => {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_out(conversation);
        });

        window.conversation_selected.connect(conversation => select_conversation(conversation));

        stream_interactor.account_added.connect((account) => { update_stack_state(true); });
        stream_interactor.account_removed.connect((account) => { update_stack_state(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(() => update_stack_state());
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(() => update_stack_state());
        update_stack_state();
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

        foreach(Plugins.ConversationTitlebarEntry e in this.app.plugin_registry.conversation_titlebar_entries) {
            e.unset_conversation();
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
                    window.global_search.search_entry.text = @"with:$(conversation.counterpart) ";
                    break;
                case Conversation.Type.GROUPCHAT:
                    window.global_search.search_entry.text = @"in:$(conversation.counterpart) ";
                    break;
            }
        }
    }

    private void close_search() {
        conversation_view_controller.search_menu_entry.button.active = false;
    }

    private void toggle_selection_mode(bool enable) {
        window.conversation_view.conversation_frame.show_selection_checkboxes(enable);
        window.show_selection_toolbar(enable);
    }
}

}
