using Dino;
using Dino.Entities;
using winrt.Windows.UI.Notifications;
using Xmpp;
using Gee;

namespace Dino.Plugins.WindowsNotification {
    public class WindowsNotificationProvider : NotificationProvider, Object {

        private delegate void DelegateToUi();

        private static uint notification_counter = 0;
        private ToastNotifier notifier;
        private StreamInteractor stream_interactor;
        private Dino.Application app;

        private Gee.List<uint?> marked_for_removal;
        
        // we must keep a reference to the notification itself or else their actions are disabled
        private HashMap<uint, ToastNotification> notifications;
        private Gee.List<uint?> content_notifications;
        private HashMap<Conversation, Gee.List<uint?>> conversation_notifications;

        public WindowsNotificationProvider(Dino.Application app, ToastNotifier notifier) {
            this.notifier = notifier;
            this.stream_interactor = app.stream_interactor;
            this.app = app;
            this.marked_for_removal = new Gee.ArrayList<uint?>();
            this.content_notifications = new Gee.ArrayList<uint?>();
            this.conversation_notifications = new HashMap<Conversation, Gee.List<uint?>>(Conversation.hash_func, Conversation.equals_func);
            this.notifications = new HashMap<uint, ToastNotification>();
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

            string? inlineImagePath = null;
            if (file_transfer.state == FileTransfer.State.COMPLETE) {
                inlineImagePath = file_transfer.get_file().get_path();
            }
    
            yield notify_content_item(conversation, conversation_display_name, participant_display_name, text, inlineImagePath);
        }

        public async void notify_subscription_request(Conversation conversation) {
            string summary = _("Subscription request");
            string body = Markup.escape_text(conversation.counterpart.to_string());

            var image_path = get_avatar(conversation);
            var notification = yield new ToastNotificationBuilder()
                .SetHeader(summary)
                .SetBody(body)
                .SetAppLogo(image_path)
                .AddButton(_("Accept"), "accept-subscription")
                .AddButton(_("Deny"), "deny-subscription")
                .Build();

            var notification_id = generate_id();
            notification.Activated((argument, user_input) => {
                run_on_ui(() => {
                    if (argument != null) {
                        app.activate_action(argument, conversation.id);
                    } else {
                        app.activate_action("open-conversation", conversation.id);
                    }
                });
    
                marked_for_removal.add(notification_id);
            });

            notification.Dismissed((reason) => marked_for_removal.add(notification_id));

            notification.Failed(() => marked_for_removal.add(notification_id));

            notifications[notification_id] = notification;

            if (!conversation_notifications.has_key(conversation)) {
                conversation_notifications[conversation] = new ArrayList<uint?>();
            }
            conversation_notifications[conversation].add(notification_id);
            
            notifier.Show(notification);
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

            var notification = yield new ToastNotificationBuilder()
                .SetHeader(summary)
                .SetBody(body)
                .Build();

            var notification_id = generate_id();
            notification.Activated((argument, user_input) => marked_for_removal.add(notification_id));
            notification.Dismissed((reason) =>  marked_for_removal.add(notification_id));
            notification.Failed(() => marked_for_removal.add(notification_id));

            notifications[notification_id] = notification;
            notifier.Show(notification);
        }

        public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name) {
            Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);
    
            string display_room = room_jid.bare_jid.to_string();
            string summary = _("Invitation to %s").printf(display_room);
            string body = _("%s invited you to %s").printf(inviter_display_name, display_room);

            var image_path = get_avatar(direct_conversation);
            var notification = yield new ToastNotificationBuilder()
                .SetHeader(summary)
                .SetBody(body)
                .SetAppLogo(image_path)
                .AddButton(_("Accept"), "open-muc-join")
                .AddButton(_("Deny"), "deny-invite")
                .Build();

