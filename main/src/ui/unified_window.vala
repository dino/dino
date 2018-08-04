using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class UnifiedWindow : Gtk.Window {

    private NoAccountsPlaceholder accounts_placeholder = new NoAccountsPlaceholder() { visible=true };
    private NoConversationsPlaceholder conversations_placeholder = new NoConversationsPlaceholder() { visible=true };
    private ChatInput.View chat_input;
    private ConversationListTitlebar conversation_list_titlebar;
    private ConversationSelector.View filterable_conversation_list;
    private ConversationSummary.ConversationView conversation_frame;
    private ConversationTitlebar conversation_titlebar;
    private HeaderBar placeholder_headerbar = new HeaderBar() { title="Dino", show_close_button=true, visible=true };
    private Paned headerbar_paned = new Paned(Orientation.HORIZONTAL) { visible=true };
    private Paned paned;
    private Revealer search_revealer;
    private SearchEntry search_entry;
    private GlobalSearch search_box;
    private Stack stack = new Stack() { visible=true };

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private Application app;

    public UnifiedWindow(Application application, StreamInteractor stream_interactor) {
        Object(application : application);
        this.stream_interactor = stream_interactor;
        this.app = application;

        restore_window_size();


        this.get_style_context().add_class("dino-main");
        setup_headerbar();
        setup_unified();
        setup_stack();


        conversation_titlebar.search_button.clicked.connect(() => {
            search_revealer.reveal_child = conversation_titlebar.search_button.active;
        });
        search_revealer.notify["child-revealed"].connect(() => {
            if (search_revealer.child_revealed) {
                if (conversation_frame.conversation != null && search_box.search_entry.text == "") {
                    reset_search_entry();
                }
                search_box.search_entry.grab_focus();
            }
        });
        search_box.selected_item.connect((item) => {
            on_conversation_selected(item.conversation, false, false);
            conversation_frame.initialize_around_message(item.conversation, item);
        });
        event.connect((event) => {
            if (event.type == EventType.BUTTON_PRESS) {
                int dest_x, dest_y;
                bool ret = search_box.translate_coordinates(this, 0, 0, out dest_x, out dest_y);
                if (ret && event.button.x_root < dest_x) {
                    close_search();
                }
            } else if (event.type == EventType.KEY_RELEASE) {
                if (event.key.keyval == Gdk.Key.Escape) {
                    close_search();
                }
            }
            return false;
        });

        paned.bind_property("position", headerbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        focus_in_event.connect(on_focus_in_event);
        focus_out_event.connect(on_focus_out_event);

        stream_interactor.account_added.connect((account) => { check_stack(true); });
        stream_interactor.account_removed.connect((account) => { check_stack(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(() => check_stack());
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(() => check_stack());
        accounts_placeholder.primary_button.clicked.connect(() => { get_application().activate_action("accounts", null); });
        conversations_placeholder.primary_button.clicked.connect(() => { get_application().activate_action("add_chat", null); });
        conversations_placeholder.secondary_button.clicked.connect(() => { get_application().activate_action("add_conference", null); });
        filterable_conversation_list.conversation_list.conversation_selected.connect((conversation) => on_conversation_selected(conversation));
        conversation_list_titlebar.conversation_opened.connect((conversation) => on_conversation_selected(conversation));

        check_stack();
    }

    private void reset_search_entry() {
        if (conversation_frame.conversation != null) {
            switch (conversation.type_) {
                case Conversation.Type.CHAT:
                case Conversation.Type.GROUPCHAT_PM:
                    search_box.search_entry.text = @"with:$(conversation.counterpart) ";
                    break;
                case Conversation.Type.GROUPCHAT:
                    search_box.search_entry.text = @"in:$(conversation.counterpart) ";
                    break;
            }
        }
    }

    public void on_conversation_selected(Conversation conversation, bool do_reset_search = true, bool default_initialize_conversation = true) {
        if (this.conversation == null || !this.conversation.equals(conversation)) {
            this.conversation = conversation;
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_conversation_selected(conversation);
            conversation.active = true; // only for conversation_selected
            filterable_conversation_list.conversation_list.on_conversation_selected(conversation); // only for conversation_opened

            if (do_reset_search) {
                reset_search_entry();
            }
            chat_input.initialize_for_conversation(conversation);
            if (default_initialize_conversation) {
                conversation_frame.initialize_for_conversation(conversation);
            }
            conversation_titlebar.initialize_for_conversation(conversation);
        }
    }

    private void close_search() {
        conversation_titlebar.search_button.active = false;
        search_revealer.reveal_child = false;
    }

    private void setup_unified() {
        Builder builder = new Builder.from_resource("/im/dino/Dino/unified_main_content.ui");
        paned = (Paned) builder.get_object("paned");
        chat_input = ((ChatInput.View) builder.get_object("chat_input")).init(stream_interactor);
        conversation_frame = ((ConversationSummary.ConversationView) builder.get_object("conversation_frame")).init(stream_interactor);
        filterable_conversation_list = ((ConversationSelector.View) builder.get_object("conversation_list")).init(stream_interactor);
        search_box = ((GlobalSearch) builder.get_object("search_box")).init(stream_interactor);
        search_revealer = (Revealer) builder.get_object("search_revealer");
        search_entry = (SearchEntry) builder.get_object("search_entry");
    }

    private void setup_headerbar() {
        conversation_titlebar = new ConversationTitlebar(stream_interactor, this) { visible=true };
        conversation_list_titlebar = new ConversationListTitlebar(stream_interactor, this) { visible=true };
        headerbar_paned.pack1(conversation_list_titlebar, false, false);
        headerbar_paned.pack2(conversation_titlebar, true, false);

        // Distribute start/end decoration_layout buttons to left/right headerbar. Ensure app menu fallback.
        Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
        if (gtk_settings != null) {
            if (!gtk_settings.gtk_decoration_layout.contains("menu")) {
                gtk_settings.gtk_decoration_layout = "menu:" + gtk_settings.gtk_decoration_layout;
            }
            string[] decoration_layout = gtk_settings.gtk_decoration_layout.split(":");
            if (decoration_layout.length == 2) {
                conversation_list_titlebar.decoration_layout = decoration_layout[0] + ":";
                conversation_titlebar.decoration_layout = ":" + decoration_layout[1];
            }
        }
    }

    private void setup_stack() {
        stack.add_named(paned, "main");
        stack.add_named(accounts_placeholder, "accounts_placeholder");
        stack.add_named(conversations_placeholder, "conversations_placeholder");
        add(stack);
    }

    private void check_stack(bool know_exists = false) {
        ArrayList<Account> accounts = stream_interactor.get_accounts();
        if (!know_exists && accounts.size == 0) {
            stack.set_visible_child_name("accounts_placeholder");
            set_titlebar(placeholder_headerbar);
        } else if (stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations().size == 0) {
            stack.set_visible_child_name("conversations_placeholder");
            set_titlebar(placeholder_headerbar);
        } else {
            stack.set_visible_child_name("main");
            set_titlebar(headerbar_paned);
        }
    }

    private void restore_window_size() {
        default_width = app.settings.current_width;
        default_height = app.settings.current_height;
        if (app.settings.is_maximized) this.maximize();
        if (app.settings.position_x != -1 && app.settings.position_y != -1) {
            move(app.settings.position_x, app.settings.position_y);
        }

        delete_event.connect(() => {
            int x, y;
            get_position(out x, out y);
            app.settings.position_x = x;
            app.settings.position_y = y;

            int width, height;
            get_size(out width, out height);
            app.settings.current_width = width;
            app.settings.current_height = height;

            app.settings.is_maximized = is_maximized;
            return false;
        });
    }

    private bool on_focus_in_event() {
        stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_in(conversation);
        urgency_hint = false;
        return false;
    }

    private bool on_focus_out_event() {
        stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_out(conversation);
        return false;
    }
}

public class NoAccountsPlaceholder : UnifiedWindowPlaceholder {
    public NoAccountsPlaceholder() {
        label.label = _("No active accounts");
        primary_button.label = _("Manage accounts");
        secondary_button.visible = false;
    }
}

public class NoConversationsPlaceholder : UnifiedWindowPlaceholder {
    public NoConversationsPlaceholder() {
        label.label = _("No active conversations");
        primary_button.label = _("Start Conversation");
        secondary_button.label = _("Join Channel");
        secondary_button.visible = true;
    }
}

[GtkTemplate (ui = "/im/dino/Dino/unified_window_placeholder.ui")]
public class UnifiedWindowPlaceholder : Box {
    [GtkChild] public Label label;
    [GtkChild] public Button primary_button;
    [GtkChild] public Button secondary_button;
}

}
