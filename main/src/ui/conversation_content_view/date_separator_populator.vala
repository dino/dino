using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

class DateSeparatorPopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

    public string id { get { return "date_separator"; } }

    private StreamInteractor stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;
    private Gee.TreeSet<DateTime> insert_times;

    public DateSeparatorPopulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;
        item_collection.inserted_item.connect(on_inserted_item);
        this.insert_times = new TreeSet<DateTime>((a, b) => {
            return a.compare(b);
        });
    }

    public void close(Conversation conversation) {
        item_collection.inserted_item.disconnect(on_inserted_item);
    }

    public void populate_timespan(Conversation conversation, DateTime after, DateTime before) { }

    private void on_inserted_item(Plugins.MetaConversationItem item) {
        if (!(item is ContentMetaItem)) return;

        DateTime time = item.time.to_local();
        DateTime msg_date = new DateTime.local(time.get_year(), time.get_month(), time.get_day_of_month(), 0, 0, 0);
        if (!insert_times.contains(msg_date)) {
            if (insert_times.lower(msg_date) != null) {
                item_collection.insert_item(new MetaDateItem(msg_date.to_utc()));
            } else if (insert_times.size > 0) {
                item_collection.insert_item(new MetaDateItem(insert_times.first().to_utc()));
            }
            insert_times.add(msg_date);
        }
    }
}

public class MetaDateItem : Plugins.MetaConversationItem {
    public override DateTime time { get; set; }

    public MetaDateItem(DateTime date) {
        this.time = date;
    }

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType widget_type) {
        return new DateSeparator() { model = new ViewModel.CompatDateSeparatorModel(time) };
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
}

}
