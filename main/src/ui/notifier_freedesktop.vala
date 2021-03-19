using Gee;

using Dino.Entities;
using Xmpp;

public class Dino.Ui.FreeDesktopNotifier : NotificationProvider, Object {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private DBusNotifications dbus_notifications;
    private bool supports_body_markup = false;

    private HashMap<Conversation, uint32> content_notifications = new HashMap<Conversation, uint32>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Conversation, Gee.List<uint32>> conversation_notifications = new HashMap<Conversation, Gee.List<uint32>>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<uint32, HashMap<string, ListenerFuncWrapper>> action_listeners = new HashMap<uint32, HashMap<string, ListenerFuncWrapper>>();
    private HashMap<Call, uint32> call_notifications = new HashMap<Call, uint32>(Call.hash_func, Call.equals_func);

    private FreeDesktopNotifier(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

    }

    private void set_dbus_notifications(DBusNotifications dbus_notifications) throws Error {
        this.dbus_notifications = dbus_notifications;

        string[] caps;
        dbus_notifications.get_capabilities(out caps);
        foreach (string cap in caps) {
            switch (cap) {
                case "body-markup":
                    supports_body_markup = true;
                    break;
            }
        }

        dbus_notifications.action_invoked.connect((id, action) => {
            if (action_listeners.has_key(id) && action_listeners[id].has_key(action)) {
                action_listeners[id][action].func();
            }
        });

        dbus_notifications.notification_closed.connect((id) => {
            action_listeners.unset(id);
        });
    }

    public static FreeDesktopNotifier? try_create(StreamInteractor stream_interactor) {
        DBusNotifications? dbus_notifications = get_notifications_dbus();
        if (dbus_notifications == null) return null;

        try {
            FreeDesktopNotifier notifier = new FreeDesktopNotifier(stream_interactor);
            notifier.set_dbus_notifications(dbus_notifications);
            return notifier;
        } catch (Error e) {
            debug("Failed accessing fdo notification server: %s", e.message);
        }

        return null;
    }

    public double get_priority() {
        return 1;
    }

    public async void notify_message(Message message, Conversation conversation, string conversation_display_name, string? participant_display_name) {
        string body = supports_body_markup ? Markup.escape_text(message.body) : message.body;
        yield notify_content_item(conversation, conversation_display_name, participant_display_name, body);
    }

