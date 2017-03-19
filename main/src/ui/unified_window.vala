using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class UnifiedWindow : Window {

    private UnifiedWindowPlaceholder main_placeholder = new UnifiedWindowPlaceholder();
    private ChatInput chat_input;
    private ConversationListTitlebar conversation_list_titlebar;
    private ConversationSelector.View filterable_conversation_list;
    private ConversationSummary.View conversation_frame;
    private ConversationTitlebar conversation_titlebar;
    private Paned headerbar_paned = new Paned(Orientation.HORIZONTAL);
    private Paned paned = new Paned(Orientation.HORIZONTAL);
    private Stack headerbar_stack = new Stack();
    private Stack stack = new Stack();

    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public UnifiedWindow(Application application, StreamInteractor stream_interactor) {
        Object(application : application, default_width : 1200, default_height : 700);
        this.stream_interactor = stream_interactor;

        setup_headerbar();
        setup_unified();
        setup_stacks();

        conversation_list_titlebar.search_button.bind_property("active", filterable_conversation_list.search_bar, "search-mode-enabled",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        paned.bind_property("position", headerbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        focus_in_event.connect(on_focus_in_event);
        focus_out_event.connect(on_focus_out_event);

        stream_interactor.account_added.connect((account) => { check_stack(true); });
        stream_interactor.account_removed.connect((account) => { check_stack(); });
        main_placeholder.no_accounts_add.clicked.connect(() => { get_application().activate_action("accounts", null); });
        filterable_conversation_list.conversation_list.conversation_selected.connect(on_conversation_selected);
        conversation_list_titlebar.conversation_opened.connect(on_conversation_selected);

        check_stack();
    }

    private void setup_unified() {
        chat_input = new ChatInput(stream_interactor);
        conversation_frame = new ConversationSummary.View(stream_interactor);
        filterable_conversation_list = new ConversationSelector.View(stream_interactor);

        Grid grid = new Grid() { orientation=Orientation.VERTICAL };
        grid.add(conversation_frame);
        grid.add(new Separator(Orientation.HORIZONTAL));
        grid.add(chat_input);

        paned.set_position(300);
        paned.add1(filterable_conversation_list);
        paned.add2(grid);

        conversation_frame.show_all();
    }

    private void setup_headerbar() {
        conversation_titlebar = new ConversationTitlebar(stream_interactor);
        conversation_list_titlebar = new ConversationListTitlebar(this, stream_interactor);
        headerbar_paned.add1(conversation_list_titlebar);
        headerbar_paned.add2(conversation_titlebar);
    }

    private void setup_stacks() {
        stack.add_named(paned, "main");
        stack.add_named(main_placeholder, "placeholder");
        add(stack);

        headerbar_stack.add_named(headerbar_paned, "main");
        headerbar_stack.add_named(new HeaderBar() { title="Dino", show_close_button=true, visible=true}, "placeholder");
        set_titlebar(headerbar_stack);
    }

    private void check_stack(bool know_exists = false) {
        ArrayList<Account> accounts = stream_interactor.get_accounts();
        bool exists_active = know_exists;
        foreach (Account account in accounts) {
            if (account.enabled) {
                exists_active = true;
                break;
            }
        }
        if (exists_active) {
            stack.set_visible_child_name("main");
            headerbar_stack.set_visible_child_name("main");
        } else {
            stack.set_visible_child_name("placeholder");
            headerbar_stack.set_visible_child_name("placeholder");
        }
    }

    private void on_conversation_selected(Conversation conversation) {
        this.conversation = conversation;
        stream_interactor.get_module(ChatInteraction.IDENTITY).on_conversation_selected(conversation);
        conversation.active = true; // only for conversation_selected
        filterable_conversation_list.conversation_list.on_conversation_selected(conversation); // only for conversation_opened

        chat_input.initialize_for_conversation(conversation);
        conversation_frame.initialize_for_conversation(conversation);
        conversation_titlebar.initialize_for_conversation(conversation);
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

[GtkTemplate (ui = "/org/dino-im/unified_window_placeholder.ui")]
public class UnifiedWindowPlaceholder : Box {
    [GtkChild] public Button no_accounts_add;
}

}