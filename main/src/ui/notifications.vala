using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class Notifications : GLib.Object {

    private StreamInteractor stream_interactor;
    private Notify.Notification notification = new Notify.Notification("", null, null);

    public Notifications(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void start() {
        stream_interactor.get_module(MessageManager.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (!stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) {
            string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
            if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)) {
                string muc_occupant = Util.get_display_name(stream_interactor, message.from, conversation.account);
                display_name = muc_occupant + " in " + display_name;
            }
            notification.update(display_name, message.body, null);
            notification.set_image_from_pixbuf((new AvatarGenerator(40, 40)).draw_conversation(stream_interactor, conversation));
            notification.set_timeout(3);
            try {
                notification.show();
            } catch (Error error) { }
        }
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Notify.Notification notification = new Notify.Notification("Subscription request", jid.bare_jid.to_string(), null);
        notification.set_image_from_pixbuf((new AvatarGenerator(40, 40)).draw_jid(stream_interactor, jid, account));
        notification.add_action("accept", "Accept", () => {
            stream_interactor.get_module(PresenceManager.IDENTITY).approve_subscription(account, jid);
            try {
                notification.close();
            } catch (Error error) { }
        });
        notification.add_action("deny", "Deny", () => {
            stream_interactor.get_module(PresenceManager.IDENTITY).deny_subscription(account, jid);
            try {
                notification.close();
            } catch (Error error) { }
        });
        try {
            notification.show();
        } catch (Error error) { }
    }
}

}