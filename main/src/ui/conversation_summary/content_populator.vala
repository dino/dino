using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ContentProvider : ContentItemCollection, Object {

    private StreamInteractor stream_interactor;
    private ContentItemWidgetFactory widget_factory;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    public ContentProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.widget_factory =  new ContentItemWidgetFactory(stream_interactor);
    }

    public void init(Plugins.ConversationItemCollection item_collection, Conversation conversation, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;
        stream_interactor.get_module(ContentItemAccumulator.IDENTITY).init(conversation, this);
    }

    public void close(Conversation conversation) { }

    public void insert_item(ContentItem item) {
        item_collection.insert_item(new ContentMetaItem(item, widget_factory));
    }

    public void remove_item(ContentItem item) { }


    public Gee.List<ContentMetaItem> populate_latest(Conversation conversation, int n) {
        Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemAccumulator.IDENTITY).populate_latest(this, conversation, n);
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        foreach (ContentItem item in items) {
            ret.add(new ContentMetaItem(item, widget_factory));
        }
        return ret;
    }

    public Gee.List<ContentMetaItem> populate_before(Conversation conversation, Plugins.MetaConversationItem before_item, int n) {
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        ContentMetaItem? content_meta_item = before_item as ContentMetaItem;
        if (content_meta_item != null) {
            Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemAccumulator.IDENTITY).populate_before(this, conversation, content_meta_item.content_item, n);
            foreach (ContentItem item in items) {
                ret.add(new ContentMetaItem(item, widget_factory));
            }
        }
        return ret;
    }

    public Gee.List<ContentMetaItem> populate_after(Conversation conversation, Plugins.MetaConversationItem before_item, int n) {
        Gee.List<ContentMetaItem> ret = new ArrayList<ContentMetaItem>();
        ContentMetaItem? content_meta_item = before_item as ContentMetaItem;
        if (content_meta_item != null) {
            Gee.List<ContentItem> items = stream_interactor.get_module(ContentItemAccumulator.IDENTITY).populate_after(this, conversation, content_meta_item.content_item, n);
            foreach (ContentItem item in items) {
                ret.add(new ContentMetaItem(item, widget_factory));
            }
        }
        return ret;
    }
}

public class ContentMetaItem : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override DateTime? sort_time { get; set; }
    public override DateTime? display_time { get; set; }
    public override Encryption? encryption { get; set; }

    public ContentItem content_item;
    private ContentItemWidgetFactory widget_factory;

    public ContentMetaItem(ContentItem content_item, ContentItemWidgetFactory widget_factory) {
        this.jid = content_item.jid;
        this.sort_time = content_item.sort_time;
        this.seccondary_sort_indicator = content_item.seccondary_sort_indicator;
        this.display_time = content_item.display_time;
        this.encryption = content_item.encryption;
        this.mark = content_item.mark;

        WeakRef weak_item = WeakRef(content_item);
        content_item.notify["mark"].connect(() => {
            ContentItem? ci = weak_item.get() as ContentItem;
            if (ci == null) return;
            this.mark = ci.mark;
        });

        this.can_merge = true;
        this.requires_avatar = true;
        this.requires_header = true;

        this.content_item = content_item;
        this.widget_factory = widget_factory;
    }

    public override bool can_merge { get; set; default=true; }
    public override bool requires_avatar { get; set; default=true; }
    public override bool requires_header { get; set; default=true; }

    public override Object? get_widget(Plugins.WidgetType type) {
        return widget_factory.get_widget(content_item);
    }
}

}
