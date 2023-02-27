using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ConversationItemSkeleton : Plugins.ConversationItemWidgetInterface, Object {

    public Grid main_grid { get; set; }
    public Label name_label { get; set; }
    public Label time_label { get; set; }
    public AvatarImage avatar_image { get; set; }
    public Image encryption_image { get; set; }
    public Image received_image { get; set; }

    private HashMap<int, Widget> content_widgets = new HashMap<int, Widget>();

    private bool show_skeleton_ = false;
    public bool show_skeleton {
        get { return show_skeleton_; }
        set {
            show_skeleton_ = value && content_meta_item != null && content_meta_item.requires_header && content_meta_item.requires_avatar; }
    }

    public StreamInteractor stream_interactor;
    public Conversation conversation { get; set; }
    public Plugins.MetaConversationItem item;
    public bool item_in_edit_mode { get; set; }
    public Entities.Message.Marked item_mark { get; set; }
    public ContentMetaItem content_meta_item = null;
    public Widget? widget = null;
    private ReactionsController? reactions_controller = null;

    private uint time_update_timeout = 0;
    private ulong updated_roster_handler_id = 0;

    public ConversationItemSkeleton(StreamInteractor stream_interactor, Conversation conversation, Plugins.MetaConversationItem item) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.item = item;
        this.content_meta_item = item as ContentMetaItem;

        item.bind_property("in-edit-mode", this, "item-in-edit-mode");
        this.notify["item-in-edit-mode"].connect(update_edit_mode);

        Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_item_widget.ui");
        main_grid = (Grid) builder.get_object("main_grid");
        main_grid.add_css_class("message-box");
        name_label = (Label) builder.get_object("name_label");
        time_label = (Label) builder.get_object("time_label");
        avatar_image = (AvatarImage) builder.get_object("avatar_image");
        encryption_image = (Image) builder.get_object("encrypted_image");
        received_image = (Image) builder.get_object("marked_image");

        widget = item.get_widget(this, Plugins.WidgetType.GTK4) as Widget;
        if (widget != null) {
            widget.valign = Align.END;
            set_widget(widget, Plugins.WidgetType.GTK4, 2);
        }

        if (item.requires_header) {
            avatar_image.set_conversation_participant(stream_interactor, conversation, item.jid);
        }

        this.notify["show-skeleton"].connect(update_margin);
        this.notify["show-skeleton"].connect(set_header);

        ContentMetaItem? content_meta_item = item as ContentMetaItem;
        if (content_meta_item != null) {
            reactions_controller = new ReactionsController(conversation, content_meta_item.content_item, stream_interactor);
            reactions_controller.box_activated.connect(on_reaction_box_activated);
            reactions_controller.init();
        }

        update_margin();
    }

    private void set_header() {
        if (!show_skeleton) return;

        update_name_label();
//            name_label.style_updated.connect(update_name_label);
            updated_roster_handler_id = stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
            if (this.conversation.account.equals(account) && this.conversation.counterpart.equals(jid)) {
                update_name_label();
            }
        });

        item.notify["encryption"].connect(update_encryption_icon);
        update_encryption_icon();

        if (item.time != null) {
            update_time();
        }

        item.bind_property("mark", this, "item-mark", BindingFlags.SYNC_CREATE);
        this.notify["item-mark"].connect_after(update_received_mark);
        update_received_mark();
    }

    public void set_widget(Object object, Plugins.WidgetType type, int priority) {
        foreach (var content_widget in content_widgets.values) {
            content_widget.unparent();
        }

        content_widgets[priority] = (Widget) object;
        int row_no = 1;
        for (int i = 0; i < 5; i++) {
            if (!content_widgets.has_key(i)) continue;
            main_grid.attach(content_widgets[i], 1, row_no, 4, 1);
            row_no++;
        }
    }

    private void update_margin() {
        avatar_image.visible = show_skeleton;
        name_label.visible = show_skeleton;
        time_label.visible = show_skeleton;
        encryption_image.visible = show_skeleton;
        received_image.visible = show_skeleton;

        if (show_skeleton || content_meta_item == null) {
            main_grid.add_css_class("has-skeleton");
        }
    }

    private void update_edit_mode() {
        if (item.in_edit_mode) {
            main_grid.add_css_class("edit-mode");
        } else {
            main_grid.remove_css_class("edit-mode");
        }
    }

    private void update_error_mode() {
        if (item_mark == Message.Marked.ERROR) {
            main_grid.add_css_class("error");
        } else {
            main_grid.remove_css_class("error");
        }
    }

    private void update_encryption_icon() {
        Application app = GLib.Application.get_default() as Application;

        ContentMetaItem ci = item as ContentMetaItem;
        if (item.encryption != Encryption.NONE && item.encryption != Encryption.UNKNOWN && ci != null) {
            string? icon_name = null;
            var encryption_entry = app.plugin_registry.encryption_list_entries[item.encryption];
            icon_name = encryption_entry.get_encryption_icon_name(conversation, ci.content_item);
            encryption_image.icon_name = icon_name ?? "changes-prevent-symbolic";
            encryption_image.visible = true;
        }

        if (item.encryption == Encryption.NONE) {
            if (conversation.encryption != Encryption.NONE) {
                encryption_image.icon_name = "changes-allow-symbolic";
                encryption_image.tooltip_text = Util.string_if_tooltips_active(_("Unencrypted"));
                Util.force_error_color(encryption_image);
                encryption_image.visible = true;
            } else if (conversation.encryption == Encryption.NONE) {
                encryption_image.icon_name = null;
                encryption_image.visible = false;
            }
        }
    }

    private void on_reaction_box_activated(Widget widget) {
        set_widget(widget, Plugins.WidgetType.GTK4, 3);
    }

    private void update_time() {
        time_label.label = get_relative_time(item.time.to_local()).to_string();

        time_update_timeout = Timeout.add_seconds((int) get_next_time_change(item.time), () => {
            if (this.main_grid.parent == null) return false;
            update_time();
            return false;
        });
    }

    private void update_name_label() {
        name_label.label = Util.get_participant_display_name(stream_interactor, conversation, item.jid, true);
    }

    private void update_received_mark() {
        switch (content_meta_item.mark) {
            case Message.Marked.RECEIVED: 
                received_image.icon_name = "dino-tick-symbolic";
                received_image.tooltip_text = Util.string_if_tooltips_active(_("Delivered"));
                break;
            case Message.Marked.READ:
                received_image.icon_name = "dino-double-tick-symbolic";
                received_image.tooltip_text = Util.string_if_tooltips_active(_("Read"));
                break;
            case Message.Marked.WONTSEND:
                received_image.icon_name = "dialog-warning-symbolic";
                Util.force_error_color(received_image);
                Util.force_error_color(time_label);
                string error_text = Util.string_if_tooltips_active(_("Unable to send message"));
                received_image.tooltip_text = error_text;
                time_label.tooltip_text = error_text;
                break;
            default: received_image.icon_name = null; break;
        }
    }

    public static int get_next_time_change(DateTime datetime) {
        DateTime now = new DateTime.now_local();
        TimeSpan timespan = now.difference(datetime);

        if (timespan < 10 * TimeSpan.MINUTE) {
            if (now.get_second() < datetime.get_second()) {
                return datetime.get_second() - now.get_second();
            } else {
                return 60 - (now.get_second() - datetime.get_second());
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

    public Widget get_widget() {
        return main_grid;
    }

    public override void dispose() {
        if (time_update_timeout != 0) {
            Source.remove(time_update_timeout);
            time_update_timeout = 0;
        }
        if (updated_roster_handler_id != 0){
            stream_interactor.get_module(RosterManager.IDENTITY).disconnect(updated_roster_handler_id);
            updated_roster_handler_id = 0;
        }
        reactions_controller = null;

        // Children won't be disposed automatically
        if (name_label != null) {
            name_label.unparent();
            name_label.dispose();
            name_label = null;
        }
        if (time_label != null) {
            time_label.unparent();
            time_label.dispose();
            time_label = null;
        }
        if (avatar_image != null) {
            avatar_image.unparent();
            avatar_image.dispose();
            avatar_image = null;
        }
        if (encryption_image != null) {
            encryption_image.unparent();
            encryption_image.dispose();
            encryption_image = null;
        }
        if (received_image != null) {
            received_image.unparent();
            received_image.dispose();
            received_image = null;
        }
        base.dispose();
    }
}

}