    public async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name) {
        string text = "";
        if (file_transfer.direction == Message.DIRECTION_SENT) {
            text = is_image ? _("Image sent") : _("File sent");
        } else {
            text = is_image ? _("Image received") : _("File received");
        }

        if (supports_body_markup) {
            text = "<i>" + text + "</i>";
        }

        yield notify_content_item(conversation, conversation_display_name, participant_display_name, text);
    }

    private async void notify_content_item(Conversation conversation, string conversation_display_name, string? participant_display_name, string body_) {
        string body = body_;
        if (participant_display_name != null) {
            if (supports_body_markup) {
                body = @"<b>$(Markup.escape_text(participant_display_name)):</b> $body";
            } else {
                body = @"$participant_display_name: $body";
            }
        }

        uint32 replace_id = content_notifications.has_key(conversation) ? content_notifications[conversation] : 0;
        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        hash_table["image-data"] = yield get_conversation_icon(conversation);
        string[] actions = new string[] {"default", "Open conversation"};
        try {
            uint32 notification_id = dbus_notifications.notify("Dino", replace_id, "", conversation_display_name, body, actions, hash_table, 0);
            content_notifications[conversation] = notification_id;

            add_action_listener(notification_id, "default", () => {
                GLib.Application.get_default().activate_action("open-conversation", new Variant.int32(conversation.id));
            });
        } catch (Error e) {
            warning("Failed showing content item notification: %s", e.message);
        }
    }

    public async void notify_call(Call call, Conversation conversation, bool video, string conversation_display_name) {
        string summary = Markup.escape_text(conversation_display_name);
        string body =  video ? _("Incoming video call") : _("Incoming call");

        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        hash_table["image-path"] = "call-start-symbolic";
        hash_table["sound-name"] = new Variant.string("phone-incoming-call");
        hash_table["urgency"] = new Variant.byte(2);
        string[] actions = new string[] {"default", "Open conversation", "reject", _("Reject"), "accept", _("Accept")};
        try {
            uint32 notification_id = dbus_notifications.notify("Dino", 0, "", summary, body, actions, hash_table, 0);
            call_notifications[call] = notification_id;

            add_action_listener(notification_id, "default", () => {
                GLib.Application.get_default().activate_action("open-conversation", new Variant.int32(conversation.id));
            });
            add_action_listener(notification_id, "reject", () => {
                GLib.Application.get_default().activate_action("deny-call", new Variant.int32(call.id));
            });
            add_action_listener(notification_id, "accept", () => {
                GLib.Application.get_default().activate_action("accept-call", new Variant.int32(call.id));
            });
        } catch (Error e) {
            warning("Failed showing subscription request notification: %s", e.message);
        }
    }

    public async void retract_call_notification(Call call, Conversation conversation) {
        if (!call_notifications.has_key(call)) return;
        uint32 notification_id = call_notifications[call];
        try {
            dbus_notifications.close_notification(notification_id);
            action_listeners.unset(notification_id);
            call_notifications.unset(call);
        } catch (Error e) { }
    }

    public async void notify_subscription_request(Conversation conversation) {
        string summary = _("Subscription request");
        string body = Markup.escape_text(conversation.counterpart.to_string());

        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        hash_table["image-data"] = yield get_conversation_icon(conversation);
        string[] actions = new string[] {"default", "Open conversation", "accept", _("Accept"), "deny", _("Deny")};
        try {
            uint32 notification_id = dbus_notifications.notify("Dino", 0, "", summary, body, actions, hash_table, 0);

            if (!conversation_notifications.has_key(conversation)) {
                conversation_notifications[conversation] = new ArrayList<uint32>();
            }
            conversation_notifications[conversation].add(notification_id);

            add_action_listener(notification_id, "default", () => {
                GLib.Application.get_default().activate_action("open-conversation", new Variant.int32(conversation.id));
            });
            add_action_listener(notification_id, "accept", () => {
                GLib.Application.get_default().activate_action("accept-subscription", new Variant.int32(conversation.id));
            });
            add_action_listener(notification_id, "deny", () => {
                GLib.Application.get_default().activate_action("deny-subscription", new Variant.int32(conversation.id));
            });
        } catch (Error e) {
            warning("Failed showing subscription request notification: %s", e.message);
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
        }

        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        try {
            dbus_notifications.notify("Dino", 0, "im.dino.Dino", summary, body, new string[]{}, hash_table, 0);
        } catch (Error e) {
            warning("Failed showing connection error notification: %s", e.message);
        }
    }

    public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name) {
        Conversation direct_conversation = new Conversation(from_jid, account, Conversation.Type.CHAT);

        string display_room = room_jid.bare_jid.to_string();
        string summary = _("Invitation to %s").printf(display_room);
        string body = _("%s invited you to %s").printf(inviter_display_name, display_room);
        if (supports_body_markup) {
            body = Markup.escape_text(body);
        }

        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        hash_table["image-data"] = yield get_conversation_icon(direct_conversation);
        string[] actions = new string[] {"default", "", "reject", _("Reject"), "accept", _("Accept")};

        try {
            uint32 notification_id = dbus_notifications.notify("Dino", 0, "", summary, body, actions, hash_table, 0);

            Conversation group_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(room_jid, account, Conversation.Type.GROUPCHAT);
            add_action_listener(notification_id, "default", () => {
                GLib.Application.get_default().activate_action("open-muc-join", new Variant.int32(group_conversation.id));
            });
            add_action_listener(notification_id, "accept", () => {
                GLib.Application.get_default().activate_action("open-muc-join", new Variant.int32(group_conversation.id));
            });
            add_action_listener(notification_id, "deny", () => {
                GLib.Application.get_default().activate_action("deny-invite", new Variant.int32(group_conversation.id));
            });
        } catch (Error e) {
            warning("Failed showing muc invite notification: %s", e.message);
        }
    }

    public async void notify_voice_request(Conversation conversation, Jid from_jid) {

        string display_name = Util.get_participant_display_name(stream_interactor, conversation, from_jid);
        string display_room = Util.get_conversation_display_name(stream_interactor, conversation);
        string summary = _("Permission request");
        string body = _("%s requests the permission to write in %s").printf(display_name, display_room);
        if (supports_body_markup) {
            Markup.escape_text(body);
        }

        HashTable<string, Variant> hash_table = new HashTable<string, Variant>(null, null);
        hash_table["image-data"] = yield get_conversation_icon(conversation);
        string[] actions = new string[] {"deny", _("Deny"), "accept", _("Accept")};

        try {
            uint32 notification_id = dbus_notifications.notify("Dino", 0, "", summary, body, actions, hash_table, 0);

            add_action_listener(notification_id, "accept", () => {
                GLib.Application.get_default().activate_action("accept-voice-request", new Variant.int32(conversation.id));
            });
            add_action_listener(notification_id, "deny", () => {
                GLib.Application.get_default().activate_action("deny-voice-request", new Variant.int32(conversation.id));
            });
        } catch (Error e) {
            warning("Failed showing voice request notification: %s", e.message);
        }
    }

    public async void retract_content_item_notifications() {
        if (content_notifications != null) {
            foreach (uint32 id in content_notifications.values) {
                try {
                    dbus_notifications.close_notification(id);
                } catch (Error e) { }
            }
            content_notifications.clear();
        }
    }

    public async void retract_conversation_notifications(Conversation conversation) {
        if (content_notifications.has_key(conversation)) {
            try {
                dbus_notifications.close_notification(content_notifications[conversation]);
            } catch (Error e) { }
        }
        content_notifications.unset(conversation);
    }

    private async Variant get_conversation_icon(Conversation conversation) {
        AvatarDrawer drawer = yield Util.get_conversation_avatar_drawer(stream_interactor, conversation);
        Cairo.ImageSurface surface = drawer.size(40, 40).draw_image_surface();
        Gdk.Pixbuf avatar = Gdk.pixbuf_get_from_surface(surface, 0, 0, surface.get_width(), surface.get_height());
        var bytes = avatar.pixel_bytes;
        var image_bytes = Variant.new_from_data<Bytes>(new VariantType("ay"), bytes.get_data(), true, bytes);
        return new Variant("(iiibii@ay)", avatar.width, avatar.height, avatar.rowstride, avatar.has_alpha, avatar.bits_per_sample, avatar.n_channels, image_bytes);
    }

    private void add_action_listener(uint32 id, string name, owned ListenerFunc func) {
        if (!action_listeners.has_key(id)) {
            action_listeners[id] = new HashMap<string, ListenerFuncWrapper>();
        }
        action_listeners[id][name] = new ListenerFuncWrapper((owned) func);
    }

    delegate void ListenerFunc();
    class ListenerFuncWrapper {
        public ListenerFunc func;

        public ListenerFuncWrapper(owned ListenerFunc func) {
            this.func = (owned) func;
        }
    }
}