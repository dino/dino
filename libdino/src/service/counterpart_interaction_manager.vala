using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
public class CounterpartInteractionManager : StreamInteractionModule, Object {
    public static ModuleIdentity<CounterpartInteractionManager> IDENTITY = new ModuleIdentity<CounterpartInteractionManager>("counterpart_interaction_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void received_state(Conversation conversation, string state);
    public signal void received_marker(Account account, Jid jid, Entities.Message message, Entities.Message.Marked marker);
    public signal void received_message_received(Account account, Jid jid, Entities.Message message);
    public signal void received_message_displayed(Account account, Jid jid, Entities.Message message);

    private StreamInteractor stream_interactor;
    private HashMap<Conversation, HashMap<Jid, DateTime>> typing_since = new HashMap<Conversation, HashMap<Jid, DateTime>>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<string, string> marker_wo_message = new HashMap<string, string>();

    public static void start(StreamInteractor stream_interactor) {
        CounterpartInteractionManager m = new CounterpartInteractionManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private CounterpartInteractionManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect((message, conversation) => clear_chat_state(conversation, message.from));
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent_or_received.connect(check_if_got_marker);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => {
            foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_conversations(jid, account)) {
                clear_chat_state(conversation, jid);
            }
        });
        stream_interactor.stream_negotiated.connect((account) => clear_all_chat_states(account) );

