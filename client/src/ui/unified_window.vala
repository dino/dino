using Gtk;

using Dino.Entities;

public class Dino.Ui.UnifiedWindow : ApplicationWindow {
    public ChatInput chat_input;
    public ConversationListTitlebar conversation_list_titlebar;
    public ConversationSelector.View filterable_conversation_list;
    public ConversationSummary.View conversation_frame;
    public ConversationTitlebar conversation_titlebar;
    public Paned paned;

    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public UnifiedWindow(Application application, StreamInteractor stream_interactor) {
        Object(application : application);
        this.stream_interactor = stream_interactor;
        focus_in_event.connect(on_focus_in_event);
        focus_out_event.connect(on_focus_out_event);

        default_width = 1200;
        default_height = 700;

        chat_input = new ChatInput(stream_interactor);
        conversation_frame = new ConversationSummary.View(stream_interactor);
        conversation_titlebar = new ConversationTitlebar(stream_interactor);
        paned = new Paned(Orientation.HORIZONTAL);
        paned.set_position(300);
        filterable_conversation_list = new ConversationSelector.View(stream_interactor);
        conversation_list_titlebar = new ConversationListTitlebar(this, stream_interactor);
        conversation_list_titlebar.search_button.bind_property("active", filterable_conversation_list.search_bar, "search-mode-enabled",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        Grid grid = new Grid();
        grid.orientation = Orientation.VERTICAL;
        Paned toolbar_paned = new Paned(Orientation.HORIZONTAL);

        add(paned);
        paned.add1(filterable_conversation_list);
        paned.add2(grid);

        grid.add(conversation_frame);
        grid.add(new Separator(Orientation.HORIZONTAL));
        grid.add(chat_input);

        conversation_frame.show_all();

        toolbar_paned.add1(conversation_list_titlebar);
        toolbar_paned.add2(conversation_titlebar);
        paned.bind_property("position", toolbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        set_titlebar(toolbar_paned);

        filterable_conversation_list.conversation_list.conversation_selected.connect(on_conversation_selected);
        conversation_list_titlebar.conversation_opened.connect(on_conversation_selected);
    }

    private void on_conversation_selected(Conversation conversation) {
        this.conversation = conversation;
        ChatInteraction.get_instance(stream_interactor).on_conversation_selected(conversation);
        conversation.active = true; // only for conversation_selected
        filterable_conversation_list.conversation_list.on_conversation_selected(conversation); // only for conversation_opened

        chat_input.initialize_for_conversation(conversation);
        conversation_frame.initialize_for_conversation(conversation);
        conversation_titlebar.initialize_for_conversation(conversation);
    }

    private bool on_focus_in_event() {
        ChatInteraction.get_instance(stream_interactor).window_focus_in(conversation);
        return false;
    }

    private bool on_focus_out_event() {
        ChatInteraction.get_instance(stream_interactor).window_focus_out(conversation);
        return false;
    }
}

