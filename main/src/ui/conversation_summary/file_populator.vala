using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

class FilePopulator : Plugins.ConversationItemPopulator, Object {

    public string id { get { return "file"; } }

    private StreamInteractor? stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    public FilePopulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(FileManager.IDENTITY).received_file.connect((file_transfer) => {
            if (current_conversation != null && current_conversation.account.equals(file_transfer.account) && current_conversation.counterpart.equals_bare(file_transfer.counterpart)) {
                insert_file(file_transfer);
            }
        });
    }

    public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;
    }

    public void close(Conversation conversation) { }

    public void populate_timespan(Conversation conversation, DateTime from, DateTime to) {
        Gee.List<FileTransfer> transfers = stream_interactor.get_module(FileManager.IDENTITY).get_file_transfers(conversation.account, conversation.counterpart, from, to);
        foreach (FileTransfer transfer in transfers) {
            insert_file(transfer);
        }
    }

    public void populate_between_widgets(Conversation conversation, DateTime from, DateTime to) { }

    private void insert_file(FileTransfer transfer) {
        Plugins.MetaConversationItem item = null;
        if (transfer.mime_type != null && transfer.mime_type.has_prefix("image")) {
            item = new ImageDisplay(stream_interactor, transfer);
        } else {
            item = new DefaultFileDisplay(stream_interactor, transfer);
        }
        item_collection.insert_item(item);
    }
}

}
