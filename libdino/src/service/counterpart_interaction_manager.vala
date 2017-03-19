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
    private HashMap<Jid, Entities.Message> last_read = new HashMap<Jid, Entities.Message>(Jid.hash_bare_func, Jid.equals_bare_func);
    private HashMap<Jid, string> chat_states = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

    public static void start(StreamInteractor stream_interactor) {
        CounterpartInteractionManager m = new CounterpartInteractionManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private CounterpartInteractionManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageManager.IDENTITY).message_received.connect(on_message_received);
    }

    public string? get_chat_state(Account account, Jid jid) {
        return chat_states[jid];
    }

    public Entities.Message? get_last_read(Account account, Jid jid) {
        return last_read[jid];
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.ChatMarkers.Module.IDENTITY).marker_received.connect( (stream, jid, marker, id) => {
            on_chat_marker_received(account, new Jid(jid), marker, id);
        });
        stream_interactor.module_manager.get_module(account, Xep.MessageDeliveryReceipts.Module.IDENTITY).receipt_received.connect((stream, jid, id) => {
            on_receipt_received(account, new Jid(jid), id);
        });
        stream_interactor.module_manager.get_module(account, Xep.ChatStateNotifications.Module.IDENTITY).chat_state_received.connect((stream, jid, state) => {
            on_chat_state_received(account, new Jid(jid), state);
        });
    }

    private void on_chat_state_received(Account account, Jid jid, string state) {
        chat_states[jid] = state;
        received_state(account, jid, state);
    }

    private void on_chat_marker_received(Account account, Jid jid, string marker, string stanza_id) {
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account);
        if (conversation != null) {
            Gee.List<Entities.Message>? messages = stream_interactor.get_module(MessageManager.IDENTITY).get_messages(conversation);
            if (messages != null) { // TODO not here
                foreach (Entities.Message message in messages) {
                    if (message.stanza_id == stanza_id) {
                        switch (marker) {
                            case Xep.ChatMarkers.MARKER_RECEIVED:
                                received_message_received(account, jid, message);
                                message.marked = Entities.Message.Marked.RECEIVED;
                                break;
                            case Xep.ChatMarkers.MARKER_DISPLAYED:
                                last_read[jid] = message;
                                received_message_displayed(account, jid, message);
                                foreach (Entities.Message m in messages) {
                                    if (m.equals(message)) break;
                                    if (m.marked == Entities.Message.Marked.RECEIVED) m.marked = Entities.Message.Marked.READ;
                                }
                                message.marked = Entities.Message.Marked.READ;
                                break;
                        }
                    }
                }
            }
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