            var notification_id = generate_id();
            var group_conversation_id = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT).id;
            notification.Activated((argument, user_input) => {
                run_on_ui(() => {
                    if (argument != null) {
                        app.activate_action(argument, group_conversation_id);
                    } else {
                        app.activate_action("open-muc-join", group_conversation_id);
                    }
                });

                marked_for_removal.add(notification_id);
            });

            notification.Dismissed((reason) => marked_for_removal.add(notification_id));

            notification.Failed(() => marked_for_removal.add(notification_id));

            notifications[notification_id] = notification;
            notifier.Show(notification);
        }

        public async void notify_voice_request(Conversation conversation, Jid from_jid) {
            string display_name = Dino.get_participant_display_name(stream_interactor, conversation, from_jid);
            string display_room = Dino.get_conversation_display_name(stream_interactor, conversation, _("%s from %s"));
            string summary = _("Permission request");
            string body = _("%s requests the permission to write in %s").printf(display_name, display_room);

            var image_path = get_avatar(conversation);
            var notification = yield new ToastNotificationBuilder()
                .SetHeader(summary)
                .SetBody(body)
                .SetAppLogo(image_path)
                .AddButton(_("Accept"), "accept-voice-request")
                .AddButton(_("Deny"), "deny-voice-request")
                .Build();

            var notification_id = generate_id();
            notification.Activated((argument, user_input) => {
                if (argument != null) {
                    run_on_ui(() => app.activate_action(argument, conversation.id));
                }

                marked_for_removal.add(notification_id);
            });

            notification.Dismissed((reason) => marked_for_removal.add(notification_id));

            notification.Failed(() => marked_for_removal.add(notification_id));

            notifications[notification_id] = notification;
            notifier.Show(notification);
        }

        private async void notify_content_item(Conversation conversation, string conversation_display_name, string? participant_display_name, string body_, string? inlineImagePath = null) {
            clear_marked();

            string body = body_;
            if (participant_display_name != null) {
                body = @"$participant_display_name: $body";
            }

            var image_path = get_avatar(conversation);
            var builder = new ToastNotificationBuilder()
                .SetHeader(conversation_display_name)
                .SetBody(body)
                .SetAppLogo(image_path);
            
            if (inlineImagePath != null) {
                builder.SetInlineImage(inlineImagePath);
            }

            var notification = yield builder.Build();

            var notification_id = generate_id();
            notification.Activated((argument, user_input) => {
                run_on_ui(() => app.activate_action("open-conversation", conversation.id));
                marked_for_removal.add(notification_id);
            });

            notification.Dismissed((reason) => marked_for_removal.add(notification_id));

            notification.Failed(() => marked_for_removal.add(notification_id));

            notifications[notification_id] = notification;
            notifier.Show(notification);

            content_notifications.add(notification_id);
        }

        private string? get_avatar(Conversation conversation) {
            var avatar_manager = app.stream_interactor.get_module(AvatarManager.IDENTITY);
            return avatar_manager.get_avatar_filepath(conversation.account, conversation.counterpart);
        }

        public async void retract_content_item_notifications() {
            foreach (uint id in content_notifications) {
                remove_notification(id);
            }
            content_notifications.clear();
        }
    
        public async void retract_conversation_notifications(Conversation conversation) {
            if (conversation_notifications.has_key(conversation)) {
                var conversation_items = conversation_notifications[conversation];
                foreach (uint id in conversation_items) {
                    remove_notification(id);
                }
                conversation_items.clear();
            }
        }

        private void clear_marked() {
            foreach (var id in marked_for_removal) {
                remove_notification(id);
            }
            marked_for_removal.clear();
        }

        private void remove_notification(uint id) {
            ToastNotification notification = null;
            notifications.unset(id, out notification);
            if (notification != null) {
                notifier.Hide(notification);
            }
        }

        private uint generate_id() {
            return AtomicUint.add(ref notification_counter, 1);
        }

        private void run_on_ui(DelegateToUi func) {
            Idle.add(() => { func(); return false; }, GLib.Priority.HIGH);
        }
    }
}