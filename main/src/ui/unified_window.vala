using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class UnifiedWindow : Gtk.Window {

    public signal void conversation_selected(Conversation conversation);

    public new string? title { get; set; }
    public string? subtitle { get; set; }

    public WelcomePlceholder welcome_placeholder = new WelcomePlceholder() { visible=true };
    public NoAccountsPlaceholder accounts_placeholder = new NoAccountsPlaceholder() { visible=true };
    public NoConversationsPlaceholder conversations_placeholder = new NoConversationsPlaceholder() { visible=true };
    public ChatInput.View chat_input;
    public ConversationSelector conversation_selector;
    public ConversationSummary.ConversationView conversation_frame;
    public ConversationTitlebar conversation_titlebar;
    public ConversationTitlebarCsd conversation_titlebar_csd;
    public ConversationListTitlebarCsd conversation_list_titlebar_csd;
    public HeaderBar placeholder_headerbar = new HeaderBar() { title="Dino", show_close_button=true, visible=true };
    public Box box = new Box(Orientation.VERTICAL, 0) { orientation=Orientation.VERTICAL, visible=true };
    public Paned headerbar_paned = new Paned(Orientation.HORIZONTAL) { visible=true };
    public Paned paned;
    public Revealer goto_end_revealer;
    public Button goto_end_button;
    public Revealer search_revealer;
    public SearchEntry search_entry;
    public GlobalSearch search_box;
    private Stack stack = new Stack() { visible=true };
    private Stack left_stack;
    private Stack right_stack;

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private Application app;
    private Database db;

    public UnifiedWindow(Application application, StreamInteractor stream_interactor, Database db) {
        Object(application : application);
        this.app = application;
        this.stream_interactor = stream_interactor;
        this.db = db;

        this.get_style_context().add_class("dino-main");
        setup_headerbar();
        Gtk.Settings.get_default().notify["gtk-decoration-layout"].connect(set_window_buttons);
        this.realize.connect(set_window_buttons);
        setup_unified();
        setup_stack();

        this.bind_property("title", conversation_titlebar, "title");
        this.bind_property("subtitle", conversation_titlebar, "subtitle");
        paned.bind_property("position", headerbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        stream_interactor.account_added.connect((account) => { check_stack(true); });
        stream_interactor.account_removed.connect((account) => { check_stack(); });
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(() => check_stack());
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(() => check_stack());

        check_stack();
    }

    public void on_conversation_selected(Conversation conversation, bool do_reset_search = true, bool default_initialize_conversation = true) {
        if (this.conversation == null || !this.conversation.equals(conversation)) {
            this.conversation = conversation;
            conversation_selected(conversation);
        }
    }

    private void setup_unified() {
        Builder builder = new Builder.from_resource("/im/dino/Dino/unified_main_content.ui");
        paned = (Paned) builder.get_object("paned");
        box.add(paned);
        left_stack = (Stack) builder.get_object("left_stack");
        right_stack = (Stack) builder.get_object("right_stack");
        chat_input = ((ChatInput.View) builder.get_object("chat_input")).init(stream_interactor);
        chat_input.key_press_event.connect(forward_key_press_to_chat_input);
        conversation_frame = ((ConversationSummary.ConversationView) builder.get_object("conversation_frame")).init(stream_interactor);
        conversation_frame.key_press_event.connect(forward_key_press_to_chat_input);
        conversation_selector = ((ConversationSelector) builder.get_object("conversation_list")).init(stream_interactor);
        goto_end_revealer = (Revealer) builder.get_object("goto_end_revealer");
        goto_end_button = (Button) builder.get_object("goto_end_button");
        search_box = ((GlobalSearch) builder.get_object("search_box")).init(stream_interactor);
        search_revealer = (Revealer) builder.get_object("search_revealer");
        search_entry = (SearchEntry) builder.get_object("search_entry");
        Image conversation_list_placeholder_image = (Image) builder.get_object("conversation_list_placeholder_image");
        conversation_list_placeholder_image.set_from_pixbuf(new Pixbuf.from_resource("/im/dino/Dino/icons/dino-conversation-list-placeholder-arrow.svg"));
    }

    private void setup_headerbar() {
        if (Util.use_csd()) {
            conversation_list_titlebar_csd = new ConversationListTitlebarCsd(stream_interactor, this) { visible=true };
            headerbar_paned.pack1(conversation_list_titlebar_csd, false, false);

            conversation_titlebar_csd = new ConversationTitlebarCsd() { visible=true };
            conversation_titlebar = conversation_titlebar_csd;
            headerbar_paned.pack2(conversation_titlebar_csd, true, false);
        } else {
            ConversationListTitlebar conversation_list_titlebar = new ConversationListTitlebar(stream_interactor, this) { visible=true };
            headerbar_paned.pack1(conversation_list_titlebar, false, false);

            conversation_titlebar = new ConversationTitlebarNoCsd() { visible=true };
            headerbar_paned.pack2(conversation_titlebar, true, false);

            box.add(headerbar_paned);
        }
        headerbar_paned.key_press_event.connect(forward_key_press_to_chat_input);
    }

    private void set_window_buttons() {
        if (!Util.use_csd()) return;
        Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
        if (gtk_settings == null) return;

        string[] buttons = gtk_settings.gtk_decoration_layout.split(":");
        this.conversation_list_titlebar_csd.decoration_layout = buttons[0] + ":";
        this.conversation_titlebar_csd.decoration_layout = ((buttons.length == 2) ? ":" + buttons[1] : "");
    }

    private void setup_stack() {
        stack.add_named(box, "main");
        stack.add_named(welcome_placeholder, "welcome_placeholder");
        stack.add_named(accounts_placeholder, "accounts_placeholder");
        stack.add_named(conversations_placeholder, "conversations_placeholder");
        add(stack);
    }

    private void check_stack(bool know_exists = false) {
        ArrayList<Account> accounts = stream_interactor.get_accounts();
        if (!know_exists && accounts.size == 0) {
            if (db.get_accounts().size == 0) {
                stack.set_visible_child_name("welcome_placeholder");
            } else {
                stack.set_visible_child_name("accounts_placeholder");
            }
            if (Util.use_csd()) {
                set_titlebar(placeholder_headerbar);
            }
        } else if (stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations().size == 0) {
            stack.set_visible_child_name("main");
            left_stack.set_visible_child_name("placeholder");
            right_stack.set_visible_child_name("placeholder");
            if (Util.use_csd()) {
                set_titlebar(headerbar_paned);
            }
        } else {
            left_stack.set_visible_child_name("content");
            right_stack.set_visible_child_name("content");

            stack.set_visible_child_name("main");
            if (Util.use_csd()) {
                set_titlebar(headerbar_paned);
            }
        }
    }

    private bool forward_key_press_to_chat_input(EventKey event) {
        // Don't forward / change focus on Control / Alt
        if (event.keyval == Gdk.Key.Control_L || event.keyval == Gdk.Key.Control_R ||
                event.keyval == Gdk.Key.Alt_L || event.keyval == Gdk.Key.Alt_R) {
            return false;
        }
        // Don't forward / change focus on Control + ...
        if ((event.state & ModifierType.CONTROL_MASK) > 0) {
            return false;
        }
        chat_input.text_input.key_press_event(event);
        chat_input.text_input.grab_focus();
        return true;
    }

    public void loop_conversations(bool backwards) {
        conversation_selector.loop_conversations(backwards);
    }
}

public class WelcomePlceholder : UnifiedWindowPlaceholder {
    public WelcomePlceholder() {
        title_label.label = _("Welcome to Dino!");
        label.label = _("Sign in or create an account to get started.");
        primary_button.label = _("Set up account");
        title_label.visible = true;
        secondary_button.visible = false;
    }
}

public class NoAccountsPlaceholder : UnifiedWindowPlaceholder {
    public NoAccountsPlaceholder() {
        title_label.label = _("No active accounts");
        primary_button.label = _("Manage accounts");
        title_label.visible = true;
        label.visible = false;
        secondary_button.visible = false;
    }
}

public class NoConversationsPlaceholder : UnifiedWindowPlaceholder {
    public NoConversationsPlaceholder() {
        title_label.label = _("No active conversations");
        primary_button.label = _("Start Conversation");
        secondary_button.label = _("Join Channel");
        title_label.visible = true;
        label.visible = false;
        secondary_button.visible = true;
    }
}

[GtkTemplate (ui = "/im/dino/Dino/unified_window_placeholder.ui")]
public class UnifiedWindowPlaceholder : Box {
    [GtkChild] public Label title_label;
    [GtkChild] public Label label;
    [GtkChild] public Button primary_button;
    [GtkChild] public Button secondary_button;
}

}
