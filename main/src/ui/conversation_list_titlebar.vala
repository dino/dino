using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_list_titlebar.ui")]
public class ConversationListTitlebar : Gtk.Box {

    [GtkChild] private unowned MenuButton add_button;
    [GtkChild] private unowned MenuButton menu_button;

    public ConversationListTitlebar() {
        create_add_menu(add_button, menu_button);
    }
}

public static HeaderBar get_conversation_list_titlebar_csd() {
    Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_list_titlebar_csd.ui");
    MenuButton add_button = (MenuButton) builder.get_object("add_button");
    MenuButton menu_button = (MenuButton) builder.get_object("menu_button");
    create_add_menu(add_button, menu_button);
    return (HeaderBar) builder.get_object("header_bar");
}

private static void create_add_menu(MenuButton add_button, MenuButton menu_button) {
    Builder add_builder = new Builder.from_resource("/im/dino/Dino/menu_add.ui");
    MenuModel add_menu_model = add_builder.get_object("menu_add") as MenuModel;
    add_button.set_menu_model(add_menu_model);

    Builder menu_builder = new Builder.from_resource("/im/dino/Dino/menu_app.ui");
    MenuModel menu_menu_model = menu_builder.get_object("menu_app") as MenuModel;
    menu_button.set_menu_model(menu_menu_model);
}

}
