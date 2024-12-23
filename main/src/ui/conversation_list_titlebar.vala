using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public static Adw.HeaderBar get_conversation_list_titlebar(string presence = "") {
    Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_list_titlebar.ui");
    MenuButton add_button = (MenuButton) builder.get_object("add_button");
    MenuButton presence_button = (MenuButton) builder.get_object("presence_button");
    MenuButton menu_button = (MenuButton) builder.get_object("menu_button");
    switch(presence) {
        case Xmpp.Presence.Stanza.SHOW_AWAY: presence_button.set_icon_name("dino-status-away"); break;
        case Xmpp.Presence.Stanza.SHOW_DND: presence_button.set_icon_name("dino-status-dnd"); break;
        case Xmpp.Presence.Stanza.SHOW_XA: presence_button.set_icon_name("dino-status-xa"); break;
        case "offline": presence_button.set_icon_name("dino-status-offline"); break;
        default: presence_button.set_icon_name("dino-status-online"); break;
    }
    create_add_menu(add_button, presence_button, menu_button);
    return (Adw.HeaderBar) builder.get_object("header_bar");
}

private static void create_add_menu(MenuButton add_button, MenuButton presence_button, MenuButton menu_button) {
    add_button.tooltip_text = Util.string_if_tooltips_active(_("Start Conversation"));

    Builder add_builder = new Builder.from_resource("/im/dino/Dino/menu_add.ui");
    MenuModel add_menu_model = add_builder.get_object("menu_add") as MenuModel;
    add_button.set_menu_model(add_menu_model);

    Builder presence_builder = new Builder.from_resource("/im/dino/Dino/menu_presence.ui");
    MenuModel presence_menu_model = presence_builder.get_object("menu_presence") as MenuModel;
    presence_button.set_menu_model(presence_menu_model);

    Builder menu_builder = new Builder.from_resource("/im/dino/Dino/menu_app.ui");
    MenuModel menu_menu_model = menu_builder.get_object("menu_app") as MenuModel;
    menu_button.set_menu_model(menu_menu_model);
}

}
