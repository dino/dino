using Gtk;

using Dino.Entities;
using Dino.Ui;

public class Dino.Ui.Application : Gtk.Application, Dino.Application {
    private Notifications notifications;
    private UnifiedWindow window;

    public Database db { get; set; }
    public StreamInteractor stream_interaction { get; set; }
    public Plugins.Registry plugin_registry { get; set; default = new Plugins.Registry(); }
    public SearchPathGenerator? search_path_generator { get; set; }

    public Application() throws Error {
        init();
        Notify.init("dino");
        Environment.set_application_name("Dino");
        Gtk.Window.set_default_icon_name("dino");
        IconTheme.get_default().add_resource_path("/org/dino-im/icons");

        activate.connect(() => {
            create_set_app_menu();
            window = new UnifiedWindow(this, stream_interaction);
            notifications = new Notifications(stream_interaction, window);
            notifications.start();
            notifications.conversation_selected.connect(window.on_conversation_selected);
            window.present();
        });
    }

    private void show_accounts_window() {
        ManageAccounts.Dialog dialog = new ManageAccounts.Dialog(stream_interaction, db);
        dialog.set_transient_for(window);
        dialog.account_enabled.connect(add_connection);
        dialog.account_disabled.connect(remove_connection);
        dialog.present();
    }

    private void show_settings_window() {
        SettingsDialog dialog = new SettingsDialog();
        dialog.set_transient_for(window);
        dialog.present();
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
}