        Timeout.add_seconds(60, () => {
            var one_min_ago = new DateTime.now_utc().add_seconds(-1);

            foreach (Conversation conversation in typing_since.keys) {
                ArrayList<Jid> to_remove = new ArrayList<Jid>();
                foreach (Jid jid in typing_since[conversation].keys) {
                    if (typing_since[conversation][jid].compare(one_min_ago) < 0) {
                        to_remove.add(jid);
                    }
                }
                foreach (Jid jid in to_remove) {
                    clear_chat_state(conversation, jid);
                }
            }
            return true;
        });
    }

    public Gee.List<Jid>? get_typing_jids(Conversation conversation) {
        if (stream_interactor.connection_manager.get_state(conversation.account) != ConnectionManager.ConnectionState.CONNECTED) return null;
        if (!typing_since.has_key(conversation) || typing_since[conversation].size == 0) return null;

        var jids = new ArrayList<Jid>();
        foreach (Jid jid in typing_since[conversation].keys) {
            jids.add(jid);
        }
        return jids;
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.ChatMarkers.Module.IDENTITY).marker_received.connect( (stream, jid, marker, id, message_stanza) => {
            on_chat_marker_received.begin(account, jid, marker, id, message_stanza);
        });
        stream_interactor.module_manager.get_module(account, Xep.MessageDeliveryReceipts.Module.IDENTITY).receipt_received.connect((stream, jid, id) => {
            on_receipt_received(account, jid, id);
        });
        stream_interactor.module_manager.get_module(account, Xep.ChatStateNotifications.Module.IDENTITY).chat_state_received.connect((stream, jid, state, stanza) => {
            on_chat_state_received.begin(account, jid, state, stanza);
        });
    }

    private void clear_chat_state(Conversation conversation, Jid jid) {
        if (!(typing_since.has_key(conversation) && typing_since[conversation].has_key(jid))) return;

        typing_since[conversation].unset(jid);
        received_state(conversation, Xmpp.Xep.ChatStateNotifications.STATE_ACTIVE);
    }

    private void clear_all_chat_states(Account account) {
        foreach (Conversation conversation in typing_since.keys) {
            if (conversation.account.equals(account)) {
                received_state(conversation, Xmpp.Xep.ChatStateNotifications.STATE_ACTIVE);
                typing_since[conversation].clear();
            }
        }
    }

    private async void on_chat_state_received(Account account, Jid jid, string state, MessageStanza stanza) {
        // Don't show our own (other devices) typing notification
        if (jid.equals_bare(account.bare_jid)) return;

        Message message = yield stream_interactor.get_module(MessageProcessor.IDENTITY).parse_message_stanza(account, stanza);
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
        if (conversation == null) return;

        // Don't show our own typing notification in MUCs
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Jid? own_muc_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(jid.bare_jid, account);
            if (own_muc_jid != null && own_muc_jid.equals(jid)) {
                return;
            }
        }

        if (!typing_since.has_key(conversation)) {
            typing_since[conversation] = new HashMap<Jid, DateTime>(Jid.hash_func, Jid.equals_func);
        }
        if (state == Xmpp.Xep.ChatStateNotifications.STATE_COMPOSING) {
            typing_since[conversation][jid] = new DateTime.now_utc();
            received_state(conversation, state);
        } else {
            clear_chat_state(conversation, jid);
        }
    }

    private async void on_chat_marker_received(Account account, Jid jid, string marker, string stanza_id, MessageStanza message_stanza) {
        Message message = yield stream_interactor.get_module(MessageProcessor.IDENTITY).parse_message_stanza(account, message_stanza);
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
        if (conversation == null) return;
        handle_chat_marker(conversation, jid, marker, stanza_id);
    }

    private void handle_chat_marker(Conversation conversation, Jid jid, string marker, string stanza_id) {
        // Check if the marker comes from ourselves (own jid or our jid in a MUC)
        bool own_marker = false;
        if (conversation.type_ == Conversation.Type.CHAT) {
            own_marker = conversation.account.bare_jid.to_string() == jid.bare_jid.to_string();
        } else {
            Jid? own_muc_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(jid.bare_jid, conversation.account);
            if (own_muc_jid != null && own_muc_jid.equals(jid)) {
                own_marker = true;
            }
        }

        if (own_marker) {
            // If we received a display marker from ourselves (other device), set the conversation read up to that message.
            if (marker != Xep.ChatMarkers.MARKER_DISPLAYED && marker != Xep.ChatMarkers.MARKER_ACKNOWLEDGED) return;
            Entities.Message? message = null;
            if (conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
                message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_server_id(stanza_id, conversation);
            } else {
                message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_stanza_id(stanza_id, conversation);
            }
            if (message == null) return;
            // Don't move read marker backwards because we get old info from another client
            if (conversation.read_up_to != null && conversation.read_up_to.local_time.compare(message.local_time) > 0) return;
            conversation.read_up_to = message;

            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);
            ContentItem? read_up_to_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, conversation.read_up_to_item);
            if (read_up_to_item != null && read_up_to_item.compare(content_item) > 0) return;
            conversation.read_up_to_item = content_item.id;
        } else {
            // We can't currently handle chat markers in MUCs
            if (conversation.type_ == Conversation.Type.GROUPCHAT) return;

            Entities.Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_stanza_id(stanza_id, conversation);
            if (message != null) {
                switch (marker) {
                    case Xep.ChatMarkers.MARKER_RECEIVED:
                        // If we got a received marker, mark the respective message received.
                        received_message_received(conversation.account, jid, message);
                        message.marked = Entities.Message.Marked.RECEIVED;
                        break;
                    case Xep.ChatMarkers.MARKER_DISPLAYED:
                        // If we got a display marker, set all messages up to that message as read (if we know they've been received).
                        received_message_displayed(conversation.account, jid, message);
                        Gee.List<Entities.Message> messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation);
                        foreach (Entities.Message m in messages) {
                            if (m.equals(message)) break;
                            if (m.marked == Entities.Message.Marked.RECEIVED) m.marked = Entities.Message.Marked.READ;
                        }
                        message.marked = Entities.Message.Marked.READ;
                        break;
                }
            } else {
                // We might get a marker before the actual message (on catchup). Save the marker.
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
            handle_chat_marker(conversation, conversation.counterpart, marker_wo_message[message.stanza_id], message.stanza_id);
            marker_wo_message.unset(message.stanza_id);
        }
    }

    private void on_receipt_received(Account account, Jid jid, string id) {
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account, Conversation.Type.CHAT);
        if (conversation == null) return;
        handle_chat_marker(conversation, jid,Xep.ChatMarkers.MARKER_RECEIVED, id);
    }
}

}
