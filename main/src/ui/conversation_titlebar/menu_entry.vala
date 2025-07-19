using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }
    public double order { get { return 0; } }

    StreamInteractor stream_interactor;
    private Conversation? conversation;

    MenuButton button = new MenuButton() { icon_name="view-more-symbolic" };

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        Menu menu_model = new Menu();
        menu_model.append(_("Conversation Details"), "conversation.details");
        menu_model.append(_("Close Conversation"), "app.close-current-conversation");
        Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
        button.popover = popover_menu;

        SimpleActionGroup action_group = new SimpleActionGroup();
        SimpleAction details_action = new SimpleAction("details", null);
        details_action.activate.connect((parameter) => {
            var variant = new Variant.tuple(new Variant[] {new Variant.int32(conversation.id), new Variant.string("about")});
            GLib.Application.get_default().activate_action("open-conversation-details", variant);
        });
        action_group.insert(details_action);
        button.insert_action_group("conversation", action_group);
    }

    public new void set_conversation(Conversation conversation) {
        button.sensitive = true;
        this.conversation = conversation;
    }

    public new void unset_conversation() {
        button.sensitive = false;
    }

    private void open_conversation_details() {
        var conversation_details = ConversationDetails.setup_dialog(conversation, stream_interactor, (Window)button.get_root());
        conversation_details.present();
    }

    public Object? get_widget(Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return null;
        return button;
    }
}
}
