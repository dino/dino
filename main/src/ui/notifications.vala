using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class Notifications : Object {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private Gtk.Window window;
    private HashMap<Conversation, Notification> notifications = new HashMap<Conversation, Notification>(Conversation.hash_func, Conversation.equals_func);
    private Set<string>? active_notification_ids = null;

    private enum ClosedReason { // org.freedesktop.Notifications.NotificationClosed
        EXPIRED = 1,
        USER_DISMISSED = 2,
        CLOSE_NOTIFICATION = 3,
        UNDEFINED = 4
    }

    public Notifications(StreamInteractor stream_interactor, Gtk.Window window) {
        this.stream_interactor = stream_interactor;
        this.window = window;

        stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect(() => {
            if (active_notification_ids == null) {
                Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations();
                foreach (Conversation conversation in conversations) {
                    GLib.Application.get_default().withdraw_notification(conversation.id.to_string());
                }
                active_notification_ids = new HashSet<string>();
            } else {
                foreach (string id in active_notification_ids) {
                    GLib.Application.get_default().withdraw_notification(id);
                }
                active_notification_ids.clear();
            }
        });

        SimpleAction open_conversation_action = new SimpleAction("open-conversation", VariantType.INT32);
        open_conversation_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation != null) conversation_selected(conversation);
            window.present();
        });
        GLib.Application.get_default().add_action(open_conversation_action);

        SimpleAction accept_subscription_action = new SimpleAction("accept-subscription", VariantType.INT32);
        accept_subscription_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation == null) return;
            stream_interactor.get_module(PresenceManager.IDENTITY).approve_subscription(conversation.account, conversation.counterpart);
            if (stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, conversation.counterpart) == null) {
                AddContactDialog dialog = new AddContactDialog(stream_interactor);
                dialog.jid = conversation.counterpart.bare_jid.to_string();
                dialog.account = conversation.account;
                dialog.present();
            }
        });
        GLib.Application.get_default().add_action(accept_subscription_action);

        SimpleAction deny_subscription_action = new SimpleAction("deny-subscription", VariantType.INT32);
        deny_subscription_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation == null) return;
            stream_interactor.get_module(PresenceManager.IDENTITY).deny_subscription(conversation.account, conversation.counterpart);
        });
        GLib.Application.get_default().add_action(deny_subscription_action);
    }

    public void start() {
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect(on_received_subscription_request);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if  (!should_notify_message(message, conversation)) return;

        if (!notifications.has_key(conversation)) {
            notifications[conversation] = new Notification("");
            notifications[conversation].set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
        }
        if (!stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus()) {
            string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
            string text = message.body;
            if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)) {
                string muc_occupant = Util.get_display_name(stream_interactor, message.from, conversation.account);
                text = @"$muc_occupant: $text";
            }
            notifications[conversation].set_title(display_name);
            notifications[conversation].set_body(text);
            try {
                notifications[conversation].set_icon(get_pixbuf_icon((new AvatarGenerator(40, 40)).draw_conversation(stream_interactor, conversation)));
            } catch (Error e) { }
            window.get_application().send_notification(conversation.id.to_string(), notifications[conversation]);
            active_notification_ids.add(conversation.id.to_string());
            window.urgency_hint = true;
        }
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Notification notification = new Notification(_("Subscription request"));
        notification.set_body(jid.bare_jid.to_string());
        try {
            notification.set_icon(get_pixbuf_icon((new AvatarGenerator(40, 40)).draw_jid(stream_interactor, jid, account)));
        } catch (Error e) { }
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
        notification.add_button_with_target_value(_("Accept"), "app.accept-subscription", conversation.id);
        notification.add_button_with_target_value(_("Deny"), "app.deny-subscription", conversation.id);
        window.get_application().send_notification(null, notification);
    }

    private bool should_notify_message(Entities.Message message, Conversation conversation) {
        Conversation.NotifySetting notify = conversation.get_notification_setting(stream_interactor);
        if (notify == Conversation.NotifySetting.OFF) return false;
        Jid? nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        if (notify == Conversation.NotifySetting.HIGHLIGHT && nick != null) {
            return Regex.match_simple("""\b""" + Regex.escape_string(nick.resourcepart) + """\b""", message.body, RegexCompileFlags.CASELESS);
        }
        return true;
    }

    private Icon get_pixbuf_icon(Gdk.Pixbuf avatar) throws Error {
        uint8[] buffer;
        avatar.save_to_buffer(out buffer, "png");
        return new BytesIcon(new Bytes(buffer));
    }
}

}
