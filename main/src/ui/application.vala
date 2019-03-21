using Gtk;

using Dino.Entities;
using Dino.Ui;
using Xmpp;

public class Dino.Ui.Application : Gtk.Application, Dino.Application {
    private Notifications notifications;
    private UnifiedWindow window;
    private UnifiedWindowController controller;

    public Database db { get; set; }
    public Dino.Entities.Settings settings { get; set; }
    public StreamInteractor stream_interactor { get; set; }
    public Plugins.Registry plugin_registry { get; set; default = new Plugins.Registry(); }
    public SearchPathGenerator? search_path_generator { get; set; }

    public Application() throws Error {
        Object(application_id: "im.dino.Dino", flags: ApplicationFlags.HANDLES_OPEN);
        init();
        Environment.set_application_name("Dino");
        Window.set_default_icon_name("im.dino.Dino");

        CssProvider provider = new CssProvider();
        provider.load_from_resource("/im/dino/Dino/theme.css");
        StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        create_actions();

        activate.connect(() => {
            if (window == null) {
                controller = new UnifiedWindowController(this, stream_interactor, db);
                window = new UnifiedWindow(this, stream_interactor, db);
                controller.set_window(window);

                notifications = new Notifications(stream_interactor, window);
                notifications.start();
                notifications.conversation_selected.connect((conversation) => window.on_conversation_selected(conversation));
            }
            window.present();
        });
    }

    public void handle_uri(string jid, string query, Gee.Map<string, string> options) {
        switch (query) {
            case "join":
                Dialog dialog = new Dialog.with_buttons(_("Join Conference"), window, Gtk.DialogFlags.MODAL | Gtk.DialogFlags.USE_HEADER_BAR, _("Join"), ResponseType.OK, _("Cancel"), ResponseType.CANCEL);
                dialog.modal = true;
                Button ok_button = dialog.get_widget_for_response(ResponseType.OK) as Button;
                ok_button.get_style_context().add_class("suggested-action");
                ConferenceDetailsFragment conference_fragment = new ConferenceDetailsFragment(stream_interactor, ok_button);
                conference_fragment.jid = jid;
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
                Gee.List<Account> accounts = stream_interactor.get_accounts();
                if (accounts.size == 1) {
                    Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(new Jid(jid), accounts[0], Conversation.Type.CHAT);
                    stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation, true);
                    window.on_conversation_selected(conversation);
                } else {
                    AddChatDialog dialog = new AddChatDialog(stream_interactor, stream_interactor.get_accounts());
                    dialog.set_filter(jid);
                    dialog.set_transient_for(window);
                    dialog.added.connect((conversation) => {
                        window.on_conversation_selected(conversation);
                    });
                    dialog.present();
                }
                break;
        }
    }

    private void create_actions() {
        SimpleAction accounts_action = new SimpleAction("accounts", null);
        accounts_action.activate.connect(show_accounts_window);
        add_action(accounts_action);

        SimpleAction settings_action = new SimpleAction("settings", null);
        settings_action.activate.connect(show_settings_window);
        add_action(settings_action);

        SimpleAction quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(quit);
        add_action(quit_action);
        set_accels_for_action("app.quit", new string[]{"<Ctrl>Q"});

        SimpleAction open_conversation_action = new SimpleAction("open-conversation", VariantType.INT32);
        open_conversation_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation != null) window.on_conversation_selected(conversation);
            window.present();
        });
        add_action(open_conversation_action);

        SimpleAction deny_subscription_action = new SimpleAction("deny-subscription", VariantType.INT32);
        deny_subscription_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation == null) return;
            stream_interactor.get_module(PresenceManager.IDENTITY).deny_subscription(conversation.account, conversation.counterpart);
        });
        add_action(deny_subscription_action);

        SimpleAction contacts_action = new SimpleAction("add_chat", null);
        contacts_action.activate.connect(() => {
            AddChatDialog add_chat_dialog = new AddChatDialog(stream_interactor, stream_interactor.get_accounts());
            add_chat_dialog.set_transient_for(window);
            add_chat_dialog.added.connect((conversation) => {
                window.on_conversation_selected(conversation);
            });
            add_chat_dialog.present();
        });
        add_action(contacts_action);
        set_accels_for_action("app.add_chat", new string[]{"<Ctrl>T"});

        SimpleAction conference_action = new SimpleAction("add_conference", null);
        conference_action.activate.connect(() => {
            AddConferenceDialog add_conference_dialog = new AddConferenceDialog(stream_interactor);
            add_conference_dialog.set_transient_for(window);
            add_conference_dialog.conversation_opened.connect(conversation => controller.select_conversation(conversation));
            add_conference_dialog.present();
        });
        add_action(conference_action);
        set_accels_for_action("app.add_conference", new string[]{"<Ctrl>G"});

        SimpleAction loop_conversations_action = new SimpleAction("loop_conversations", null);
        loop_conversations_action.activate.connect(() => {controller.loop_conversations(false);});
        add_action(loop_conversations_action);
        set_accels_for_action("app.loop_conversations", new string[]{"<Ctrl>Tab"});

        SimpleAction loop_conversations_bw_action = new SimpleAction("loop_conversations_bw", null);
        loop_conversations_bw_action.activate.connect(() => {controller.loop_conversations(true);});
        add_action(loop_conversations_bw_action);
        set_accels_for_action("app.loop_conversations_bw", new string[]{"<Ctrl><Shift>Tab"});
    }

    public bool use_csd() {
        return Environment.get_variable("GTK_CSD") != "0";
    }

    private void show_accounts_window() {
        ManageAccounts.Dialog dialog = new ManageAccounts.Dialog(stream_interactor, db);
        dialog.set_transient_for(get_active_window());
        dialog.account_enabled.connect(add_connection);
        dialog.account_disabled.connect(remove_connection);
        dialog.present();
    }

    private void show_settings_window() {
        SettingsDialog dialog = new SettingsDialog();
        dialog.set_transient_for(get_active_window());
        dialog.present();
    }
}

