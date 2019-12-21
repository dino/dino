using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_list_titlebar.ui")]
public class ConversationListTitlebar : Gtk.Box {

    [GtkChild] private MenuButton add_button;
    [GtkChild] private MenuButton menu_button;

    private StreamInteractor stream_interactor;

    public ConversationListTitlebar(StreamInteractor stream_interactor, Window window) {
        this.stream_interactor = stream_interactor;
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
