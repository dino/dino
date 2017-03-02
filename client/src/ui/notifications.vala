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
        MessageManager.get_instance(stream_interactor).message_received.connect(on_message_received);
        PresenceManager.get_instance(stream_interactor).received_subscription_request.connect(on_received_subscription_request);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (!ChatInteraction.get_instance(stream_interactor).is_active_focus()) {
            string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
            if (MucManager.get_instance(stream_interactor).is_groupchat(conversation.counterpart, conversation.account)) {
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
            PresenceManager.get_instance(stream_interactor).approve_subscription(account, jid);
            try {
                notification.close();
            } catch (Error error) { }
        });
        notification.add_action("deny", "Deny", () => {
            PresenceManager.get_instance(stream_interactor).deny_subscription(account, jid);
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