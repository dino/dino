using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }
    public double order { get { return 0; } }

    StreamInteractor stream_interactor;
    private Conversation? conversation;

    MenuButton button = new MenuButton() { icon_name="dino-view-more-symbolic" };

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        Menu menu_model = new Menu();
        menu_model.append(_("Conversation Details"), "conversation.details");
        menu_model.append(_("Clear History"), "conversation.clear-history");
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
        SimpleAction clear_history_action = new SimpleAction("clear-history", null);
        clear_history_action.activate.connect((parameter) => {
            Adw.AlertDialog dialog = new Adw.AlertDialog(_("Clear history"), null);
            dialog.extra_child = new Gtk.Label(_("All messages in this conversation will be permanently deleted from this device.")) { xalign=0, wrap=true };
            dialog.add_response("clear", _("Clear History"));
            dialog.set_response_appearance("clear", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.add_response("cancel", _("Cancel"));
            dialog.close_response = "cancel";
            dialog.response.connect((response) => {
                if (response == "clear") {
                    stream_interactor.get_module(MessageDeletion.IDENTITY).delete_conversation_history(conversation);
                }
            });
            dialog.present((Gtk.Window)button.get_root());
        });
        action_group.insert(clear_history_action);
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
        var conversation_details = ConversationDetails.setup_dialog(conversation, stream_interactor);
        conversation_details.present((Window)button.get_root());
    }

    public Object? get_widget(Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return null;
        return button;
    }
}
}
