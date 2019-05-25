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
        if (item.display_time == null) return;

        DateTime time = item.sort_time.to_local();
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
    public override DateTime? sort_time { get; set; }

    public override bool can_merge { get; set; default=false; }
    public override bool requires_avatar { get; set; default=false; }
    public override bool requires_header { get; set; default=false; }

    private DateTime date;

    public MetaDateItem(DateTime date) {
        this.date = date;
        this.sort_time = date;
    }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        Box box = new Box(Orientation.HORIZONTAL, 10) { width_request=300, halign=Align.CENTER, visible=true };
        box.add(new Separator(Orientation.HORIZONTAL) { valign=Align.CENTER, hexpand=true, visible=true });
        string date_str = get_relative_time(date);
        Label label = new Label(@"<span size='small'>$date_str</span>") { use_markup=true, halign=Align.CENTER, hexpand=false, visible=true };
        label.get_style_context().add_class("dim-label");
        box.add(label);
        box.add(new Separator(Orientation.HORIZONTAL) { valign=Align.CENTER, hexpand=true, visible=true });
        return box;
    }

    private static string get_relative_time(DateTime time) {
        DateTime time_local = time.to_local();
        DateTime now_local = new DateTime.now_local();
        if (time_local.get_year() == now_local.get_year() &&
            time_local.get_month() == now_local.get_month() &&
            time_local.get_day_of_month() == now_local.get_day_of_month()) {
            return _("Today");
        }
        DateTime now_local_minus = now_local.add_days(-1);
        if (time_local.get_year() == now_local_minus.get_year() &&
            time_local.get_month() == now_local_minus.get_month() &&
            time_local.get_day_of_month() == now_local_minus.get_day_of_month()) {
            return _("Yesterday");
        }
        if (time_local.get_year() != now_local.get_year()) {
            return time_local.format("%x");
        }
        TimeSpan timespan = now_local.difference(time_local);
        if (timespan < 7 * TimeSpan.DAY) {
            return time_local.format(_("%a, %b %d"));
        } else {
            return time_local.format(_("%b %d"));
        }
    }
}

}
