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

[GtkTemplate (ui = "/im/dino/Dino/conversation_list_titlebar_csd.ui")]
public class ConversationListTitlebarCsd : Gtk.HeaderBar {

    [GtkChild] private unowned MenuButton add_button;
    [GtkChild] private unowned MenuButton menu_button;

    public ConversationListTitlebarCsd() {
        custom_title = new Label("Dino") { visible = true, hexpand = true, xalign = 0 };
        custom_title.get_style_context().add_class("title");

        create_add_menu(add_button, menu_button);
    }
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
