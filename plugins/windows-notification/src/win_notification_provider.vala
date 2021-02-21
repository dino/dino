using Dino;
using Dino.Entities;
using DinoWinToast;
using Xmpp;
using Gee;

namespace Dino.Plugins.WindowsNotification {
    public class WindowsNotificationProvider : NotificationProvider, Object {

        private StreamInteractor stream_interactor;
        private Dino.Application app;
        private Gee.List<int64?> marked_for_removal;
        private Gee.List<int64?> content_notifications;
        private HashMap<Conversation, Gee.List<int64?>> conversation_notifications;
        private bool supportsModernNotifications;

        private class Notification {
            public int64? id;
        }

        public WindowsNotificationProvider(Dino.Application app, bool supportsModernNotifications) {
            this.supportsModernNotifications = supportsModernNotifications;
            this.stream_interactor = app.stream_interactor;
            this.app = app;
            this.marked_for_removal = new Gee.ArrayList<int64?>();
            this.content_notifications = new Gee.ArrayList<int64?>();
            this.conversation_notifications = new HashMap<Conversation, Gee.List<int64?>>(Conversation.hash_func, Conversation.equals_func);
        }

        public double get_priority() {
            return 2;
        }

        public async void notify_message(Message message, Conversation conversation, string conversation_display_name, string? participant_display_name) {
            yield notify_content_item(conversation, conversation_display_name, participant_display_name, message.body);
        }

        public async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name) {
            string text = "";
            if (file_transfer.direction == Message.DIRECTION_SENT) {
                text = is_image ? _("Image sent") : _("File sent");
            } else {
                text = is_image ? _("Image received") : _("File received");
            }
    
            yield notify_content_item(conversation, conversation_display_name, participant_display_name, text);
        }

