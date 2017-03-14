using Gtk;

using Dino.Entities;
using Dino.Ui;

public class Dino.Ui.Application : Dino.Application {
    private Notifications notifications;
    private UnifiedWindow? window;
    private ConversationSelector.View? filterable_conversation_list;
    private ConversationSelector.List? conversation_list;
    private ConversationSummary.View? conversation_frame;
    private ChatInput? chat_input;

    public Application() throws Error {
        Notify.init("dino");
        notifications = new Notifications(stream_interaction);
        notifications.start();
        Environment.set_application_name("Dino");
        IconTheme.get_default().add_resource_path("/org/dino-im/icons");
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
}

