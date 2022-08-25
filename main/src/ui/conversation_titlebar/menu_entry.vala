using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }
    public double order { get { return 0; } }

    StreamInteractor stream_interactor;
    private Conversation? conversation;

    Button button = new Button() { icon_name="open-menu-symbolic" };

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        button.clicked.connect(on_clicked);
    }

    public new void set_conversation(Conversation conversation) {
        button.sensitive = true;
        this.conversation = conversation;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            button.tooltip_text = Util.string_if_tooltips_active("Channel details");
        } else {
            button.tooltip_text = Util.string_if_tooltips_active("Conversation details");
        }
    }

    public new void unset_conversation() {
        button.sensitive = false;
    }

    private void on_clicked() {
        ContactDetails.Dialog contact_details_dialog = new ContactDetails.Dialog(stream_interactor, conversation);
        contact_details_dialog.set_transient_for((Window) button.get_root());
        contact_details_dialog.present();
    }

    public Object? get_widget(Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return null;
        return button;
    }
}
}
