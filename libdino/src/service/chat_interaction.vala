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

    public static void start(StreamInteractor stream_interactor) {
        ChatInteraction m = new ChatInteraction(stream_interactor);
        stream_interactor.add_module(m);
    }

    private ChatInteraction(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        Timeout.add_seconds(30, update_interactions);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(on_message_sent);
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
        on_conversation_focused(conversation);
    }

    private void on_message_sent(Entities.Message message, Conversation conversation) {
        last_input_interaction.unset(conversation);
        last_interface_interaction.unset(conversation);
        conversation.read_up_to = message;
    }

    private void on_conversation_focused(Conversation? conversation) {
        focus_in = true;
        if (conversation == null) return;
        focused_in(selected_conversation);
        check_send_read();
        selected_conversation.read_up_to = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
    }

    private void on_conversation_unfocused(Conversation? conversation) {
        focus_in = false;
        if (conversation == null) return;
        focused_out(selected_conversation);
        if (last_input_interaction.has_key(conversation)) {
            send_chat_state_notification(conversation, Xep.ChatStateNotifications.STATE_PAUSED);
            last_input_interaction.unset(conversation);
        }
    }

    private void check_send_read() {
        if (selected_conversation == null || selected_conversation.type_ == Conversation.Type.GROUPCHAT) return;
        Entities.Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(selected_conversation);
        if (message != null && message.direction == Entities.Message.DIRECTION_RECEIVED &&
                message.stanza != null && !message.equals(selected_conversation.read_up_to)) {
            selected_conversation.read_up_to = message;
            send_chat_marker(selected_conversation, message, Xep.ChatMarkers.MARKER_DISPLAYED);
        }
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

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (Xep.MessageArchiveManagement.MessageFlag.get_flag(message.stanza) != null) return;

        send_delivery_receipt(conversation, message);
        if (is_active_focus(conversation)) {
            check_send_read();
            conversation.read_up_to = message;
            send_chat_marker(conversation, message, Xep.ChatMarkers.MARKER_DISPLAYED);
        } else {
            send_chat_marker(conversation, message, Xep.ChatMarkers.MARKER_RECEIVED);
        }
    }

    private void send_chat_marker(Conversation conversation, Entities.Message message, string marker) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream != null &&
                (marker == Xep.ChatMarkers.MARKER_RECEIVED || conversation.get_send_marker_setting() == Conversation.Setting.ON) &&
                Xep.ChatMarkers.Module.requests_marking(message.stanza)) {
            stream.get_module(Xep.ChatMarkers.Module.IDENTITY).send_marker(stream, message.stanza.from, message.stanza_id, message.get_type_string(), marker);
        }
    }

    private void send_delivery_receipt(Conversation conversation, Entities.Message message) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream != null && Xep.MessageDeliveryReceipts.Module.requests_receipt(message.stanza)) {
            stream.get_module(Xep.MessageDeliveryReceipts.Module.IDENTITY).send_received(stream, message.from, message.stanza_id);
        }
    }

    private void send_chat_state_notification(Conversation conversation, string state) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        if (stream != null && conversation.get_send_typing_setting() == Conversation.Setting.ON &&
                conversation.type_ != Conversation.Type.GROUPCHAT) {
            stream.get_module(Xep.ChatStateNotifications.Module.IDENTITY).send_state(stream, conversation.counterpart, state);
        }
    }
}

}
