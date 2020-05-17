using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class MainWindow : Gtk.Window {

    public signal void conversation_selected(Conversation conversation);

    public new string? title { get; set; }
    public string? subtitle { get; set; }

    public WelcomePlceholder welcome_placeholder = new WelcomePlceholder() { visible=true };
    public NoAccountsPlaceholder accounts_placeholder = new NoAccountsPlaceholder() { visible=true };
    public ConversationView conversation_view;
    public ConversationSelector conversation_selector;
    public ConversationTitlebar conversation_titlebar;
    public ConversationTitlebarCsd conversation_titlebar_csd;
    public ConversationListTitlebarCsd conversation_list_titlebar_csd;
    public HeaderBar placeholder_headerbar = new HeaderBar() { title="Dino", show_close_button=true, visible=true };
    public Box box = new Box(Orientation.VERTICAL, 0) { orientation=Orientation.VERTICAL, visible=true };
    public Paned headerbar_paned = new Paned(Orientation.HORIZONTAL) { visible=true };
    public Paned paned;
    public Revealer search_revealer;
    public SearchEntry search_entry;
    public GlobalSearch search_box;
    private Stack stack = new Stack() { visible=true };
    private Stack left_stack;
    private Stack right_stack;

    private StreamInteractor stream_interactor;
    private Database db;
    private Config config;

    public MainWindow(Application application, StreamInteractor stream_interactor, Database db, Config config) {
        Object(application : application);
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.config = config;

        restore_window_size();

        this.get_style_context().add_class("dino-main");
        setup_headerbar();
        Gtk.Settings.get_default().notify["gtk-decoration-layout"].connect(set_window_buttons);
        this.realize.connect(set_window_buttons);
        setup_unified();
        setup_stack();

        paned.bind_property("position", headerbar_paned, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
    }

    private void setup_unified() {
        Builder builder = new Builder.from_resource("/im/dino/Dino/unified_main_content.ui");
        paned = (Paned) builder.get_object("paned");
        box.add(paned);
        left_stack = (Stack) builder.get_object("left_stack");
        right_stack = (Stack) builder.get_object("right_stack");
        conversation_view = (ConversationView) builder.get_object("conversation_view");
        conversation_selector = ((ConversationSelector) builder.get_object("conversation_list")).init(stream_interactor);
        search_box = ((GlobalSearch) builder.get_object("search_box")).init(stream_interactor);
        search_revealer = (Revealer) builder.get_object("search_revealer");
        search_entry = (SearchEntry) builder.get_object("search_entry");
        Image conversation_list_placeholder_image = (Image) builder.get_object("conversation_list_placeholder_image");
        conversation_list_placeholder_image.set_from_pixbuf(new Pixbuf.from_resource("/im/dino/Dino/icons/dino-conversation-list-placeholder-arrow.svg"));
    }

    private void setup_headerbar() {
        if (Util.use_csd()) {
            conversation_list_titlebar_csd = new ConversationListTitlebarCsd() { visible=true };
            headerbar_paned.pack1(conversation_list_titlebar_csd, false, false);

            conversation_titlebar_csd = new ConversationTitlebarCsd() { visible=true };
            conversation_titlebar = conversation_titlebar_csd;
            headerbar_paned.pack2(conversation_titlebar_csd, true, false);
        } else {
            ConversationListTitlebar conversation_list_titlebar = new ConversationListTitlebar() { visible=true };
            headerbar_paned.pack1(conversation_list_titlebar, false, false);

            conversation_titlebar = new ConversationTitlebarNoCsd() { visible=true };
            headerbar_paned.pack2(conversation_titlebar, true, false);

            box.add(headerbar_paned);
        }
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
        add(stack);
    }

    public enum StackState {
        CLEAN_START,
        NO_ACTIVE_ACCOUNTS,
        NO_ACTIVE_CONVERSATIONS,
        CONVERSATION
    }

    public void set_stack_state(StackState stack_state) {
        if (stack_state == StackState.CONVERSATION) {
            left_stack.set_visible_child_name("content");
            right_stack.set_visible_child_name("content");

            stack.set_visible_child_name("main");
            if (Util.use_csd()) {
                set_titlebar(headerbar_paned);
            }
        } else if (stack_state == StackState.CLEAN_START || stack_state == StackState.NO_ACTIVE_ACCOUNTS) {
            if (stack_state == StackState.CLEAN_START) {
                stack.set_visible_child_name("welcome_placeholder");
            } else if (stack_state == StackState.NO_ACTIVE_ACCOUNTS) {
                stack.set_visible_child_name("accounts_placeholder");
            }
            if (Util.use_csd()) {
                set_titlebar(placeholder_headerbar);
            }
        } else if (stack_state == StackState.NO_ACTIVE_CONVERSATIONS) {
            stack.set_visible_child_name("main");
            left_stack.set_visible_child_name("placeholder");
            right_stack.set_visible_child_name("placeholder");
            if (Util.use_csd()) {
                set_titlebar(headerbar_paned);
            }
        }
    }

    public void loop_conversations(bool backwards) {
        conversation_selector.loop_conversations(backwards);
    }

    public void restore_window_size() {
        Gdk.Display? display = Gdk.Display.get_default();
        if (display != null) {
            Gdk.Monitor? monitor = display.get_primary_monitor();
            if (monitor == null) {
                monitor = display.get_monitor_at_point(1, 1);
            }

            if (monitor != null &&
                    config.window_width <= monitor.geometry.width &&
                    config.window_height <= monitor.geometry.height) {
                set_default_size(config.window_width, config.window_height);
            }
        }
        this.window_position = Gtk.WindowPosition.CENTER;
        if (config.window_maximize) {
            maximize();
        }

        this.delete_event.connect(() => {
            save_window_size();
            config.window_maximize = this.is_maximized;
            return false;
        });
    }

    public void save_window_size() {
        if (this.is_maximized) return;

        Gdk.Display? display = get_display();
        Gdk.Window? window = get_window();
        if (display != null && window != null) {
            Gdk.Monitor monitor = display.get_monitor_at_window(window);

            int width = 0;
            int height = 0;
            get_size(out width, out height);


            // Only store if the values have changed and are reasonable-looking.
            if (config.window_width != width && width > 0 && width <= monitor.geometry.width) {
                config.window_width = width;
            }
            if (config.window_height != height && height > 0 && height <= monitor.geometry.height) {
                config.window_height = height;
            }
        }
    }
}

public class WelcomePlceholder : MainWindowPlaceholder {
    public WelcomePlceholder() {
        title_label.label = _("Welcome to Dino!");
        label.label = _("Sign in or create an account to get started.");
        primary_button.label = _("Set up account");
        title_label.visible = true;
        secondary_button.visible = false;
    }
}

public class NoAccountsPlaceholder : MainWindowPlaceholder {
    public NoAccountsPlaceholder() {
        title_label.label = _("No active accounts");
        primary_button.label = _("Manage accounts");
        title_label.visible = true;
        label.visible = false;
        secondary_button.visible = false;
    }
}

[GtkTemplate (ui = "/im/dino/Dino/unified_window_placeholder.ui")]
public class MainWindowPlaceholder : Box {
    [GtkChild] public Label title_label;
    [GtkChild] public Label label;
    [GtkChild] public Button primary_button;
    [GtkChild] public Button secondary_button;
}

}
