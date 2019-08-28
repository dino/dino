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
        stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect((content_item, conversation) => notify_content_item.begin(content_item, conversation));
        stream_interactor.get_module(NotificationEvents.IDENTITY).notify_subscription_request.connect(notify_subscription_request);
        stream_interactor.get_module(NotificationEvents.IDENTITY).notify_connection_error.connect(notify_connection_error);
        stream_interactor.get_module(NotificationEvents.IDENTITY).notify_muc_invite.connect(on_invite_received);
    }

    private async void notify_content_item(ContentItem content_item, Conversation conversation) {
        if (!notifications.has_key(conversation)) {
            notifications[conversation] = new Notification("");
            notifications[conversation].set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
        }
        string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
        string text = "";
        switch (content_item.type_) {
            case MessageItem.TYPE:
                Message message = (content_item as MessageItem).message;
                text = message.body;
                break;
            case FileItem.TYPE:
                FileItem file_item = content_item as FileItem;
                FileTransfer transfer = file_item.file_transfer;

                bool file_is_image = transfer.mime_type != null && transfer.mime_type.has_prefix("image");
                if (transfer.direction == Message.DIRECTION_SENT) {
                    text = file_is_image ? _("Image sent") : _("File sent");
                } else {
                    text = file_is_image ? _("Image received") : _("File received");
                }
                break;
        }
        if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)) {
            string muc_occupant = Util.get_display_name(stream_interactor, content_item.jid, conversation.account);
            text = @"$muc_occupant: $text";
        }
        notifications[conversation].set_title(display_name);
        notifications[conversation].set_body(text);
        try {
            Cairo.ImageSurface conversation_avatar = yield (new AvatarGenerator(40, 40)).draw_conversation(stream_interactor, conversation);
            notifications[conversation].set_icon(get_pixbuf_icon(conversation_avatar));
        } catch (Error e) { }
        window.get_application().send_notification(conversation.id.to_string(), notifications[conversation]);
        active_conversation_ids.add(conversation.id.to_string());

        // Don't set urgency hint in GNOME, produces "Window is active" notification
        var desktop_env = Environment.get_variable("XDG_CURRENT_DESKTOP");
        if (desktop_env == null || !desktop_env.down().contains("gnome")) {
            window.urgency_hint = true;
        }
    }

    private async void notify_subscription_request(Conversation conversation) {
        Notification notification = new Notification(_("Subscription request"));
        notification.set_body(conversation.counterpart.to_string());
        try {
            Cairo.ImageSurface jid_avatar = yield (new AvatarGenerator(40, 40)).draw_jid(stream_interactor, conversation.counterpart, conversation.account);
            notification.set_icon(get_pixbuf_icon(jid_avatar));
        } catch (Error e) { }
        notification.set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
        notification.add_button_with_target_value(_("Accept"), "app.accept-subscription", conversation.id);
        notification.add_button_with_target_value(_("Deny"), "app.deny-subscription", conversation.id);
        window.get_application().send_notification(conversation.id.to_string() + "-subscription", notification);
        active_ids.add(conversation.id.to_string() + "-subscription");
    }

    private void notify_connection_error(Account account, ConnectionManager.ConnectionError error) {
        Notification notification = new Notification(_("Could not connect to %s").printf(account.bare_jid.domainpart));
        switch (error.source) {
            case ConnectionManager.ConnectionError.Source.SASL:
                notification.set_body("Wrong password");
                break;
            case ConnectionManager.ConnectionError.Source.TLS:
                notification.set_body("Invalid TLS certificate");
                break;
        }
        window.get_application().send_notification(account.id.to_string() + "-connection-error", notification);
    }

    private async void on_invite_received(Account account, Jid room_jid, Jid from_jid, string? password, string? reason) {
        string display_name = Util.get_display_name(stream_interactor, from_jid, account);
        string display_room = room_jid.bare_jid.to_string();
        Notification notification = new Notification(_("Invitation to %s").printf(display_room));
        string body = _("%s invited you to %s").printf(display_name, display_room);
        notification.set_body(body);

        Cairo.ImageSurface jid_avatar = yield (new AvatarGenerator(40, 40)).draw_jid(stream_interactor, from_jid, account);
        notification.set_icon(get_pixbuf_icon(jid_avatar));

        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
        notification.set_default_action_and_target_value("app.open-muc-join", new Variant.int32(conversation.id));
        notification.add_button_with_target_value(_("Deny"), "app.deny-invite", conversation.id);
        notification.add_button_with_target_value(_("Accept"), "app.open-muc-join", conversation.id);
        window.get_application().send_notification(null, notification);
    }

    private Icon get_pixbuf_icon(Cairo.ImageSurface surface) throws Error {
        Gdk.Pixbuf avatar = Gdk.pixbuf_get_from_surface(surface, 0, 0, surface.get_width(), surface.get_height());
        uint8[] buffer;
        avatar.save_to_buffer(out buffer, "png");
        return new BytesIcon(new Bytes(buffer));
    }
}

}
