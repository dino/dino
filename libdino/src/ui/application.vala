using Gtk;

using Dino.Entities;

public class Dino.Ui.Application : Gtk.Application {

    private Database db;
    private StreamInteractor stream_interaction;

    private Notifications notifications;
    private UnifiedWindow? window;
    private ConversationSelector.View? filterable_conversation_list;
    private ConversationSelector.List? conversation_list;
    private ConversationSummary.View? conversation_frame;
    private ChatInput? chat_input;

    public Application() {
        this.db = new Database("store.sqlite3");
        this.stream_interaction = new StreamInteractor(db);

        AvatarManager.start(stream_interaction, db);
        MessageManager.start(stream_interaction, db);
        CounterpartInteractionManager.start(stream_interaction);
        PresenceManager.start(stream_interaction);
        MucManager.start(stream_interaction);
        PgpManager.start(stream_interaction, db);
        RosterManager.start(stream_interaction);
        ConversationManager.start(stream_interaction, db);
        ChatInteraction.start(stream_interaction);

        Notify.init("dino");
        notifications = new Notifications(stream_interaction);
        notifications.start();

        load_css();
    }

    public override void activate() {
        create_set_app_menu();
        create_window();
        window.show_all();
        restore();
    }

    private void create_window() {
        window = new UnifiedWindow(this, stream_interaction);

        filterable_conversation_list = window.filterable_conversation_list;
        conversation_list = window.filterable_conversation_list.conversation_list;
        conversation_frame = window.conversation_frame;
        chat_input = window.chat_input;
    }

    private void show_accounts_window() {
        ManageAccounts.Dialog dialog = new ManageAccounts.Dialog(stream_interaction, db);
        dialog.set_transient_for(window);
        dialog.account_enabled.connect(add_connection);
        dialog.account_disabled.connect(remove_connection);
        dialog.show();
    }

    private void show_settings_window() {
        SettingsDialog dialog = new SettingsDialog();
        dialog.set_transient_for(window);
        dialog.show();
    }

    private void create_set_app_menu() {
        SimpleAction accounts_action = new SimpleAction("accounts", null);
        accounts_action.activate.connect(show_accounts_window);
        add_action(accounts_action);

        SimpleAction settings_action = new SimpleAction("settings", null);
        settings_action.activate.connect(show_settings_window);
        add_action(settings_action);

        SimpleAction quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(quit);
        add_action(quit_action);
        add_accelerator("<Ctrl>Q", "app.quit", null);

        Builder builder = new Builder.from_resource("/org/dino-im/menu_app.ui");
        MenuModel menu = builder.get_object("menu_app") as MenuModel;

        set_app_menu(menu);
    }

    private void restore() {
        foreach (Account account in db.get_accounts()) {
            if (account.enabled) add_connection(account);
        }
    }

    private void add_connection(Account account) {
        stream_interaction.connect(account);
    }

    private void remove_connection(Account account) {
        stream_interaction.disconnect(account);
    }

    private void load_css() {
        var css_provider = new Gtk.CssProvider ();
        try {
            var file = File.new_for_uri("resource:///org/dino-im/style.css");
            css_provider.load_from_file (file);
        } catch (GLib.Error e) {
            warning ("loading css: %s", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

