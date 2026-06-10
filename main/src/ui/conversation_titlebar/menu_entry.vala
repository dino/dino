using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class MenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "menu"; } }
    public double order { get { return 0; } }

    StreamInteractor stream_interactor;
    private Conversation? conversation;
    private SimpleAction resync_history_action = new SimpleAction("resync-history", null);

    MenuButton button = new MenuButton() { icon_name="dino-view-more-symbolic" };

    public MenuEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        button.sensitive = false;
        resync_history_action.set_enabled(false);

        Menu menu_model = new Menu();
        menu_model.append(_("Conversation Details"), "conversation.details");
        menu_model.append(_("Resync Message History"), "conversation.resync-history");
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
        resync_history_action.activate.connect((parameter) => {
            if (conversation == null) return;

            Conversation resync_conversation = (!)conversation;
            Cancellable cancellable = new Cancellable();
            resync_history_action.set_enabled(false);
            stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync.resync_conversation.begin(resync_conversation, cancellable, (_, res) => {
                try {
                    stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync.resync_conversation.end(res);
                } catch (Error e) {
                    debug("Resync message history failed: %s", e.message);
                }
                update_resync_history_action();
            });
        });
        action_group.insert(resync_history_action);
        button.insert_action_group("conversation", action_group);
    }

    public new void set_conversation(Conversation conversation) {
        button.sensitive = true;
        this.conversation = conversation;
        update_resync_history_action();
    }

    public new void unset_conversation() {
        button.sensitive = false;
        this.conversation = null;
        update_resync_history_action();
    }

    private void update_resync_history_action() {
        Conversation? current_conversation = conversation;
        if (current_conversation == null) {
            resync_history_action.set_enabled(false);
            return;
        }

        Cancellable? cancellable;
        int messages;
        int total_messages;
        bool active = stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync.get_conversation_resync_state((!)current_conversation, out cancellable, out messages, out total_messages);
        resync_history_action.set_enabled(!active);
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
