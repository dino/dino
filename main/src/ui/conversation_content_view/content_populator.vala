using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ContentProvider : ContentItemCollection, Object {

    private StreamInteractor stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    public ContentProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void init(Plugins.ConversationItemCollection item_collection, Conversation conversation, Plugins.WidgetType type) {
        if (current_conversation != null) {
            stream_interactor.get_module(ContentItemStore.IDENTITY).uninit(current_conversation, this);
        }
        current_conversation = conversation;
        this.item_collection = item_collection;
        stream_interactor.get_module(ContentItemStore.IDENTITY).init(conversation, this);
    }

    public void insert_item(ContentItem item) {
        item_collection.insert_item(create_content_meta_item(item));
    }

    public void remove_item(ContentItem item) { }


    public Gee.List<ContentMetaItem> populate_latest(Conversation conversation, int n) {
        Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemStore.IDENTITY).get_n_latest(conversation, n);
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        foreach (ContentItem item in items) {
            ret.add(create_content_meta_item(item));
        }
        return ret;
    }

    public Gee.List<ContentMetaItem> populate_before(Conversation conversation, ContentItem before_item, int n) {
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemStore.IDENTITY).get_before(conversation, before_item, n);
        foreach (ContentItem item in items) {
            ret.add(create_content_meta_item(item));
        }
        return ret;
    }

    public Gee.List<ContentMetaItem> populate_after(Conversation conversation, ContentItem after_item, int n) {
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemStore.IDENTITY).get_after(conversation, after_item, n);
        foreach (ContentItem item in items) {
            ret.add(create_content_meta_item(item));
        }
        return ret;
    }

    public ContentMetaItem get_content_meta_item(ContentItem content_item) {
        return create_content_meta_item(content_item);
    }

    private ContentMetaItem create_content_meta_item(ContentItem content_item) {
        if (content_item.type_ == MessageItem.TYPE) {
            return new MessageMetaItem(content_item, stream_interactor);
        } else if (content_item.type_ == FileItem.TYPE) {
            return new FileMetaItem(content_item, stream_interactor);
        }
        return null;
    }
}

public abstract class ContentMetaItem : Plugins.MetaConversationItem {

    public ContentItem content_item;

    protected ContentMetaItem(ContentItem content_item) {
        this.jid = content_item.jid;
        this.sort_time = content_item.sort_time;
        this.seccondary_sort_indicator = (long) content_item.display_time.to_unix();
        this.tertiary_sort_indicator = content_item.id;
        this.display_time = content_item.display_time;
        this.encryption = content_item.encryption;
        this.mark = content_item.mark;

        content_item.bind_property("mark", this, "mark");

        this.can_merge = true;
        this.requires_avatar = true;
        this.requires_header = true;

        this.content_item = content_item;
    }
}

}
