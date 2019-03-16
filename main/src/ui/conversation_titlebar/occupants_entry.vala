using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class OccupantsEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "occupants"; } }

    StreamInteractor stream_interactor;
    OccupantsWidget widget;

    public OccupantsEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public double order { get { return 3; } }
    public Plugins.ConversationTitlebarWidget? get_widget(Plugins.WidgetType type) {
        if (type == Plugins.WidgetType.GTK) {
            if (widget == null) {
                widget = new OccupantsWidget(stream_interactor) { visible=true };
            }
            return widget;
        }
        return null;
    }
}

class OccupantsWidget : MenuButton, Plugins.ConversationTitlebarWidget {

    private Conversation? conversation;
    private StreamInteractor stream_interactor;
    private OccupantMenu.View menu = null;

    public OccupantsWidget(StreamInteractor stream_interactor) {
        image = new Image.from_icon_name("system-users-symbolic", IconSize.MENU);
        tooltip_text = _("Members");

        this.stream_interactor = stream_interactor;
        set_use_popover(true);
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;

        visible = conversation.type_ == Conversation.Type.GROUPCHAT;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            OccupantMenu.View new_menu = new OccupantMenu.View(stream_interactor, conversation);
            set_popover(new_menu);
            if (menu != null) menu.destroy();
            menu = new_menu;
        }
    }
}

}
