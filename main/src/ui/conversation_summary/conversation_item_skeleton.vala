using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ConversationItemSkeleton : EventBox {

    private AvatarImage image = new AvatarImage() { margin_top=2, valign=Align.START, visible=true, allow_gray = false };

    public bool show_skeleton { get; set; }
    public bool last_group_item { get; set; }

    public StreamInteractor stream_interactor;
    public Conversation conversation { get; set; }
    public Plugins.MetaConversationItem item;

    private Box image_content_box = new Box(Orientation.HORIZONTAL, 8) { visible=true };
    private Box header_content_box = new Box(Orientation.VERTICAL, 0) { visible=true };
    private DefaultSkeletonHeader default_header;

    public ConversationItemSkeleton(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;
        this.get_style_context().add_class("message-box");

        if (item.requires_avatar) {
            image.set_jid(stream_interactor, item.jid, conversation.account);
            image_content_box.add(image);
        }
        if (item.display_time != null) {
            default_header = new DefaultSkeletonHeader(stream_interactor, conversation, item) { visible=true };
            if (!item.requires_header) {
                default_header.name_label.visible = false;
                default_header.dot_label.visible = false;
            }
            header_content_box.add(default_header);
        }

        // add item
        this.item = item;
        if (default_header != null) {
            default_header.add_item(item);
        }
        Widget? widget = item.get_widget(Plugins.WidgetType.GTK) as Widget;
        widget.valign = Align.END;
        if (widget != null) {
            header_content_box.add(widget);
        }

        image_content_box.add(header_content_box);
        this.add(image_content_box);

        if (item.get_type().is_a(typeof(ContentMetaItem))) {
            this.motion_notify_event.connect((event) => {
                this.set_state_flags(StateFlags.PRELIGHT, false);
                return false;
            });
            this.enter_notify_event.connect((event) => {
                this.set_state_flags(StateFlags.PRELIGHT, false);
                return false;
            });
            this.leave_notify_event.connect((event) => {
                this.unset_state_flags(StateFlags.PRELIGHT);
                return false;
            });
        }

        this.notify["show-skeleton"].connect(update_margin);
        this.notify["last-group-item"].connect(update_margin);

        this.show_skeleton = true;
        this.last_group_item = true;
        update_margin();
    }

    public void update_time() {
        if (default_header != null) {
            default_header.update_time();
        }
    }

    public void update_margin() {
        image.visible = this.show_skeleton;
        if (default_header != null) {
            default_header.visible = this.show_skeleton;
        }
        image_content_box.margin_start = this.show_skeleton ? 15 : 58;

        if (this.show_skeleton && this.last_group_item) {
            image_content_box.margin_top = 8;
            image_content_box.margin_bottom = 8;
        } else {
            image_content_box.margin_top = 4;
            image_content_box.margin_bottom = 4;
        }
    }
}

public class DefaultSkeletonHeader : Box {
    private Box box = new Box(Orientation.HORIZONTAL, 4) { visible=true };
    public Label name_label = new Label("") { use_markup=true, valign=Align.START, xalign=0, visible=true };
    public Label time_label = new Label("") { use_markup=true, valign=Align.START, xalign=0, visible=true };
    public Label dot_label = new Label("<span size='small'>·</span>") { use_markup=true, valign=Align.START, xalign=0, visible=true };
    public Image encryption_image = new Image();
    public Image received_image = new Image();

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private Plugins.MetaConversationItem item;
    private ArrayList<Plugins.MetaConversationItem> items = new ArrayList<Plugins.MetaConversationItem>();

    public static IconSize ICON_SIZE_HEADER = Gtk.icon_size_register("im.dino.Dino.HEADER_ICON", 17, 12);
    public virtual string TEXT_SIZE { get { return "small"; } }

    construct {
        time_label.get_style_context().add_class("dim-label");
        dot_label.get_style_context().add_class("dim-label");
        encryption_image.opacity = 0.4;
        received_image.opacity = 0.4;
    }

    public DefaultSkeletonHeader(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;

        box.add(name_label);
        box.add(dot_label);
        box.add(time_label);
        box.add(received_image);
        box.add(encryption_image);
        this.add(box);

        update_name_label();
        name_label.style_updated.connect(update_name_label);
        if (item.encryption != null && item.encryption != Encryption.NONE) {
            encryption_image.visible = true;
            encryption_image.set_from_icon_name("dino-changes-prevent-symbolic", ICON_SIZE_HEADER);
        }
        update_time();
        add_item(item);
    }

    public void add_item(Plugins.MetaConversationItem item) {
        items.add(item);
        item.notify["mark"].connect_after(update_received_mark);
        update_received_mark();
    }

    public void update_time() {
        if (item.display_time != null) {
            time_label.label = @"<span size='$TEXT_SIZE'>" + get_relative_time(item.display_time.to_local()) + "</span>";
        }
    }

    private void update_name_label() {
        string display_name = Util.get_display_name(stream_interactor, item.jid, conversation.account);
        string color = Util.get_name_hex_color(stream_interactor, conversation.account, item.jid, Util.is_dark_theme(name_label));
        name_label.label = @"<span size='$TEXT_SIZE' foreground=\"#$color\">$display_name</span>";
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
