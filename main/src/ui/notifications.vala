using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class Notifications : Object {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private Gtk.Window window;
    private HashMap<Conversation, Notify.Notification> notifications = new HashMap<Conversation, Notify.Notification>(Conversation.hash_func, Conversation.equals_func);

    private enum ClosedReason { // org.freedesktop.Notifications.NotificationClosed
        EXPIRED = 1,
        USER_DISMISSED = 2,
        CLOSE_NOTIFICATION = 3,
        UNDEFINED = 4
    }

    public Notifications(StreamInteractor stream_interactor, Gtk.Window window) {
        this.stream_interactor = stream_interactor;
        this.window = window;
    }

    public void start() {
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if  (!should_notify_message(message, conversation)) return;

        if (!notifications.has_key(conversation)) {
            notifications[conversation] = new Notify.Notification("", null, null);
            notifications[conversation].set_hint("transient", true);
            notifications[conversation].add_action("default", "Open", () => {
                conversation_selected(conversation);
#if GDK3_WITH_X11
                Gdk.X11.Window x11window = window.get_window() as Gdk.X11.Window;
                if (x11window != null) {
                    window.present_with_time(Gdk.X11.get_server_time(x11window));
                } else {
                    window.present();
                }
#else
                window.present();
#endif
            });
        }
        if (!stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) {
            string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
            string text = message.body;
            if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)) {
                string muc_occupant = Util.get_display_name(stream_interactor, message.from, conversation.account);
                text = @"<b>$muc_occupant</b> $text";
            }
            notifications[conversation].update(display_name, text, null);
            notifications[conversation].set_image_from_pixbuf((new AvatarGenerator(40, 40)).draw_conversation(stream_interactor, conversation));
            notifications[conversation].set_timeout(3);
            try {
                notifications[conversation].show();
            } catch (Error error) { }
        }
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Notify.Notification notification = new Notify.Notification(_("Subscription request"), jid.bare_jid.to_string(), null);
        notification.set_image_from_pixbuf((new AvatarGenerator(40, 40)).draw_jid(stream_interactor, jid, account));
        notification.add_action("accept", _("Accept"), () => {
            stream_interactor.get_module(PresenceManager.IDENTITY).approve_subscription(account, jid);

            if (stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, jid) == null) {
                AddConversation.Chat.AddContactDialog dialog = new AddConversation.Chat.AddContactDialog(stream_interactor);
                dialog.jid = jid.bare_jid.to_string();
                dialog.account = account;
                dialog.present();
            }
            try {
                notification.close();
            } catch (Error error) { }
        });
        notification.add_action("deny", _("Deny"), () => {
            stream_interactor.get_module(PresenceManager.IDENTITY).deny_subscription(account, jid);
            try {
                notification.close();
            } catch (Error error) { }
        });
        try {
            notification.show();
        } catch (Error error) { }
    }

    private bool should_notify_message(Entities.Message message, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
        if (notify == Conversation.NotifySetting.OFF) return false;
        Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (notify == Conversation.NotifySetting.HIGHLIGHT && nick != null && !message.body.contains(nick.resourcepart)) return false;
        return true;
    }
}

}