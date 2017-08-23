using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/conversation_summary/message_item.ui")]
public class ConversationItemSkeleton : Grid {

    [GtkChild] private Image image;
    [GtkChild] private Label time_label;
    [GtkChild] private Image encryption_image;
    [GtkChild] private Image received_image;

    public StreamInteractor stream_interactor;
    public Conversation conversation { get; set; }
    public Gee.List<Plugins.MetaConversationItem> items = new ArrayList<Plugins.MetaConversationItem>();

    private Box box = new Box(Orientation.VERTICAL, 2) { visible=true };

    public ConversationItemSkeleton(StreamInteractor stream_interactor, Conversation conversation) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;

        set_main_widget(box);
    }

    public void add_meta_item(Plugins.MetaConversationItem item) {
        items.add(item);
        if (items.size == 1) {
            setup(item);
        }
        Widget widget = (Widget) item.get_widget(Plugins.WidgetType.GTK);
        if (item.requires_header) {
            box.add(widget);
        } else {
            set_title_widget(widget);
        }
        item.notify["mark"].connect_after(() => { Idle.add(() => { update_received(); return false; }); });
        update_received();
    }

    public void set_title_widget(Widget w) {
        attach(w, 1, 0, 1, 1);
    }

    public void set_main_widget(Widget w) {
        attach(w, 1, 1, 2, 1);
    }

    public void update_time() {
        if (items.size > 0 && items[0].display_time != null) {
            DateTime local = items[0].display_time.to_local();
            time_label.label = get_relative_time(items[0].display_time.to_local());
            /* xgettext:no-c-format */ /* Full date + time for the relative time tooltip */
            time_label.tooltip_text = local.format(_("%x %X"));
        }
    }

    private void setup(Plugins.MetaConversationItem item) {
        update_time();
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(30, 30, image.scale_factor)).set_greyscale(item.dim).draw_jid(stream_interactor, item.jid, conversation.account));
        if (item.requires_header) {
            set_default_title_widget(item.jid);
        }
        if (item.encryption != null && item.encryption != Encryption.NONE) {
            encryption_image.visible = true;
            encryption_image.set_from_icon_name("changes-prevent-symbolic", IconSize.SMALL_TOOLBAR);
        }
    }

    private void set_default_title_widget(Jid jid) {
        Label name_label = new Label("") { use_markup=true, xalign=0, hexpand=true, visible=true };
        string display_name = Util.get_display_name(stream_interactor, jid, conversation.account);
        string color = Util.get_name_hex_color(stream_interactor, conversation.account, jid, Util.is_dark_theme(name_label));
        name_label.label = @"<span foreground=\"#$color\">$display_name</span>";
        name_label.style_updated.connect(() => {
            string new_color = Util.get_name_hex_color(stream_interactor, conversation.account, jid, Util.is_dark_theme(name_label));
            name_label.set_markup(@"<span foreground=\"#$new_color\">$display_name</span>");
        });
        set_title_widget(name_label);
    }

    private void update_received() {
        bool all_received = true;
        bool all_read = true;
        bool all_sent = true;
        foreach (Plugins.MetaConversationItem item in items) {
            if (item.mark == Message.Marked.WONTSEND) {
                received_image.visible = true;
                received_image.set_from_icon_name("dialog-warning-symbolic", IconSize.SMALL_TOOLBAR);
                Util.force_error_color(received_image);
                Util.force_error_color(encryption_image);
                Util.force_error_color(time_label);
                return;
            } else if (item.mark != Message.Marked.READ) {
                all_read = false;
                if (item.mark != Message.Marked.RECEIVED) {
                    all_received = false;
                    if (item.mark == Message.Marked.UNSENT) {
                        all_sent = false;
                    }
                }
            }
        }
        if (all_read) {
            received_image.visible = true;
            received_image.set_from_icon_name("dino-double-tick-symbolic", IconSize.SMALL_TOOLBAR);
        } else if (all_received) {
            received_image.visible = true;
            received_image.set_from_icon_name("dino-tick-symbolic", IconSize.SMALL_TOOLBAR);
        } else if (!all_sent) {
            received_image.visible = true;
            received_image.set_from_icon_name("image-loading-symbolic", IconSize.SMALL_TOOLBAR);
        } else if (received_image.visible) {
            received_image.set_from_icon_name("image-loading-symbolic", IconSize.SMALL_TOOLBAR);
        }
    }

    private static string format_time(DateTime datetime, string format_24h, string format_12h) {
        string format = Util.is_24h_format() ? format_24h : format_12h;
        if (!get_charset(null)) {
            // No UTF-8 support, use simple colon for time instead
            format = format.replace("∶", ":");
        }
        return datetime.format(format);
    }

    private static string get_relative_time(DateTime datetime) {
        DateTime now = new DateTime.now_local();
        TimeSpan timespan = now.difference(datetime);
        if (timespan > 365 * TimeSpan.DAY) {
            return format_time(datetime,
                /* xgettext:no-c-format */ /* Date + time in 24h format (w/o seconds) */ _("%x, %H∶%M"),
                /* xgettext:no-c-format */ /* Date + time in 12h format (w/o seconds)*/ _("%x, %l∶%M %p"));
        } else if (timespan > 7 * TimeSpan.DAY) {
            return format_time(datetime,
                /* xgettext:no-c-format */ /* Month, day and time in 24h format (w/o seconds) */ _("%b %d, %H∶%M"),
                /* xgettext:no-c-format */ /* Month, day and time in 12h format (w/o seconds) */ _("%b %d, %l∶%M %p"));
        } else if (datetime.get_day_of_month() != now.get_day_of_month()) {
            return format_time(datetime,
                /* xgettext:no-c-format */ /* Day of week and time in 24h format (w/o seconds) */ _("%a, %H∶%M"),
                /* xgettext:no-c-format */ /* Day of week and time in 12h format (w/o seconds) */_("%a, %l∶%M %p"));
        } else if (timespan > 9 * TimeSpan.MINUTE) {
            return format_time(datetime,
                /* xgettext:no-c-format */  /* Time in 24h format (w/o seconds) */ _("%H∶%M"),
                /* xgettext:no-c-format */  /* Time in 12h format (w/o seconds) */ _("%l∶%M %p"));
        } else if (timespan > TimeSpan.MINUTE) {
            ulong mins = (ulong) (timespan.abs() / TimeSpan.MINUTE);
            /* xgettext:this is the beginning of a sentence. */
            return n("%i min ago", "%i mins ago", mins).printf(mins);
        } else {
            return _("Just now");
        }
    }
}

}
