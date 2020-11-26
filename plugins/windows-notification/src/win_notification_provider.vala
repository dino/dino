using Dino;
using Dino.Entities;
using DinoWinToast;
using Xmpp;
using Gee;

namespace Dino.Plugins.WindowsNotification {
    public class WindowsNotificationProvider : NotificationProvider, Object {

        // TODO:
        // 1. Actions
        // 2. Dismissed

        private StreamInteractor stream_interactor;
        private Dino.Application app;

        private WindowsNotificationProvider(Dino.Application app) {
            this.stream_interactor = app.stream_interactor;
            this.app = app;
        }

        public static WindowsNotificationProvider? try_create(Dino.Application app) {
            var valid = Init() == 0;
            if (valid) {
                return new WindowsNotificationProvider(app);
            }
            warning("Unable to initialize Windows notification provider");
            return null;
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
            
            var callbacks = new Callbacks();
            callbacks.activated = () => {
                app.activate_action("open-conversation", conversation.id);
            };

            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("accept-subscription", conversation.id);
                } else if (index == 1) {
                    app.activate_action("deny-subscription", conversation.id);
                }
            };

            if (!ShowMessage(template, callbacks) == 0) {
                warning("Failed showing subscription request notification");
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
    
            if (!show_message(summary, body, null, null)) {
                warning("Failed showing connection error notification");
            }
        }

        public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name) {
            Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);
    
            string display_room = room_jid.bare_jid.to_string();
            string summary = _("Invitation to %s").printf(display_room);
            string body = _("%s invited you to %s").printf(inviter_display_name, display_room);

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
            
            Conversation group_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            var callbacks = new Callbacks();
            callbacks.activated = () => {
                app.activate_action("open-muc-join", group_conversation.id);
            };

            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("deny-invite", group_conversation.id);
                } else if (index == 1) {
                    app.activate_action("open-muc-join", group_conversation.id);
                }
            };

            if (!ShowMessage(template, callbacks)) {
                warning("Failed showing muc invite notification");
            }
    
            //  try {
            //      uint32 notification_id = dbus_notifications.notify("Dino", 0, "", summary, body, actions, hash_table, 0);
    
            //      Conversation group_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            //      add_action_listener(notification_id, "default", () => {
            //          GLib.Application.get_default().activate_action("open-muc-join", new Variant.int32(group_conversation.id));
            //      });
            //      add_action_listener(notification_id, "accept", () => {
            //          GLib.Application.get_default().activate_action("deny-invite", new Variant.int32(group_conversation.id));
            //      });
            //      add_action_listener(notification_id, "deny", () => {
            //          GLib.Application.get_default().activate_action("open-muc-join", new Variant.int32(group_conversation.id));
            //      });
            //  } catch (Error e) {
                
            //  }
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
            
            var callbacks = new Callbacks();
            callbacks.activatedWithIndex = (index) => {
                if (index == 0) {
                    app.activate_action("deny-invite", conversation.id);
                } else if (index == 1) {
                    app.activate_action("open-muc-join", conversation.id);
                }
            };

            if (!ShowMessage(template, callbacks) == 0) {
                warning("Failed showing voice request notification");
            }
        }
    
        public async void retract_content_item_notifications() {
            //  if (content_notifications != null) {
            //      foreach (uint32 id in content_notifications.values) {
            //          try {
            //              dbus_notifications.close_notification(id);
            //          } catch (Error e) { }
            //      }
            //      content_notifications.clear();
            //  }
        }
    
        public async void retract_conversation_notifications(Conversation conversation) {
            //  if (content_notifications.has_key(conversation)) {
            //      try {
            //          dbus_notifications.close_notification(content_notifications[conversation]);
            //      } catch (Error e) { }
            //  }
            //  content_notifications.unset(conversation);
        }

        private bool show_message(string sender, string message, string? image_path, Callbacks? callbacks = null) {
            DinoWinToastTemplate template;
            if (image_path != null) {
                template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                template.setImagePath(image_path);
            } else {
                template = new DinoWinToastTemplate(TemplateType.Text02);
            }
            
            template.setTextField(sender, TextField.FirstLine);
            template.setTextField(message, TextField.SecondLine);
            if (callbacks != null) {
                return ShowMessage(template, callbacks) == 0;
            }
            return ShowMessage(template, new Callbacks()) == 0;
        }

        private async void notify_content_item(Conversation conversation, string conversation_display_name, string? participant_display_name, string body_) {
            string body = body_;
            if (participant_display_name != null) {
                body = @"$participant_display_name: $body";
            }

            var avatar = get_avatar(conversation);
            var callbacks = new Callbacks();
            callbacks.activated = () => app.activate_action("open-conversation", conversation.id);
            if (!show_message(conversation_display_name, body, avatar, callbacks)) {
                warning("Failed showing content item notification");
            }
        }

        private string? get_avatar(Conversation conversation) {
            var avatar_manager = app.stream_interactor.get_module(AvatarManager.IDENTITY);
            return avatar_manager.get_avatar_filepath(conversation.account, conversation.counterpart);
        }
    }
}