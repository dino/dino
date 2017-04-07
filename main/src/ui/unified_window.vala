using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class UnifiedWindow : Window {

    private NoAccountsPlaceholder accounts_placeholder = new NoAccountsPlaceholder() { visible=true };
    private NoConversationsPlaceholder conversations_placeholder = new NoConversationsPlaceholder() { visible=true };
    private ChatInput.View chat_input;
    private ConversationListTitlebar conversation_list_titlebar;
    private ConversationSelector.View filterable_conversation_list;
    private ConversationSummary.View conversation_frame;
    private ConversationTitlebar conversation_titlebar;
    private HeaderBar placeholder_headerbar = new HeaderBar() { title="Dino", show_close_button=true, visible=true };
    private Paned headerbar_paned = new Paned(Orientation.HORIZONTAL) { visible=true };
    private Paned paned = new Paned(Orientation.HORIZONTAL) { visible=true };
    private Stack stack = new Stack() { visible=true };

    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public UnifiedWindow(Application application, StreamInteractor stream_interactor) {
        Object(application : application, default_width : 1200, default_height : 700);
        this.stream_interactor = stream_interactor;

        setup_headerbar();
        setup_unified();
        setup_stack();

        conversation_list_titlebar.search_button.bind_property("active", filterable_conversation_list.search_bar, "search-mode-enabled",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        paned.bind_property("position", headerbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        focus_in_event.connect(on_focus_in_event);
        focus_out_event.connect(on_focus_out_event);

        stream_interactor.account_added.connect((account) => { check_stack(true); });
        stream_interactor.account_removed.connect((account) => { check_stack(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect((conversation) => { check_stack(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect((conversation) => { check_stack(); });
        accounts_placeholder.primary_button.clicked.connect(() => { get_application().activate_action("accounts", null); });
        conversations_placeholder.primary_button.clicked.connect(() => { get_application().activate_action("add_chat", null); });
        conversations_placeholder.secondary_button.clicked.connect(() => { get_application().activate_action("add_conference", null); });
        filterable_conversation_list.conversation_list.conversation_selected.connect(on_conversation_selected);
        conversation_list_titlebar.conversation_opened.connect(on_conversation_selected);

        check_stack();
    }

    public void on_conversation_selected(Conversation conversation) {
        if (this.conversation == null || !this.conversation.equals(conversation)) {
            this.conversation = conversation;
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_conversation_selected(conversation);
            conversation.active = true; // only for conversation_selected
            filterable_conversation_list.conversation_list.on_conversation_selected(conversation); // only for conversation_opened

            chat_input.initialize_for_conversation(conversation);
            conversation_frame.initialize_for_conversation(conversation);
            conversation_titlebar.initialize_for_conversation(conversation);
        }
    }

    private void setup_unified() {
        chat_input = new ChatInput.View(stream_interactor) { visible=true };
        conversation_frame = new ConversationSummary.View(stream_interactor) { visible=true };
        filterable_conversation_list = new ConversationSelector.View(stream_interactor) { visible=true };

        Grid grid = new Grid() { orientation=Orientation.VERTICAL, visible=true };
        grid.add(conversation_frame);
        grid.add(new Separator(Orientation.HORIZONTAL) { visible=true });
        grid.add(chat_input);

        paned.set_position(300);
        paned.add1(filterable_conversation_list);
        paned.add2(grid);
    }

    private void setup_headerbar() {
        conversation_titlebar = new ConversationTitlebar(stream_interactor) { visible=true };
        conversation_list_titlebar = new ConversationListTitlebar(this, stream_interactor) { visible=true };
        headerbar_paned.add1(conversation_list_titlebar);
        headerbar_paned.add2(conversation_titlebar);

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

    private bool on_focus_in_event() {
        stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_in(conversation);
        return false;
    }

    private bool on_focus_out_event() {
        stream_interactor.get_module(ChatInteraction.IDENTITY).on_window_focus_out(conversation);
        return false;
    }
}

public class NoAccountsPlaceholder : UnifiedWindowPlaceholder {
    public NoAccountsPlaceholder() {
        label.label = _("No accounts active");
        primary_button.label = _("Manage accounts");
        secondary_button.visible = false;
    }
}

public class NoConversationsPlaceholder : UnifiedWindowPlaceholder {
    public NoConversationsPlaceholder() {
        label.label = _("No conversation active");
        primary_button.label = _("Add Chat");
        secondary_button.label = _("Join Conference");
        secondary_button.visible = true;
    }
}

[GtkTemplate (ui = "/org/dino-im/unified_window_placeholder.ui")]
public class UnifiedWindowPlaceholder : Box {
    [GtkChild] public Label label;
    [GtkChild] public Button primary_button;
    [GtkChild] public Button secondary_button;
}

}