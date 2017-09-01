using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }

    StreamInteractor stream_interactor;

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public double order { get { return 0; } }
    public Plugins.ConversationTitlebarWidget get_widget(Plugins.WidgetType type) {
        if (type == Plugins.WidgetType.GTK) {
            return new MenuWidget(stream_interactor) { visible=true };
        }
        return null;
    }
}

class MenuWidget : MenuButton, Plugins.ConversationTitlebarWidget {

    private Conversation? conversation;

    public MenuWidget(StreamInteractor stream_interactor) {
        image = new Image.from_icon_name("open-menu-symbolic", IconSize.MENU);

        Builder builder = new Builder.from_resource("/im/dino/menu_conversation.ui");
        MenuModel menu = builder.get_object("menu_conversation") as MenuModel;
        set_menu_model(menu);

        SimpleAction contact_details_action = new SimpleAction("contact_details", null);
        contact_details_action.activate.connect(() => {
            ContactDetails.Dialog contact_details_dialog = new ContactDetails.Dialog(stream_interactor, conversation);
            contact_details_dialog.set_transient_for((Window) get_toplevel());
            contact_details_dialog.present();
        });
        GLib.Application.get_default().add_action(contact_details_action);
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;
    }
}

}
