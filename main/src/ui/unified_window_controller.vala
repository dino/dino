using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class UnifiedWindowController : Object {

    public new string? conversation_display_name { get; set; }
    public string? conversation_topic { get; set; }

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private Application app;
    private Database db;
    private UnifiedWindow window;

    private SearchMenuEntry search_menu_entry = new SearchMenuEntry();

    private ChatInputController chat_input_controller;

    public UnifiedWindowController(Application application, StreamInteractor stream_interactor, Database db) {
        this.app = application;
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(MucManager.IDENTITY).room_name_set.connect((account, jid, room_name) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_conversation_display_name();
            }
        });

        stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect((account, room, occupant) => {
            if (conversation != null && conversation.counterpart.equals_bare(room.bare_jid) && conversation.account.equals(account)) {
                update_conversation_display_name();
            }
        });

        stream_interactor.get_module(MucManager.IDENTITY).subject_set.connect((account, jid, subject) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_conversation_topic(subject);
            }
        });

        app.plugin_registry.register_contact_titlebar_entry(new MenuEntry(stream_interactor));
        app.plugin_registry.register_contact_titlebar_entry(search_menu_entry);
        app.plugin_registry.register_contact_titlebar_entry(new OccupantsEntry(stream_interactor));
    }

    public void set_window(UnifiedWindow window) {
        this.window = window;

        this.chat_input_controller = new ChatInputController(window.chat_input, stream_interactor);

        this.bind_property("conversation-display-name", window, "title");
        this.bind_property("conversation-topic", window, "subtitle");
        search_menu_entry.search_button.bind_property("active", window.search_revealer, "reveal_child");

        window.goto_end_button.clicked.connect(() => {
            window.conversation_frame.initialize_for_conversation(conversation);
        });
        window.search_revealer.notify["child-revealed"].connect(() => {
            if (window.search_revealer.child_revealed) {
                if (window.conversation_frame.conversation != null && window.search_box.search_entry.text == "") {
                    reset_search_entry();
                }
                window.search_box.search_entry.grab_focus();
            }
        });
        window.search_box.selected_item.connect((item) => {
            select_conversation(item.conversation, false, false);
            window.conversation_frame.initialize_around_message(item.conversation, item);
            close_search();
        });

        window.welcome_placeholder.primary_button.clicked.connect(() => {
            ManageAccounts.AddAccountDialog dialog = new ManageAccounts.AddAccountDialog(stream_interactor, db);
            dialog.set_transient_for(app.get_active_window());
            dialog.present();
        });
        window.accounts_placeholder.primary_button.clicked.connect(() => { app.activate_action("accounts", null); });
        window.conversations_placeholder.primary_button.clicked.connect(() => { app.activate_action("add_chat", null); });
        window.conversations_placeholder.secondary_button.clicked.connect(() => { app.activate_action("add_conference", null); });
        window.conversation_selector.conversation_selected.connect((conversation) => select_conversation(conversation));

        var vadjustment = window.conversation_frame.scrolled.vadjustment;
        vadjustment.notify["value"].connect(() => {
            window.goto_end_revealer.reveal_child = vadjustment.value <  vadjustment.upper - vadjustment.page_size;
        });
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

        restore_window_size();
    }

    public void select_conversation(Conversation conversation, bool do_reset_search = true, bool default_initialize_conversation = true) {
        this.conversation = conversation;

        update_conversation_display_name();
        update_conversation_topic();

        foreach(var e in this.app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                widget.set_conversation(conversation);
            }
        }

        stream_interactor.get_module(ChatInteraction.IDENTITY).on_conversation_selected(conversation);
        conversation.active = true; // only for conversation_selected
        window.conversation_selector.on_conversation_selected(conversation); // only for conversation_opened

        if (do_reset_search) {
            reset_search_entry();
        }
        chat_input_controller.set_conversation(conversation);
        window.chat_input.initialize_for_conversation(conversation);
        if (default_initialize_conversation) {
            window.conversation_frame.initialize_for_conversation(conversation);
        }
    }

    private void update_conversation_display_name() {
        conversation_display_name = Util.get_conversation_display_name(stream_interactor, conversation);
    }

    private void update_conversation_topic(string? subtitle = null) {
        if (subtitle != null) {
            try {
                conversation_topic = (/\s+/).replace_literal(subtitle, -1, 0, " ");
            } catch (RegexError e) {
                assert_not_reached();
            }
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            string? subject = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(conversation.counterpart, conversation.account);
            if (subject != null) {
                try {
                    conversation_topic =  (/\s+/).replace_literal(subject, -1, 0, " ");
                } catch (RegexError e) {
                    assert_not_reached();
                }
            } else {
                conversation_topic = null;
            }
        } else {
            conversation_topic = null;
        }
    }

    private void reset_search_entry() {
        if (window.conversation_frame.conversation != null) {
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
        search_menu_entry.search_button.active = false;
        window.search_revealer.reveal_child = false;
    }

    private void restore_window_size() {
        window.default_width = app.settings.current_width;
        window.default_height = app.settings.current_height;
        if (app.settings.is_maximized) window.maximize();
        if (app.settings.position_x != -1 && app.settings.position_y != -1) {
            window.move(app.settings.position_x, app.settings.position_y);
        }

        window.delete_event.connect(() => {
            int x, y;
            window.get_position(out x, out y);
            app.settings.position_x = x;
            app.settings.position_y = y;

            int width, height;
            window.get_size(out width, out height);
            app.settings.current_width = width;
            app.settings.current_height = height;

            app.settings.is_maximized = window.is_maximized;
            return false;
        });
    }
}

}
