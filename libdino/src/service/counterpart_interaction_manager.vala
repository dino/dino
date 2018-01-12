using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class CounterpartInteractionManager : StreamInteractionModule, Object {
    public static ModuleIdentity<CounterpartInteractionManager> IDENTITY = new ModuleIdentity<CounterpartInteractionManager>("counterpart_interaction_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void received_state(Account account, Jid jid, string state);
    public signal void received_marker(Account account, Jid jid, Entities.Message message, string marker);
    public signal void received_message_received(Account account, Jid jid, Entities.Message message);
    public signal void received_message_displayed(Account account, Jid jid, Entities.Message message);

    private StreamInteractor stream_interactor;
    private HashMap<Jid, string> chat_states = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<string, string> marker_wo_message = new HashMap<string, string>();

    public static void start(StreamInteractor stream_interactor) {
        CounterpartInteractionManager m = new CounterpartInteractionManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private CounterpartInteractionManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(check_if_got_marker);
        stream_interactor.stream_negotiated.connect(() => chat_states.clear() );
    }

    public string? get_chat_state(Account account, Jid jid) {
        if (stream_interactor.connection_manager.get_state(account) != ConnectionManager.ConnectionState.CONNECTED) return null;
        return chat_states[jid];
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.ChatMarkers.Module.IDENTITY).marker_received.connect( (stream, jid, marker, id) => {
            on_chat_marker_received(account, jid, marker, id);
        });
        stream_interactor.module_manager.get_module(account, Xep.MessageDeliveryReceipts.Module.IDENTITY).receipt_received.connect((stream, jid, id) => {
            on_receipt_received(account, jid, id);
        });
        stream_interactor.module_manager.get_module(account, Xep.ChatStateNotifications.Module.IDENTITY).chat_state_received.connect((stream, jid, state) => {
            on_chat_state_received(account, jid, state);
        });
    }

    private void on_chat_state_received(Account account, Jid jid, string state) {
        chat_states[jid] = state;
        received_state(account, jid, state);
    }

    private void on_chat_marker_received(Account account, Jid jid, string marker, string stanza_id) {
        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_conversations(jid, account)) {
            Entities.Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(stanza_id, conversation);
            if (message != null) {
                switch (marker) {
                    case Xep.ChatMarkers.MARKER_RECEIVED:
                        received_message_received(account, jid, message);
                        message.marked = Entities.Message.Marked.RECEIVED;
                        break;
                    case Xep.ChatMarkers.MARKER_DISPLAYED:
                        received_message_displayed(account, jid, message);
                        Gee.List<Entities.Message> messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation);
                        foreach (Entities.Message m in messages) {
                            if (m.equals(message)) break;
                            if (m.marked == Entities.Message.Marked.RECEIVED) m.marked = Entities.Message.Marked.READ;
                        }
                        message.marked = Entities.Message.Marked.READ;
                        break;
                }
            } else {
                if (marker_wo_message.has_key(stanza_id) &&
                        marker_wo_message[stanza_id] == Xep.ChatMarkers.MARKER_DISPLAYED && marker == Xep.ChatMarkers.MARKER_RECEIVED) {
                    return;
                }
                marker_wo_message[stanza_id] = marker;
            }
        }
    }

    private void check_if_got_marker(Entities.Message message, Conversation conversation) {
        if (marker_wo_message.has_key(message.stanza_id)) {
            on_chat_marker_received(conversation.account, conversation.counterpart, marker_wo_message[message.stanza_id], message.stanza_id);
            marker_wo_message.unset(message.stanza_id);
        }
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        on_chat_state_received(conversation.account, conversation.counterpart, Xep.ChatStateNotifications.STATE_ACTIVE);
    }

    private void on_receipt_received(Account account, Jid jid, string id) {
        on_chat_marker_received(account, jid, Xep.ChatMarkers.MARKER_RECEIVED, id);
    }
}

}
