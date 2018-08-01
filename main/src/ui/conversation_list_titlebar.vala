using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_list_titlebar.ui")]
public class ConversationListTitlebar : Gtk.HeaderBar {

    public signal void conversation_opened(Conversation conversation);

    [GtkChild] private MenuButton add_button;
    [GtkChild] public ToggleButton search_button;

    private StreamInteractor stream_interactor;

    public ConversationListTitlebar(StreamInteractor stream_interactor, Window window) {
        this.stream_interactor = stream_interactor;

        custom_title = new Label("Dino") { visible = true, hexpand = true, xalign = 0 };
        custom_title.get_style_context().add_class("title");

        create_add_menu(window);
    }

    private void create_add_menu(Window window) {
        SimpleAction contacts_action = new SimpleAction("add_chat", null);
        contacts_action.activate.connect(() => {
            AddChatDialog add_chat_dialog = new AddChatDialog(stream_interactor, stream_interactor.get_accounts());
            add_chat_dialog.set_transient_for(window);
            add_chat_dialog.added.connect((conversation) => {
                conversation_opened(conversation);
            });
            add_chat_dialog.present();
        });
        GLib.Application.get_default().add_action(contacts_action);

        SimpleAction conference_action = new SimpleAction("add_conference", null);
        conference_action.activate.connect(() => {
            AddConferenceDialog add_conference_dialog = new AddConferenceDialog(stream_interactor);
            add_conference_dialog.set_transient_for(window);
            add_conference_dialog.conversation_opened.connect((conversation) => conversation_opened(conversation));
            add_conference_dialog.present();
        });
        GLib.Application.get_default().add_action(conference_action);

        Builder builder = new Builder.from_resource("/im/dino/Dino/menu_add.ui");
        MenuModel menu = builder.get_object("menu_add") as MenuModel;
        add_button.set_menu_model(menu);
    }
}

}
