using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }

    StreamInteractor stream_interactor;
    MenuWidget widget;

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public double order { get { return 0; } }
    public Plugins.ConversationTitlebarWidget? get_widget(Plugins.WidgetType type) {
        if (type == Plugins.WidgetType.GTK) {
            if (widget == null) {
                widget = new MenuWidget(stream_interactor) { visible=true };
            }
            return widget;
        }
        return null;
    }
}

class MenuWidget : Button, Plugins.ConversationTitlebarWidget {

    private Conversation? conversation;

    public MenuWidget(StreamInteractor stream_interactor) {
        image = new Image.from_icon_name("open-menu-symbolic", IconSize.MENU);

        clicked.connect(() => {
            ContactDetails.Dialog contact_details_dialog = new ContactDetails.Dialog(stream_interactor, conversation);
            contact_details_dialog.set_transient_for((Window) get_toplevel());
            contact_details_dialog.present();
        });
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;
    }
}

}
