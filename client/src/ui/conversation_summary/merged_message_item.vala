using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/org/dino-im/conversation_summary/message_item.ui")]
public class MergedMessageItem : Grid {

    public Conversation conversation { get; set; }
    public Jid from { get; private set; }
    public DateTime initial_time { get; private set; }
    public ArrayList<Message> messages = new ArrayList<Message>(Message.equals_func);

    [GtkChild]
    private Image image;

    [GtkChild]
    private Label time_label;

    [GtkChild]
    private Label name_label;

    [GtkChild]
    private Image encryption_image;

    [GtkChild]
    private Image received_image;

    [GtkChild]
    private TextView message_text_view;

    public MergedMessageItem(StreamInteractor stream_interactor, Conversation conversation, Message message) {
        this.conversation = conversation;
        this.from = message.from;
        this.initial_time = message.time;
        setup_tags();
        add_message(message);

        time_label.label = get_relative_time(initial_time.to_local());
        string display_name = Util.get_message_display_name(stream_interactor, message, conversation.account);
        name_label.set_markup(@"<span foreground=\"#$(Util.get_name_hex_color(display_name))\">$display_name</span>");
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(30, 30, image.scale_factor)).draw_message(stream_interactor, message));
        if (message.encryption == Entities.Message.Encryption.PGP) {
            encryption_image.visible = true;
            encryption_image.set_from_icon_name("changes-prevent-symbolic", IconSize.SMALL_TOOLBAR);
        }
    }

    public void update() {
        time_label.label = get_relative_time(initial_time.to_local());
    }

    public void add_message(Message message) {
        TextIter end;
        message_text_view.buffer.get_end_iter(out end);
        if (messages.size > 0) {
            message_text_view.buffer.insert(ref end, "\n", -1);
        }
        message_text_view.buffer.insert(ref end, message.body, -1);
        format_suffix_urls(message.body);
        messages.add(message);
        message.notify["marked"].connect_after(update_received); // TODO other thread? not main? css error? gtk main?
        update_received();
    }

    private void update_received() {
        received_image.visible = true;
        bool all_received = true;
        bool all_read = true;
        foreach (Message message in messages) {
            if (message.marked == Message.Marked.WONTSEND) {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
                Gtk.IconInfo? icon_info = icon_theme.lookup_icon("dialog-warning-symbolic", IconSize.SMALL_TOOLBAR, 0);
                received_image.set_from_pixbuf(icon_info.load_symbolic({1,0,0,1}));
                return;
            } else if (message.marked != Message.Marked.READ) {
                all_read = false;
                if (message.marked != Message.Marked.RECEIVED) {
                    all_received = false;
                }
            }
        }
        if (all_read) {
            received_image.visible = true;
            received_image.set_from_resource("/org/dino-im/img/double_tick.svg");
        } else if (all_received) {
            received_image.visible = true;
            received_image.set_from_resource("/org/dino-im/img/tick.svg");
        } else if (received_image.visible) {
            received_image.set_from_icon_name("image-loading-symbolic", IconSize.SMALL_TOOLBAR);
        }
    }

    private void format_suffix_urls(string text) {
        int absolute_start = message_text_view.buffer.text.length - text.length;

        Regex url_regex = new Regex("""(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))""");
        MatchInfo match_info;
        url_regex.match(text, 0, out match_info);
        for (; match_info.matches(); match_info.next()) {
            string? url = match_info.fetch(0);
            int start;
            int end;
            match_info.fetch_pos(0, out start, out end);
            TextIter start_iter;
            TextIter end_iter;
            message_text_view.buffer.get_iter_at_offset(out start_iter, absolute_start + start);
            message_text_view.buffer.get_iter_at_offset(out end_iter, absolute_start + end);
            message_text_view.buffer.apply_tag_by_name("url", start_iter, end_iter);
        }
    }

    private void setup_tags() {
        message_text_view.buffer.create_tag("url", underline: Pango.Underline.SINGLE, foreground: "blue");
        message_text_view.button_release_event.connect(open_url);
        message_text_view.motion_notify_event.connect(change_cursor_over_url);
    }

    private bool open_url(EventButton event_button) {
        int buffer_x, buffer_y;
        message_text_view.window_to_buffer_coords(TextWindowType.TEXT, (int) event_button.x, (int) event_button.y, out buffer_x, out buffer_y);
        TextIter iter;
        message_text_view.get_iter_at_location(out iter, buffer_x, buffer_y);
        TextIter start_iter = iter, end_iter = iter;
        if (start_iter.backward_to_tag_toggle(null) && end_iter.forward_to_tag_toggle(null)) {
            string url = start_iter.get_text(end_iter);
            try{
                AppInfo.launch_default_for_uri(url, null);
            } catch (Error err) {
                print("Tryed to open " + url);
            }
        }
        return false;
    }

    private bool change_cursor_over_url(EventMotion event_motion) {
        TextIter iter;
        message_text_view.get_iter_at_location(out iter, (int) event_motion.x, (int) event_motion.y);
        if (iter.has_tag(message_text_view.buffer.tag_table.lookup("url"))) {
            event_motion.window.set_cursor(new Cursor.for_display(get_display(), CursorType.HAND2));
        } else {
            event_motion.window.set_cursor(new Cursor.for_display(get_display(), CursorType.XTERM));
        }
        return false;
    }

    private static string get_relative_time(DateTime datetime) {
         DateTime now = new DateTime.now_local();
         TimeSpan timespan = now.difference(datetime);
         if (timespan > 365 * TimeSpan.DAY) {
             return datetime.format("%d.%m.%Y %H:%M");
         } else if (timespan > 7 * TimeSpan.DAY) {
             return datetime.format("%d.%m %H:%M");
         } else if (timespan > 1 * TimeSpan.DAY) {
             return datetime.format("%a, %H:%M");
         } else if (timespan > 9 * TimeSpan.MINUTE) {
             return datetime.format("%H:%M");
         } else if (timespan > TimeSpan.MINUTE) {
             return (timespan / TimeSpan.MINUTE).to_string() + " min ago";
         } else {
             return "Just now";
         }
    }
}

}
