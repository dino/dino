using Gtk;

using Dino.Entities;
using Dino.Ui;

public class Dino.Ui.Application : Gtk.Application, Dino.Application {
    private Notifications notifications;
    private UnifiedWindow window;

    public Database db { get; set; }
    public Dino.Entities.Settings settings { get; set; }
    public StreamInteractor stream_interactor { get; set; }
    public Plugins.Registry plugin_registry { get; set; default = new Plugins.Registry(); }
    public SearchPathGenerator? search_path_generator { get; set; }

    public Application() throws Error {
        Object(application_id: "im.dino", flags: ApplicationFlags.HANDLES_OPEN);
        init();
        Notify.init("dino");
        Environment.set_application_name("Dino");
        Window.set_default_icon_name("dino");

        CssProvider provider = new CssProvider();
        provider.load_from_resource("/im/dino/pre_theme.css");
        StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, STYLE_PROVIDER_PRIORITY_THEME - 1);

        activate.connect(() => {
            if (window == null) {
                create_set_app_menu();
                window = new UnifiedWindow(this, stream_interactor);
                notifications = new Notifications(stream_interactor, window);
                notifications.start();
                notifications.conversation_selected.connect(window.on_conversation_selected);
            }
            window.present();
        });
    }

    public void handle_uri(string jid, string query, Gee.Map<string, string> options) {
        switch (query) {
            case "join":
                Dialog dialog = new Dialog.with_buttons(_("Join Conference"), window, Gtk.DialogFlags.MODAL | Gtk.DialogFlags.USE_HEADER_BAR, _("Join"), ResponseType.OK, _("Cancel"), ResponseType.CANCEL);
                dialog.modal = true;
                Widget ok_button = dialog.get_widget_for_response(ResponseType.OK);
                ok_button.get_style_context().add_class("suggested-action");
                AddConversation.Conference.ConferenceDetailsFragment conference_fragment = new AddConversation.Conference.ConferenceDetailsFragment(stream_interactor);
                conference_fragment.jid = jid;
                conference_fragment.set_editable();
                Box content_area = dialog.get_content_area();
                content_area.add(conference_fragment);
                dialog.response.connect((response_id) => {
                    if (response_id == ResponseType.OK) {
                        stream_interactor.get_module(MucManager.IDENTITY).join(conference_fragment.account, new Jid(conference_fragment.jid), conference_fragment.nick, conference_fragment.password);
                        dialog.destroy();
                    } else if (response_id == ResponseType.CANCEL) {
                        dialog.destroy();
                    }
                });
                dialog.present();
                break;
            case "message":
                AddConversation.Chat.Dialog dialog = new AddConversation.Chat.Dialog(stream_interactor, stream_interactor.get_accounts());
                dialog.set_filter(jid);
                dialog.set_transient_for(window);
                dialog.title = _("Start Chat");
                dialog.ok_button.label = _("Start");
                dialog.selected.connect((account, jid) => {
                    Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
                    stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation, true);
                    window.on_conversation_selected(conversation);
                });
                dialog.present();
                break;
        }
    }

    private void show_accounts_window() {
        ManageAccounts.Dialog dialog = new ManageAccounts.Dialog(stream_interactor, db);
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

        Builder builder = new Builder.from_resource("/im/dino/menu_app.ui");
        MenuModel menu = builder.get_object("menu_app") as MenuModel;

        set_app_menu(menu);
    }
}

