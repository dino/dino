using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class FileMessageFilter : ContentFilter, Object {
    public Database db;

    public FileMessageFilter(Dino.Database db) {
        this.db = db;
    }

    public bool discard(ContentItem content_item) {
        if (content_item.type_ == MessageItem.TYPE) {
            MessageItem message_item = content_item as MessageItem;
            return message_is_file(db, message_item.message);
        }
        return false;
    }
}

}
