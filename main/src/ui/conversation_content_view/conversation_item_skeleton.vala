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
    public bool item_in_edit_mode { get; set; }
    public ContentMetaItem? content_meta_item = null;
    public Widget? widget = null;

    private Box image_content_box = new Box(Orientation.HORIZONTAL, 8) { visible=true };
    private Box header_content_box = new Box(Orientation.VERTICAL, 0) { visible=true };
    private ItemMetaDataHeader? metadata_header = null;
    private AvatarImage? image = null;

    public ConversationItemSkeleton(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item, bool initial_item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;
        this.content_meta_item = item as ContentMetaItem;
        this.get_style_context().add_class("message-box");

        item.bind_property("in-edit-mode", this, "item-in-edit-mode");
        this.notify["item-in-edit-mode"].connect(() => {
            if (item.in_edit_mode) {
                this.get_style_context().add_class("edit-mode");
            } else {
                this.get_style_context().remove_class("edit-mode");
            }
        });

        widget = item.get_widget(Plugins.WidgetType.GTK) as Widget;
        if (widget != null) {
            widget.valign = Align.END;
            header_content_box.add(widget);
        }

        image_content_box.add(header_content_box);

        if (initial_item) {
            this.add(image_content_box);
        } else {
            Revealer revealer = new Revealer() { transition_duration=200, transition_type=RevealerTransitionType.SLIDE_UP, reveal_child=false, visible=true };
            revealer.add_with_properties(image_content_box);
            this.add(revealer);
            revealer.reveal_child = true;
        }


        this.notify["show-skeleton"].connect(update_margin);
        this.notify["last-group-item"].connect(update_margin);

        update_margin();
    }

    public void set_edit_mode() {
        if (content_meta_item == null) return;

    }

    private void update_margin() {
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
    public Image received_image = new Image() { opacity=0.4 };
    public Image? unencrypted_image = null;

    public static IconSize ICON_SIZE_HEADER = Gtk.icon_size_register("im.dino.Dino.HEADER_ICON", 17, 12);

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private Plugins.MetaConversationItem item;
    public Entities.Message.Marked item_mark { get; set; }
    private ArrayList<Plugins.MetaConversationItem> items = new ArrayList<Plugins.MetaConversationItem>();
    private uint time_update_timeout = 0;

    public ItemMetaDataHeader(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;
        items.add(item);

        update_name_label();
        name_label.style_updated.connect(update_name_label);

        Application app = GLib.Application.get_default() as Application;

        ContentMetaItem ci = item as ContentMetaItem;
        if (ci != null) {
            foreach(var e in app.plugin_registry.encryption_list_entries) {
                if (e.encryption == item.encryption) {
                    Object? w = e.get_encryption_icon(conversation, ci.content_item);
                    if (w != null) {
                        this.add(w as Widget);
                    } else {
                        Image image = new Image.from_icon_name("dino-changes-prevent-symbolic", ICON_SIZE_HEADER) { opacity=0.4, visible = true };
                        this.add(image);
                    }
                    break;
                }
            }
        }
        if (item.encryption == Encryption.NONE) {
            conversation.notify["encryption"].connect(update_unencrypted_icon);
            update_unencrypted_icon();
        }

        this.add(received_image);

        if (item.display_time != null) {
            update_time();
        }

        item.bind_property("mark", this, "item-mark");
        this.notify["item-mark"].connect_after(update_received_mark);
        update_received_mark();
    }

    private void update_unencrypted_icon() {
        if (conversation.encryption != Encryption.NONE && unencrypted_image == null) {
            unencrypted_image = new Image() { opacity=0.4, visible = true };
            unencrypted_image.set_from_icon_name("dino-changes-allowed-symbolic", ICON_SIZE_HEADER);
            unencrypted_image.tooltip_text = _("Unencrypted");
            this.add(unencrypted_image);
            this.reorder_child(unencrypted_image, 3);
            Util.force_error_color(unencrypted_image);
        } else if (conversation.encryption == Encryption.NONE && unencrypted_image != null) {
            unencrypted_image.destroy();
            unencrypted_image = null;
        }
    }

    private void update_time() {
        time_label.label = get_relative_time(item.display_time.to_local()).to_string();

        time_update_timeout = Timeout.add_seconds((int) get_next_time_change(), () => {
            if (this.parent == null) return false;
            update_time();
            return false;
        });
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
                Util.force_error_color(time_label);
                string error_text = _("Unable to send message");
                received_image.tooltip_text = error_text;
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

    private int get_next_time_change() {
        DateTime now = new DateTime.now_local();
        DateTime item_time = item.display_time;
        TimeSpan timespan = now.difference(item_time);

        if (timespan < 10 * TimeSpan.MINUTE) {
            if (now.get_second() < item_time.get_second()) {
                return item_time.get_second() - now.get_second();
            } else {
                return 60 - (now.get_second() - item_time.get_second());
            }
        } else {
            return (23 - now.get_hour()) * 3600 + (59 - now.get_minute()) * 60 + (59 - now.get_second());
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

    public override void dispose() {
        base.dispose();

        if (time_update_timeout != 0) {
            Source.remove(time_update_timeout);
            time_update_timeout = 0;
        }
    }
}

}
