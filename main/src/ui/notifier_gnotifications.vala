using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

    public class GNotificationsNotifier : NotificationProvider, Object {

        public signal void conversation_selected(Conversation conversation);

        private StreamInteractor stream_interactor;
        private HashMap<Conversation, Notification> notifications = new HashMap<Conversation, Notification>(Conversation.hash_func, Conversation.equals_func);
        private Set<string>? active_conversation_ids = null;
        private Set<string>? active_ids = new HashSet<string>();

        public GNotificationsNotifier(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public double get_priority() {
            return 0;
        }

        public async void notify_message(Message message, Conversation conversation, string conversation_display_name, string? participant_display_name) {
            string text = message.body;
            if (participant_display_name != null) {
                text = @"$participant_display_name: $text";
            }
            yield notify_content_item(conversation, conversation_display_name, text);
        }

        public async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name) {
            string text = "";
            if (file_transfer.direction == Message.DIRECTION_SENT) {
                text = is_image ? _("Image sent") : _("File sent");
            } else {
                text = is_image ? _("Image received") : _("File received");
            }

            if (participant_display_name != null) {
                text = @"$participant_display_name: $text";
            }

            yield notify_content_item(conversation, conversation_display_name, text);
        }

        private async void notify_content_item(Conversation conversation, string title, string body) {
            if (!notifications.has_key(conversation)) {
                notifications[conversation] = new Notification("");
                notifications[conversation].set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
            }
            Notification notification = notifications[conversation];

            notification.set_title(title);
            notification.set_body(body);
            try {
                notification.set_icon(yield get_conversation_icon(conversation));
            } catch (Error e) { }

            GLib.Application.get_default().send_notification(conversation.id.to_string(), notifications[conversation]);

            if (active_conversation_ids != null) {
                active_conversation_ids.add(conversation.id.to_string());
            }
        }

        public async void notify_call(Call call, Conversation conversation, bool video, bool multiparty, string conversation_display_name) {
            Notification notification = new Notification(conversation_display_name);
            string body =  video ? _("Incoming video call") : _("Incoming call");
            if (multiparty) {
                body = video ? _("Incoming video group call") : _("Incoming group call");
            }
            notification.set_body(body);
            notification.set_urgent(true);

            notification.set_icon(new ThemedIcon.from_names(new string[] {"call-start-symbolic"}));

            notification.set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
            notification.add_button_with_target_value(_("Reject"), "app.reject-call", new Variant.int32(call.id));
            notification.add_button_with_target_value(_("Accept"), "app.accept-call", new Variant.int32(call.id));

            GLib.Application.get_default().send_notification(call.id.to_string(), notification);
        }

        private async void retract_call_notification(Call call, Conversation conversation) {
            GLib.Application.get_default().withdraw_notification(call.id.to_string());
        }

        public async void notify_subscription_request(Conversation conversation) {
            Notification notification = new Notification(_("Subscription request"));
            notification.set_body(conversation.counterpart.to_string());
            try {
                notification.set_icon(yield get_conversation_icon(conversation));
            } catch (Error e) { }
            notification.set_default_action_and_target_value("app.open-conversation", new Variant.int32(conversation.id));
            notification.add_button_with_target_value(_("Accept"), "app.accept-subscription", conversation.id);
            notification.add_button_with_target_value(_("Deny"), "app.deny-subscription", conversation.id);
            GLib.Application.get_default().send_notification(conversation.id.to_string() + "-subscription", notification);
            active_ids.add(conversation.id.to_string() + "-subscription");
        }

        public async void notify_connection_error(Account account, ConnectionManager.ConnectionError error) {
            Notification notification = new Notification(_("Could not connect to %s").printf(account.bare_jid.domainpart));
            switch (error.source) {
                case ConnectionManager.ConnectionError.Source.SASL:
                    notification.set_body("Wrong password");
                    break;
                case ConnectionManager.ConnectionError.Source.TLS:
                    notification.set_body("Invalid TLS certificate");
                    break;
                default:
                    break;
            }
            GLib.Application.get_default().send_notification(account.id.to_string() + "-connection-error", notification);
        }

        public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name) {
            Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);

            string display_room = room_jid.bare_jid.to_string();
            Notification notification = new Notification(_("Invitation to %s").printf(display_room));
            string body = _("%s invited you to %s").printf(inviter_display_name, display_room);
            notification.set_body(body);

            try {
                notification.set_icon(yield get_conversation_icon(direct_conversation));
            } catch (Error e) { }

            Conversation group_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            notification.set_default_action_and_target_value("app.open-muc-join", new Variant.int32(group_conversation.id));
            notification.add_button_with_target_value(_("Deny"), "app.deny-invite", group_conversation.id);
            notification.add_button_with_target_value(_("Accept"), "app.open-muc-join", group_conversation.id);
            GLib.Application.get_default().send_notification(null, notification);
        }

        public async void notify_voice_request(Conversation conversation, Jid from_jid) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, from_jid);
            string display_room = Util.get_conversation_display_name(stream_interactor, conversation);
            Notification notification = new Notification(_("Permission request"));
            string body = _("%s requests the permission to write in %s").printf(display_name, display_room);
            notification.set_body(body);

            try {
                notification.set_icon(yield get_conversation_icon(conversation));
            } catch (Error e) { }

            notification.add_button_with_target_value(_("Deny"), "app.deny-voice-request", conversation.id);
            notification.add_button_with_target_value(_("Accept"), "app.accept-voice-request", conversation.id);
            GLib.Application.get_default().send_notification(null, notification);
        }

        public async void retract_content_item_notifications() {
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
        }

        public async void retract_conversation_notifications(Conversation conversation) {
            string subscription_id = conversation.id.to_string() + "-subscription";
            if (active_ids.contains(subscription_id)) {
                GLib.Application.get_default().withdraw_notification(subscription_id);
            }
        }

        private async Icon get_conversation_icon(Conversation conversation) throws Error {
            CompatAvatarDrawer drawer = new CompatAvatarDrawer() {
                model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(conversation),
                width_request = 40,
                height_request = 40
            };
            Cairo.ImageSurface surface = drawer.draw_image_surface();
            Gdk.Pixbuf avatar = Gdk.pixbuf_get_from_surface(surface, 0, 0, surface.get_width(), surface.get_height());
            uint8[] buffer;
            avatar.save_to_buffer(out buffer, "png");
            return new BytesIcon(new Bytes(buffer));
        }
    }
}
