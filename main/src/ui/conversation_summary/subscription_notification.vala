using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class SubscriptionNotitication : Object {

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private ConversationView conversation_view;

    public SubscriptionNotitication(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect((jid, account) => {
            Conversation relevant_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(relevant_conversation, true);
            if (conversation != null && account.equals(conversation.account) && jid.equals(conversation.counterpart)) {
                show_notification();
            }
        });
    }

    public void init(Conversation conversation, ConversationView conversation_view) {
        this.conversation = conversation;
        this.conversation_view = conversation_view;

        if (stream_interactor.get_module(PresenceManager.IDENTITY).exists_subscription_request(conversation.account, conversation.counterpart)) {
            show_notification();
        }
    }

    private void show_notification() {
        Box box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        Button accept_button = new Button() { label=_("Accept"), visible=true };
        Button deny_button = new Button() { label=_("Deny"), visible=true };
        GLib.Application app = GLib.Application.get_default();
        accept_button.clicked.connect(() => {
            app.activate_action("accept-subscription", conversation.id);
            conversation_view.remove_notification(box);
        });
        deny_button.clicked.connect(() => {
            app.activate_action("deny-subscription", conversation.id);
            conversation_view.remove_notification(box);
        });
        box.add(new Label(_("This contact would like to add you to their contact list")) { margin_end=10, visible=true });
        box.add(accept_button);
        box.add(deny_button);
        conversation_view.add_notification(box);
    }
}

}
