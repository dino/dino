using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ConversationItemSkeleton : EventBox {

    public bool show_skeleton { get; set; default=false; }
    public bool last_group_item { get; set; default=true; }

    public StreamInteractor stream_interactor;
    public Conversation conversation { get; set; }
    public Plugins.MetaConversationItem item;

    private Box image_content_box = new Box(Orientation.HORIZONTAL, 8) { visible=true };
    private Box header_content_box = new Box(Orientation.VERTICAL, 0) { visible=true };
    private ItemMetaDataHeader? metadata_header = null;
    private AvatarImage? image = null;

    public ConversationItemSkeleton(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item, bool initial_item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;
        this.get_style_context().add_class("message-box");

        Widget? widget = item.get_widget(Plugins.WidgetType.GTK) as Widget;
        if (widget != null) {
            widget.valign = Align.END;
            header_content_box.add(widget);
        }

        image_content_box.add(header_content_box);

        if (initial_item) {
            this.add(image_content_box);
        } else {
            Revealer revealer = new Revealer() { transition_duration=200, transition_type = RevealerTransitionType.SLIDE_UP, visible = true };
            revealer.add_with_properties(image_content_box);
            revealer.reveal_child = true;
            this.add(revealer);
        }


        this.notify["show-skeleton"].connect(update_margin);
        this.notify["last-group-item"].connect(update_margin);

        update_margin();
    }

    public void update_time() {
        if (metadata_header != null) {
            metadata_header.update_time();
        }
    }

    public void update_margin() {
        if (item.requires_header && show_skeleton && metadata_header == null) {
            metadata_header = new ItemMetaDataHeader(stream_interactor, conversation, item) { visible=true };
            header_content_box.add(metadata_header);
            header_content_box.reorder_child(metadata_header, 0);
        }
        if (item.requires_avatar && show_skeleton && image == null) {
            image = new AvatarImage() { margin_top=2, valign=Align.START, visible=true, allow_gray = false };
            image.set_conversation_participant(stream_interactor, conversation, item.jid);
            image_content_box.add(image);
            image_content_box.reorder_child(image, 0);
        }

        if (image != null) {
            image.visible = this.show_skeleton;
        }
        if (metadata_header != null) {
            metadata_header.visible = this.show_skeleton;
        }
        image_content_box.margin_start = this.show_skeleton ? 15 : 58;
        image_content_box.margin_end = 15;

        if (this.show_skeleton && this.last_group_item) {
            image_content_box.margin_top = 8;
            image_content_box.margin_bottom = 8;
        } else {
            image_content_box.margin_top = 4;
            image_content_box.margin_bottom = 4;
        }
    }
}

[GtkTemplate (ui = "/im/dino/Dino/conversation_content_view/item_metadata_header.ui")]
public class ItemMetaDataHeader : Box {
    [GtkChild] public Label name_label;
    [GtkChild] public Label dot_label;
    [GtkChild] public Label time_label;
    [GtkChild] public Image encryption_image;
    [GtkChild] public Image received_image;

    public static IconSize ICON_SIZE_HEADER = Gtk.icon_size_register("im.dino.Dino.HEADER_ICON", 17, 12);

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private Plugins.MetaConversationItem item;
    private ArrayList<Plugins.MetaConversationItem> items = new ArrayList<Plugins.MetaConversationItem>();

    public ItemMetaDataHeader(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;
        items.add(item);

        update_name_label();
        name_label.style_updated.connect(update_name_label);
        if (item.encryption != Encryption.NONE) {
            encryption_image.visible = true;
            encryption_image.set_from_icon_name("dino-changes-prevent-symbolic", ICON_SIZE_HEADER);
        }
        update_time();

        item.notify["mark"].connect_after(update_received_mark);
        update_received_mark();
    }

    public void update_time() {
        if (item.display_time != null) {
            time_label.label = get_relative_time(item.display_time.to_local()).to_string();
        }
    }

    private void update_name_label() {
        string display_name = Markup.escape_text(Util.get_participant_display_name(stream_interactor, conversation, item.jid));
        string color = Util.get_name_hex_color(stream_interactor, conversation.account, item.jid, Util.is_dark_theme(name_label));
        name_label.label = @"<span foreground=\"#$color\">$display_name</span>";
    }

    private void update_received_mark() {
        bool all_received = true;
        bool all_read = true;
        bool all_sent = true;
        foreach (Plugins.MetaConversationItem item in items) {
            if (item.mark == Message.Marked.WONTSEND) {
                received_image.visible = true;
                received_image.set_from_icon_name("dialog-warning-symbolic", ICON_SIZE_HEADER);
                Util.force_error_color(received_image);
                Util.force_error_color(encryption_image);
                Util.force_error_color(time_label);
                string error_text = _("Unable to send message");
                received_image.tooltip_text = error_text;
                encryption_image.tooltip_text = error_text;
                time_label.tooltip_text = error_text;
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
            received_image.set_from_icon_name("dino-double-tick-symbolic", ICON_SIZE_HEADER);
        } else if (all_received) {
            received_image.visible = true;
            received_image.set_from_icon_name("dino-tick-symbolic", ICON_SIZE_HEADER);
        } else if (!all_sent) {
            received_image.visible = true;
            received_image.set_from_icon_name("image-loading-symbolic", ICON_SIZE_HEADER);
        } else if (received_image.visible) {
            received_image.set_from_icon_name("image-loading-symbolic", ICON_SIZE_HEADER);

        }
    }

    public static string format_time(DateTime datetime, string format_24h, string format_12h) {
        string format = Util.is_24h_format() ? format_24h : format_12h;
        if (!get_charset(null)) {
            // No UTF-8 support, use simple colon for time instead
            format = format.replace("∶", ":");
        }
        return datetime.format(format);
    }

    public static string get_relative_time(DateTime datetime) {
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
