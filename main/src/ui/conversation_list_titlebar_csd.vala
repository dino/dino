using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_list_titlebar_csd.ui")]
public class ConversationListTitlebarCsd : Gtk.HeaderBar {

    public signal void conversation_opened(Conversation conversation);

    [GtkChild] private MenuButton add_button;
    [GtkChild] private MenuButton menu_button;

    private StreamInteractor stream_interactor;

    public ConversationListTitlebarCsd(StreamInteractor stream_interactor, Window window) {
        this.stream_interactor = stream_interactor;

        custom_title = new Label("Dino") { visible = true, hexpand = true, xalign = 0 };
        custom_title.get_style_context().add_class("title");

        create_add_menu(window);
    }

    private void create_add_menu(Window window) {
        Builder add_builder = new Builder.from_resource("/im/dino/Dino/menu_add.ui");
        MenuModel add_menu_model = add_builder.get_object("menu_add") as MenuModel;
        add_button.set_menu_model(add_menu_model);

        Builder menu_builder = new Builder.from_resource("/im/dino/Dino/menu_app.ui");
        MenuModel menu_menu_model = menu_builder.get_object("menu_app") as MenuModel;
        menu_button.set_menu_model(menu_menu_model);
    }
}

}
