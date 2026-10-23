using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class ChatInteraction : StreamInteractionModule, Object {
    public static ModuleIdentity<ChatInteraction> IDENTITY = new ModuleIdentity<ChatInteraction>("chat_interaction");
    public string id { get { return IDENTITY.id; } }

    public signal void focused_in(Conversation conversation);
    public signal void focused_out(Conversation conversation);

    private StreamInteractor stream_interactor;
    private Conversation? selected_conversation;

    private HashMap<Conversation, DateTime> last_input_interaction = new HashMap<Conversation, DateTime>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Conversation, DateTime> last_interface_interaction = new HashMap<Conversation, DateTime>(Conversation.hash_func, Conversation.equals_func);
    private bool focus_in = false;
    private bool scrolled_down = true;

    public static void start(StreamInteractor stream_interactor) {
        ChatInteraction m = new ChatInteraction(stream_interactor);
        stream_interactor.add_module(m);
    }

    private ChatInteraction(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        Timeout.add_seconds(30, update_interactions);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(stream_interactor));
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(on_message_sent);
        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(new_item);
    }

    public int get_num_unread(Conversation conversation) {
        Database db = Dino.Application.get_default().db;

        Qlite.QueryBuilder query = db.content_item.select()
                .with(db.content_item.conversation_id, "=", conversation.id)
                .with(db.content_item.hide, "=", false);

        ContentItem? read_up_to_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, conversation.read_up_to_item);
        if (read_up_to_item != null) {
            string time = read_up_to_item.time.to_unix().to_string();
            string id = read_up_to_item.id.to_string();
            query.where(@"time > ? OR (time = ? AND id > ?)", { time, time, id });
        }
        // If it's a new conversation with read_up_to_item == null, all items are new.

        return (int) query.count();
    }

    public bool is_active_focus(Conversation? conversation = null) {
        if (conversation != null) {
            return focus_in && conversation.equals(this.selected_conversation);
        } else {
            return focus_in;
        }
    }

    public void on_window_focus_in(Conversation? conversation) {
        on_conversation_focused(conversation);
    }

    public void on_window_focus_out(Conversation? conversation) {
        on_conversation_unfocused(conversation);
    }

    public void on_scrolled_down_changed(bool scrolled_down, Conversation? conversation) {
        if (scrolled_down == this.scrolled_down) return;
        this.scrolled_down = scrolled_down;
        if (this.scrolled_down && focus_in && selected_conversation == conversation) {
            mark_latest_message_displayed();
        }
    }

    public void on_message_entered(Conversation? conversation) {
        if (!last_input_interaction.has_key(conversation)) {
            send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_COMPOSING);
        }
        last_input_interaction[conversation] = new DateTime.now_utc();
        last_interface_interaction[conversation] = new DateTime.now_utc();
    }

    public void on_message_cleared(Conversation? conversation) {
        if (last_input_interaction.has_key(conversation)) {
            last_input_interaction.unset(conversation);
            send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_ACTIVE);
        }
    }

    public void on_conversation_selected(Conversation conversation) {
        on_conversation_unfocused(selected_conversation);
        selected_conversation = conversation;
        scrolled_down = false;
        on_conversation_focused(conversation);
    }

    private void new_item(ContentItem item, Conversation conversation) {
        bool mark_read = is_active_focus(conversation) && scrolled_down;

        if (!mark_read) {
            MessageItem? message_item = item as MessageItem;
            if (message_item != null && message_item.message.direction == Message.DIRECTION_SENT) {
                mark_read = true;
            }
            if (message_item == null) {
                FileItem? file_item = item as FileItem;
                if (file_item != null && file_item.file_transfer.direction == FileTransfer.DIRECTION_SENT) {
                    mark_read = true;
                }
            }
        }
        if (mark_read) {
            ContentItem? read_up_to = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, conversation.read_up_to_item);
            if (read_up_to != null) {
                if (read_up_to.compare(item) < 0) {
                    conversation.read_up_to_item = item.id;
                }
            } else {
                conversation.read_up_to_item = item.id;
            }
        }
    }

    private void on_message_sent(Entities.Message message, Conversation conversation) {
        last_input_interaction.unset(conversation);
        last_interface_interaction.unset(conversation);
    }

    private void on_conversation_focused(Conversation? conversation) {
        focus_in = true;
        if (conversation == null) return;
        focused_in(conversation);

        if (scrolled_down) mark_latest_message_displayed();
    }

    private void on_conversation_unfocused(Conversation? conversation) {
        focus_in = false;
        if (conversation == null) return;
        focused_out(conversation);
        if (last_input_interaction.has_key(conversation)) {
            send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_PAUSED);
            last_input_interaction.unset(conversation);
        }
    }

    private async bool mark_latest_message_displayed() {
        Conversation conversation = selected_conversation;
        if (conversation == null) return false;
        Entities.Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
        if (message == null || message.direction == Entities.Message.DIRECTION_SENT) return false;
        if (message.id == conversation.read_up_to_message_id) return false;

        bool sent_marker = yield send_and_mark_message_displayed(conversation, message);
        return sent_marker;
    }

    private bool update_interactions() {
        for (MapIterator<Conversation, DateTime> iter = last_input_interaction.map_iterator(); iter.has_next(); iter.next()) {
            if (!iter.valid && iter.has_next()) iter.next();
            Conversation conversation = iter.get_key();
            if (last_input_interaction.has_key(conversation) &&
                    (new DateTime.now_utc()).difference(last_input_interaction[conversation]) >= 15 *  TimeSpan.SECOND) {
                iter.unset();
                send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_PAUSED);
            }
        }
        for (MapIterator<Conversation, DateTime> iter = last_interface_interaction.map_iterator(); iter.has_next(); iter.next()) {
            if (!iter.valid && iter.has_next()) iter.next();
            Conversation conversation = iter.get_key();
            if (last_interface_interaction.has_key(conversation) &&
                    (new DateTime.now_utc()).difference(last_interface_interaction[conversation]) >= 1.5 *  TimeSpan.MINUTE) {
                iter.unset();
                send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_GONE);
            }
        }
        return true;
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "FILTER_EMPTY", "STORE_CONTENT_ITEM" };
        public override string action_group { get { return "OTHER_NODES"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (Xmpp.MessageArchiveManagement.MessageFlag.get_flag(stanza) != null) return false;

            ChatInteraction outer = stream_interactor.get_module(ChatInteraction.IDENTITY);
            outer.send_delivery_receipt(message, stanza, conversation);

            // Send chat marker
            if (message.direction == Entities.Message.DIRECTION_SENT) return false;
            if (outer.is_active_focus(conversation) && outer.scrolled_down) {
                yield outer.send_and_mark_message_displayed(conversation, message);
            } else {
                outer.send_received_marker(message, stanza, conversation);
            }
            return false;
        }
    }

    public async bool send_and_mark_message_displayed(Conversation conversation, Entities.Message message) {
        stream_interactor.get_module(CounterpartInteractionManager.IDENTITY).mark_displayed_up_to_message(conversation, message);
        bool sent_marker = send_displayed_marker(message, conversation);
        if (!sent_marker) {
            sent_marker = yield send_message_displayed_sync(message, conversation);
        }
        return sent_marker;
    }

    private bool send_received_marker(Entities.Message message, Xmpp.MessageStanza? stanza, Conversation conversation) {
        if (stanza == null) return false;
        if (!Xep.ChatMarkers.Module.requests_marking(stanza)) return false;
        if (message.type_ == Message.Type.GROUPCHAT) return false;
        if (message.stanza_id == null) return false;
        if (message.direction == Entities.Message.DIRECTION_SENT) return false;
        if (message.id == conversation.read_up_to_message_id) return false;
        if (conversation.get_send_marker_setting(stream_interactor) != Conversation.Setting.ON) return false;

        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;

        stream.get_module(Xep.ChatMarkers.Module.IDENTITY).send_marker(stream, message.from, message.stanza_id, message.get_type_string(), Xep.ChatMarkers.MARKER_RECEIVED);
        return true;
    }

    private bool send_displayed_marker(Entities.Message message, Conversation conversation) {
        if (message.direction == Entities.Message.DIRECTION_SENT) return false;
        if (conversation.get_send_marker_setting(stream_interactor) != Conversation.Setting.ON) return false;

        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;

        if (message.type_.is_muc_semantic() && message.server_id != null) {
            stream.get_module(Xep.ChatMarkers.Module.IDENTITY).send_marker(stream, message.from.bare_jid, message.server_id, message.get_type_string(), Xep.ChatMarkers.MARKER_DISPLAYED);
            return true;
        } else if (!message.type_.is_muc_semantic() && message.stanza_id != null) {
            stream.get_module(Xep.ChatMarkers.Module.IDENTITY).send_marker(stream, message.from, message.stanza_id, message.get_type_string(), Xep.ChatMarkers.MARKER_DISPLAYED);
            return true;
        }

        return false;
    }

    private async bool send_message_displayed_sync(Entities.Message message, Conversation conversation) {
        if (message.direction == Entities.Message.DIRECTION_SENT) return false;
        if (message.server_id == null) return false;

        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;

        Jid server_id_jid = conversation.type_ == Conversation.Type.GROUPCHAT ? conversation.counterpart : conversation.account.bare_jid;
        return yield stream.get_module(Xep.MessageDisplayedSynchronization.Module.IDENTITY).update_message_displayed(stream, conversation.counterpart, server_id_jid, message.server_id);
    }

    private void send_delivery_receipt(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        if (message.direction == Entities.Message.DIRECTION_SENT) return;
        if (!Xep.MessageDeliveryReceipts.Module.requests_receipt(stanza)) return;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) return;

        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream != null) {
            stream.get_module(Xep.MessageDeliveryReceipts.Module.IDENTITY).send_received(stream, message.from, message.stanza_id);
        }
    }

    private void send_chat_state_notification(Conversation conversation, string state) {
        if (conversation.get_send_typing_setting(stream_interactor) != Conversation.Setting.ON) return;

        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream != null) {
            string message_type = conversation.type_ == Conversation.Type.GROUPCHAT ? Xmpp.MessageStanza.TYPE_GROUPCHAT : Xmpp.MessageStanza.TYPE_CHAT;
            stream.get_module(Xep.ChatStateNotifications.Module.IDENTITY).send_state(stream, conversation.counterpart, message_type, state);
        }
    }
}

}
