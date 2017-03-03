using Gtk;

using Dino.Entities;

[GtkTemplate (ui = "/org/dino-im/conversation_list_titlebar.ui")]
public class Dino.Ui.ConversationListTitlebar : Gtk.HeaderBar {

    public signal void conversation_opened(Conversation conversation);

    [GtkChild]
    private MenuButton add_button;

    [GtkChild]
    public ToggleButton search_button;

    private StreamInteractor stream_interactor;

    public ConversationListTitlebar(Window application, StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        create_add_menu(application);
    }

    private void create_add_menu(Window window) {
        SimpleAction contacts_action = new SimpleAction("add_chat", null);
        contacts_action.activate.connect(() => {
            AddConversation.Chat.Dialog add_chat_dialog = new AddConversation.Chat.Dialog(stream_interactor);
            add_chat_dialog.set_transient_for((ApplicationWindow) get_toplevel());
            add_chat_dialog.conversation_opened.connect((conversation) => conversation_opened(conversation));
            add_chat_dialog.show();
        });
        window.get_application().add_action(contacts_action);

        SimpleAction conference_action = new SimpleAction("add_conference", null);
        conference_action.activate.connect(() => {
            AddConversation.Conference.Dialog add_conference_dialog = new AddConversation.Conference.Dialog(stream_interactor);
            add_conference_dialog.set_transient_for((ApplicationWindow) get_toplevel());
            add_conference_dialog.conversation_opened.connect((conversation) => conversation_opened(conversation));
            add_conference_dialog.show();
        });
        window.get_application().add_action(conference_action);

        Builder builder = new Builder.from_resource("/org/dino-im/menu_add.ui");
        MenuModel menu = builder.get_object("menu_add") as MenuModel;
        add_button.set_menu_model(menu);
    }
}