        public async void notify_subscription_request(Conversation conversation) {
            string summary = _("Subscription request");
            string body = Markup.escape_text(conversation.counterpart.to_string());

            DinoWinToastTemplate template;
            var image_path = get_avatar(conversation);
            if (image_path != null) {
                template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                template.setImagePath(image_path);
            } else {
                template = new DinoWinToastTemplate(TemplateType.Text02);
            }
            
            template.setTextField(summary, TextField.FirstLine);
            template.setTextField(body, TextField.SecondLine);

            template.addAction(_("Accept"));
            template.addAction(_("Deny"));

            var notification = new Notification();            
            var callbacks = new Callbacks();
            callbacks.activated = () => {
                app.activate_action("open-conversation", conversation.id);
                mark_for_removal(notification.id);
            };

            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("accept-subscription", conversation.id);
                } else if (index == 1) {
                    app.activate_action("deny-subscription", conversation.id);
                }
                mark_for_removal(notification.id);
            };

            callbacks.dismissed = (reason) => mark_for_removal(notification.id);
            callbacks.failed = () => mark_for_removal(notification.id);

            notification.id = ShowMessage(template, callbacks);
            if (notification.id == -1) {
                warning("Failed showing subscription request notification");
            } else {
                if (!conversation_notifications.has_key(conversation)) {
                    conversation_notifications[conversation] = new ArrayList<int64?>();
                }
                conversation_notifications[conversation].add(notification.id);
            }
        }

        public async void notify_connection_error(Account account, ConnectionManager.ConnectionError error) {
            string summary = _("Could not connect to %s").printf(account.bare_jid.domainpart);
            string body = "";
            switch (error.source) {
                case ConnectionManager.ConnectionError.Source.SASL:
                    body = _("Wrong password");
                    break;
                case ConnectionManager.ConnectionError.Source.TLS:
                    body = _("Invalid TLS certificate");
                    break;
                case ConnectionManager.ConnectionError.Source.STREAM_ERROR:
                    body = "Stream Error";
                    break;
                case ConnectionManager.ConnectionError.Source.CONNECTION:
                    body = "Connection";
                    break;
            }
            
            var notification = new Notification();
            var callbacks = new Callbacks();
            callbacks.activated = () => mark_for_removal(notification.id);
            callbacks.activatedWithIndex = (index) => mark_for_removal(notification.id);
            callbacks.dismissed = (reason) => mark_for_removal(notification.id);
            callbacks.failed = () => mark_for_removal(notification.id);

            DinoWinToastTemplate template = new DinoWinToastTemplate(TemplateType.Text02);
            template.setTextField(summary, TextField.FirstLine);
            template.setTextField(body, TextField.SecondLine);

            notification.id = ShowMessage(template, callbacks);
            if (notification.id == -1) {
                warning("Failed showing connection error notification");
            }
        }

        public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name) {
            Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);
    
            string display_room = room_jid.bare_jid.to_string();
            string summary = _("Invitation to %s").printf(display_room);
            string body = _("%s invited you to %s").printf(inviter_display_name, display_room);

            DinoWinToastTemplate template;
            var image_path = get_avatar(direct_conversation);
            if (image_path != null) {
                template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                template.setImagePath(image_path);
            } else {
                template = new DinoWinToastTemplate(TemplateType.Text02);
            }
            
            template.setTextField(summary, TextField.FirstLine);
            template.setTextField(body, TextField.SecondLine);

            template.addAction(_("Accept"));
            template.addAction(_("Deny"));
            
            Conversation group_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            var notification = new Notification();
            var callbacks = new Callbacks();
            callbacks.activated = () => {
                app.activate_action("open-muc-join", group_conversation.id);
                mark_for_removal(notification.id);
            };

            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("open-muc-join", group_conversation.id);
                } else if (index == 1) {
                    app.activate_action("deny-invite", group_conversation.id);
                }
                mark_for_removal(notification.id);
            };

            callbacks.dismissed = (reason) => mark_for_removal(notification.id);
            callbacks.failed = () => mark_for_removal(notification.id);

            notification.id = ShowMessage(template, callbacks);
            if (notification.id == -1) {
                warning("Failed showing muc invite notification");
            }
        }

        public async void notify_voice_request(Conversation conversation, Jid from_jid) {
            string display_name = Dino.get_participant_display_name(stream_interactor, conversation, from_jid);
            string display_room = Dino.get_conversation_display_name(stream_interactor, conversation, _("%s from %s"));
            string summary = _("Permission request");
            string body = _("%s requests the permission to write in %s").printf(display_name, display_room);

            DinoWinToastTemplate template;
            var image_path = get_avatar(conversation);
            if (image_path != null) {
                template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                template.setImagePath(image_path);
            } else {
                template = new DinoWinToastTemplate(TemplateType.Text02);
            }
            
            template.setTextField(summary, TextField.FirstLine);
            template.setTextField(body, TextField.SecondLine);

            template.addAction(_("Accept"));
            template.addAction(_("Deny"));
            
            var notification = new Notification();
            var callbacks = new Callbacks();
            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("accept-voice-request", conversation.id);
                } else if (index == 1) {
                    app.activate_action("deny-voice-request", conversation.id);
                }
                mark_for_removal(notification.id);
            };

            callbacks.dismissed = (reason) => mark_for_removal(notification.id);
            callbacks.failed = () => mark_for_removal(notification.id);
            callbacks.activated = () => mark_for_removal(notification.id);

            notification.id = ShowMessage(template, callbacks);
            if (notification.id == -1) {
                warning("Failed showing voice request notification");
            }
        }
    
        public async void retract_content_item_notifications() {
            foreach (int64 id in content_notifications) {
                RemoveNotification(id);
            }
            content_notifications.clear();
        }
    
        public async void retract_conversation_notifications(Conversation conversation) {
            if (conversation_notifications.has_key(conversation)) {
                var conversation_items = conversation_notifications[conversation];
                foreach (int64 id in conversation_items) {
                    RemoveNotification(id);
                }
                conversation_items.clear();
            }
        }

        private async void notify_content_item(Conversation conversation, string conversation_display_name, string? participant_display_name, string body_) {
            clear_marked();

            string body = body_;
            if (participant_display_name != null) {
                body = @"$participant_display_name: $body";
            }

            var image_path = get_avatar(conversation);
            DinoWinToastTemplate template;
            if (image_path != null) {
                template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                template.setImagePath(image_path);
            } else {
                template = new DinoWinToastTemplate(TemplateType.Text02);
            }
            
            template.setTextField(conversation_display_name, TextField.FirstLine);
            template.setTextField(body, TextField.SecondLine);

            var notification = new Notification();
            var callbacks = new Callbacks();
            callbacks.activated = () => {
                app.activate_action("open-conversation", conversation.id);
                mark_for_removal(notification.id);
            };
            callbacks.dismissed = (reason) => mark_for_removal(notification.id);
            callbacks.failed = () => mark_for_removal(notification.id);
            callbacks.activatedWithIndex = (index) => mark_for_removal(notification.id);

            notification.id = ShowMessage(template, callbacks);
            if (notification.id == -1) {
                warning("Failed showing content item notification");
            } else {
                content_notifications.add(notification.id);
            }
        }

        private string? get_avatar(Conversation conversation) {
            var avatar_manager = app.stream_interactor.get_module(AvatarManager.IDENTITY);
            return avatar_manager.get_avatar_filepath(conversation.account, conversation.counterpart);
        }

        private void clear_marked() {
            foreach (var id in marked_for_removal) {
                RemoveNotification(id);
            }
            marked_for_removal.clear();
        }

        private void mark_for_removal(int64? id) {
            if (id != null && id != -1 && id != 1 && id != 0) {
                marked_for_removal.add(id);
            }
        }
    }
}