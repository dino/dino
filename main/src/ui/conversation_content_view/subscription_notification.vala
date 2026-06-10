using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class SubscriptionNotitication : Object {

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private ConversationView conversation_view;

    public SubscriptionNotitication(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(PresenceManager.IDENTITY).received_subscription_request.connect((jid, account) => {
            Conversation relevant_conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(relevant_conversation);
            if (conversation != null && account.equals(conversation.account) && jid.equals(conversation.counterpart)) {
                show_pending_subscription_request();
            }
        });
    }

    public void init(Conversation conversation, ConversationView conversation_view) {
        this.conversation = conversation;
        this.conversation_view = conversation_view;

        if (conversation.type_ != Conversation.Type.CHAT) return;

        if (stream_interactor.get_module(PresenceManager.IDENTITY).exists_subscription_request(conversation.account, conversation.counterpart)) {
            // Show a notification of a pending subscription request
            show_pending_subscription_request();
        } else if (!conversation.counterpart.equals_bare(conversation.account.bare_jid)) {
            // Show a suggestion to request subscription if: We don't have subscription yet and didn't yet request it
            // Don't show this notification for chats with ourselves
            var roster_item = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, conversation.counterpart);
            if (roster_item == null ||
                    (roster_item.subscription == Xmpp.Roster.Item.SUBSCRIPTION_NONE || roster_item.subscription == Xmpp.Roster.Item.SUBSCRIPTION_FROM) &&
                    !roster_item.subscription_requested) {
                show_no_subscription(roster_item != null);
            }
        }
    }

    private void show_no_subscription(bool already_in_roster) {
        Box box = new Box(Orientation.HORIZONTAL, 5);
        Button accept_button = new Button.with_label(_("Send request"));
        GLib.Application app = GLib.Application.get_default();
        accept_button.clicked.connect(() => {
            if (!already_in_roster) {
                stream_interactor.get_module(RosterManager.IDENTITY).add_jid(conversation.account, conversation.counterpart, null);
            }
            stream_interactor.get_module(PresenceManager.IDENTITY).request_subscription(conversation.account, conversation.counterpart);
            app.activate_action("accept-subscription", conversation.id);
            ((Dino.Ui.Application) app).window.conversation_view.chat_input.chat_text_view.text_view.grab_focus();
            conversation_view.remove_notification(box);
        });
        box.append(new Label(_("You do not receive status updates from this contact yet.")) { margin_end=10 });
        box.append(accept_button);
        conversation_view.add_notification(box);
    }

    private void show_pending_subscription_request() {
        Box box = new Box(Orientation.HORIZONTAL, 5);
        Button accept_button = new Button.with_label(_("Accept"));
        Button deny_button = new Button.with_label(_("Deny"));
        GLib.Application app = GLib.Application.get_default();
        accept_button.clicked.connect(() => {
            app.activate_action("accept-subscription", conversation.id);
            ((Dino.Ui.Application) app).window.conversation_view.chat_input.chat_text_view.text_view.grab_focus();
            conversation_view.remove_notification(box);
        });
        deny_button.clicked.connect(() => {
            app.activate_action("deny-subscription", conversation.id);
            ((Dino.Ui.Application) app).window.conversation_view.chat_input.chat_text_view.text_view.grab_focus();
            conversation_view.remove_notification(box);
        });
        box.append(new Label(_("This contact would like to add you to their contact list")) { margin_end=10 });
        box.append(accept_button);
        box.append(deny_button);
        conversation_view.add_notification(box);
    }
}

public class HistorySyncNotification : Object {

    private Conversation? conversation;
    private ConversationView? conversation_view;
    private Box? box;
    private Label? label;
    private HistorySync history_sync;

    public HistorySyncNotification(StreamInteractor stream_interactor) {
        history_sync = stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync;
        history_sync.conversation_resync_started.connect(on_resync_started);
        history_sync.conversation_resync_progress.connect(on_resync_progress);
        history_sync.conversation_resync_finished.connect(on_resync_finished);
    }

    public void init(Conversation conversation, ConversationView conversation_view) {
        close();
        this.conversation = conversation;
        this.conversation_view = conversation_view;

        Cancellable? active_cancellable;
        int messages;
        int total_messages;
        if (history_sync.get_conversation_resync_state(conversation, out active_cancellable, out messages, out total_messages) &&
                active_cancellable != null && !((!)active_cancellable).is_cancelled()) {
            on_resync_started(conversation, (!)active_cancellable);
            on_resync_progress(conversation, messages, total_messages);
        }
    }

    private void on_resync_started(Conversation conversation, Cancellable _cancellable) {
        ConversationView? view = conversation_view;
        if (!matches(conversation) || view == null) return;

        close();
        Box notification_box = new Box(Orientation.HORIZONTAL, 5);
        Label notification_label = new Label(_("Resyncing history (0 messages)")) { margin_end=10 };
        Button cancel_button = new Button.with_label(_("Cancel")) { can_focus=false };
        cancel_button.clicked.connect(() => {
            ConversationView? active_view = conversation_view;
            double value = active_view != null ? ((!)active_view).scrolled.vadjustment.value : 0;
            if (this.conversation != null) history_sync.cancel_conversation_resync((!)this.conversation);
            if (active_view != null) {
                Idle.add(() => {
                    Adjustment adjustment = ((!)active_view).scrolled.vadjustment;
                    double max_value = adjustment.upper - adjustment.page_size;
                    if (max_value < 0) max_value = 0;
                    double restored_value = value;
                    if (restored_value < 0) restored_value = 0;
                    if (restored_value > max_value) restored_value = max_value;
                    adjustment.value = restored_value;
                    return Source.REMOVE;
                });
            }
        });
        notification_box.append(notification_label);
        notification_box.append(cancel_button);
        box = notification_box;
        label = notification_label;
        view.add_notification(notification_box);
    }

    private void on_resync_progress(Conversation conversation, int messages, int total_messages) {
        Label? progress_label = label;
        if (!matches(conversation) || progress_label == null) return;

        if (total_messages > 0) {
            progress_label.label = _("Resyncing history (%i of %i messages)").printf(messages, total_messages);
        } else {
            progress_label.label = _("Resyncing history (%i messages)").printf(messages);
        }
    }

    private void on_resync_finished(Conversation conversation) {
        if (!matches(conversation)) return;

        close();
    }

    private bool matches(Conversation other) {
        return conversation != null && conversation.equals(other);
    }

    private void close() {
        Box? notification_box = box;
        ConversationView? view = conversation_view;
        if (notification_box != null && view != null) {
            view.remove_notification(notification_box);
        }
        box = null;
        label = null;
    }
}

}
