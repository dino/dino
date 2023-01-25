using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class OccupantsEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "occupants"; } }
    public double order { get { return 3; } }

    StreamInteractor stream_interactor;
    private Conversation? conversation;

    private MenuButton button = new MenuButton() { icon_name="system-users-symbolic", tooltip_text=Util.string_if_tooltips_active(_("Members")), visible=false };

    private OccupantMenu.View menu = null;

    public OccupantsEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            button.visible = true;
            OccupantMenu.View new_menu = new OccupantMenu.View(stream_interactor, conversation);
            button.set_popover(new_menu);
            menu = new_menu;
        } else {
            button.visible = false;
        }
    }

    public new void unset_conversation() {
        button.visible = false;
    }

    public Object? get_widget(Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return null;
        return button;
    }
}

}
