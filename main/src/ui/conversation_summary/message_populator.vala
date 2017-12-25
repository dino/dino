using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class MessagePopulator : Object {

    private StreamInteractor? stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;
    private HashMap<Plugins.MetaConversationItem, Message> meta_message = new HashMap<Plugins.MetaConversationItem, Message>();

    public MessagePopulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_message_display(new DefaultMessageDisplay(stream_interactor));
        app.plugin_registry.register_message_display(new SlashmeMessageDisplay(stream_interactor));


        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(handle_message);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(handle_message);
    }

    public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection) {
        current_conversation = conversation;
        this.item_collection = item_collection;
    }

    public void close(Conversation conversation) { }

    public void populate_latest(Conversation conversation, int n) {
        Gee.List<Entities.Message>? messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation, n);
        if (messages != null) {
            foreach (Entities.Message message in messages) {
                handle_message(message, conversation);
            }
        }
    }

    public void populate_before(Conversation conversation, Plugins.MetaConversationItem item, int n) {
        Gee.List<Entities.Message>? messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_before_message(conversation, meta_message[item], n);
        if (messages != null) {
            foreach (Entities.Message message in messages) {
                handle_message(message, conversation);
            }
        }
    }

    private void handle_message(Message message, Conversation conversation) {
        if (!conversation.equals(current_conversation)) return;

        Plugins.MessageDisplayProvider? best_provider = null;
        double priority = -1;
        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.MessageDisplayProvider provider in app.plugin_registry.message_displays) {
            if (provider.can_display(message) && provider.priority > priority) {
                best_provider = provider;
                priority = provider.priority;
            }
        }
        Plugins.MetaConversationItem? meta_item = best_provider.get_item(message, conversation);
        if (meta_item == null) return;
        meta_message[meta_item] = message;

        meta_item.mark = message.marked;
        WeakRef weak_meta_item = WeakRef(meta_item);
        WeakRef weak_message = WeakRef(message);
        message.notify["marked"].connect(() => {
            Plugins.MetaConversationItem? mi = weak_meta_item.get() as Plugins.MetaConversationItem;
            Message? m = weak_message.get() as Message;
            if (mi == null || m == null) return;
            mi.mark = m.marked;
        });
        item_collection.insert_item(meta_item);
    }
}

}
