using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class MainWindow : Adw.ApplicationWindow {

    public signal void conversation_selected(Conversation conversation);

    public new string? title { get; set; }
    public string? subtitle { get; set; }

    public WelcomePlaceholder welcome_placeholder = new WelcomePlaceholder();
    public NoAccountsPlaceholder accounts_placeholder = new NoAccountsPlaceholder();
    public ConversationView conversation_view;
    public ConversationSelector conversation_selector;
    public ConversationTitlebar conversation_titlebar;
    public Widget conversation_list_titlebar;
    public Box box = new Box(Orientation.VERTICAL, 0) { orientation=Orientation.VERTICAL };
    private Adw.Leaflet leaflet;
    public Box left_box;
    public Box right_box;
    public Adw.Flap search_flap;
    public GlobalSearch global_search;
    private Stack stack = new Stack();
    private Stack left_stack;
    private Stack right_stack;

    private StreamInteractor stream_interactor;
    private Database db;
    private Config config;

    class construct {
        var shortcut = new Shortcut(new KeyvalTrigger(Key.F, ModifierType.CONTROL_MASK), new CallbackAction((widget, args) => {
            ((MainWindow) widget).search_flap.reveal_flap = true;
            return false;
        }));
        add_shortcut(shortcut);
    }

    public MainWindow(Application application, StreamInteractor stream_interactor, Database db, Config config) {
        Object(application : application);
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.config = config;

        this.title = "Dino";

        this.add_css_class("dino-main");

        ((Widget)this).realize.connect(restore_window_size);

        setup_unified();
        setup_headerbar();
        setup_stack();
    }

    private void setup_unified() {
        Builder builder = new Builder.from_resource("/im/dino/Dino/unified_main_content.ui");
        leaflet = (Adw.Leaflet) builder.get_object("leaflet");
        box.append(leaflet);
        left_box = (Box) builder.get_object("left_box");
        right_box = (Box) builder.get_object("right_box");
        left_stack = (Stack) builder.get_object("left_stack");
        right_stack = (Stack) builder.get_object("right_stack");
        conversation_view = (ConversationView) builder.get_object("conversation_view");
        search_flap = (Adw.Flap) builder.get_object("search_flap");
        conversation_selector = ((ConversationSelector) builder.get_object("conversation_list")).init(stream_interactor);
        conversation_selector.conversation_selected.connect_after(() => leaflet.navigate(Adw.NavigationDirection.FORWARD));

        Adw.Bin search_frame = (Adw.Bin) builder.get_object("search_frame");
        global_search = new GlobalSearch(stream_interactor);
        search_frame.set_child(global_search.get_widget());
    }

    private void setup_headerbar() {
        conversation_list_titlebar = get_conversation_list_titlebar();
        conversation_titlebar = new ConversationTitlebar();
        leaflet.bind_property("folded", conversation_list_titlebar, "show-end-title-buttons", BindingFlags.SYNC_CREATE);
        leaflet.bind_property("folded", conversation_titlebar.get_widget(), "show-start-title-buttons", BindingFlags.SYNC_CREATE);
        left_box.prepend(conversation_list_titlebar);
        right_box.prepend(conversation_titlebar.get_widget());
        leaflet.notify["folded"].connect_after(() => conversation_titlebar.back_button_visible = leaflet.folded);
        conversation_titlebar.back_pressed.connect(() => leaflet.navigate(Adw.NavigationDirection.BACK));
    }

    public void refresh_presence_button(string presence = "") {
        conversation_list_titlebar.unparent();
        conversation_list_titlebar = get_conversation_list_titlebar(presence);
        leaflet.bind_property("folded", conversation_list_titlebar, "show-end-title-buttons", BindingFlags.SYNC_CREATE);
        left_box.prepend(conversation_list_titlebar);
    }

    private void setup_stack() {
        stack.add_named(box, "main");
        stack.add_named(welcome_placeholder, "welcome_placeholder");
        stack.add_named(accounts_placeholder, "accounts_placeholder");
        set_content(stack);
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
        } else if (stack_state == StackState.CLEAN_START || stack_state == StackState.NO_ACTIVE_ACCOUNTS) {
            if (stack_state == StackState.CLEAN_START) {
                stack.set_visible_child_name("welcome_placeholder");
            } else if (stack_state == StackState.NO_ACTIVE_ACCOUNTS) {
                stack.set_visible_child_name("accounts_placeholder");
            }
        } else if (stack_state == StackState.NO_ACTIVE_CONVERSATIONS) {
            stack.set_visible_child_name("main");
            left_stack.set_visible_child_name("placeholder");
            right_stack.set_visible_child_name("placeholder");
        }
    }

    public void loop_conversations(bool backwards) {
        conversation_selector.loop_conversations(backwards);
    }

    public void restore_window_size() {
        Gdk.Display? display = Gdk.Display.get_default();
        if (display != null) {
            Gdk.Surface? surface = get_surface();
            Gdk.Monitor? monitor = display.get_monitor_at_surface(surface);

            if (monitor != null &&
                    config.window_width <= monitor.geometry.width &&
                    config.window_height <= monitor.geometry.height) {
                set_default_size(config.window_width, config.window_height);
            }
        }
        if (config.window_maximize) {
            maximize();
        }

        ((Widget)this).unrealize.connect(() => {
            save_window_size();
            config.window_maximize = this.maximized;
        });
    }

    public void save_window_size() {
        if (this.maximized) return;

        Gdk.Display? display = get_display();
        Gdk.Surface? surface = get_surface();
        if (display != null && surface != null) {
            Gdk.Monitor monitor = display.get_monitor_at_surface(surface);

            // Only store if the values have changed and are reasonable-looking.
            if (config.window_width != default_width && default_width > 0 && default_width <= monitor.geometry.width) {
                config.window_width = default_width;
            }
            if (config.window_height != default_height && default_height > 0 && default_height <= monitor.geometry.height) {
                config.window_height = default_height;
            }
        }
    }
}

public class WelcomePlaceholder : MainWindowPlaceholder {
    public WelcomePlaceholder() {
        status_page.title = _("Welcome to Dino!");
        status_page.description = _("Sign in or create an account to get started.");
        primary_button.label = _("Set up account");
        primary_button.visible = true;
    }
}

public class NoAccountsPlaceholder : MainWindowPlaceholder {
    public NoAccountsPlaceholder() {
        status_page.title = _("No active accounts");
        primary_button.label = _("Manage accounts");
        primary_button.visible = true;
    }
}

[GtkTemplate (ui = "/im/dino/Dino/unified_window_placeholder.ui")]
public class MainWindowPlaceholder : Box {
    [GtkChild] public unowned Adw.StatusPage status_page;
    [GtkChild] public unowned Button primary_button;
    [GtkChild] public unowned Button secondary_button;
}

}
