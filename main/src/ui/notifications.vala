using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class Notifications : Object {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private Gtk.Window window;
    private HashMap<Conversation, Notification> notifications = new HashMap<Conversation, Notification>(Conversation.hash_func, Conversation.equals_func);
    private Set<string>? active_conversation_ids = null;
    private Set<string>? active_ids = new HashSet<string>();

    public Notifications(StreamInteractor stream_interactor, Gtk.Window window) {
        this.stream_interactor = stream_interactor;
        this.window = window;

        stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect((focused_conversation) => {
            if (active_conversation_ids == null) {
                Gee.List<Conversation> conversations = stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations();
                foreach (Conversation conversation in conversations) {
                    GLib.Application.get_default().withdraw_notification(conversation.id.to_string());
                }
                active_conversation_ids = new HashSet<string>();
            } else {
                foreach (string id in active_conversation_ids) {
                    GLib.Application.get_default().withdraw_notification(id);
                }
                active_conversation_ids.clear();
            }

            string subscription_id = focused_conversation.id.to_string() + "-subscription";
            if (active_ids.contains(subscription_id)) {
                GLib.Application.get_default().withdraw_notification(subscription_id);
            }
        });
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
            active_conversation_ids.add(conversation.id.to_string());
            window.urgency_hint = true;
        }
    }

    private void on_received_subscription_request(Jid jid, Account account) {
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
        if (stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus(conversation)) return;

        Notification notification = new Notification(_("Subscription request"));
        notification.set_body(jid.bare_jid.to_string());
        try {
            notification.set_icon(get_pixbuf_icon((new AvatarGenerator(40, 40)).draw_jid(stream_interactor, jid, account)));
        } catch (Error e) { }
        notification.set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
        notification.add_button_with_target_value(_("Accept"), "app.accept-subscription", conversation.id);
        notification.add_button_with_target_value(_("Deny"), "app.deny-subscription", conversation.id);
        window.get_application().send_notification(conversation.id.to_string() + "-subscription", notification);
        active_ids.add(conversation.id.to_string() + "-subscription");
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

    private Icon get_pixbuf_icon(Cairo.ImageSurface surface) throws Error {
        Gdk.Pixbuf avatar = Gdk.pixbuf_get_from_surface(surface, 0, 0, surface.get_width(), surface.get_height());
        uint8[] buffer;
        avatar.save_to_buffer(out buffer, "png");
        return new BytesIcon(new Bytes(buffer));
    }
}

}
