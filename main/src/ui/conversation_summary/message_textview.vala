using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class MessageTextView : TextView {

    private TextTag link_tag;

    public MessageTextView() {
        Object(editable:false, hexpand:true, wrap_mode:WrapMode.WORD_CHAR);

        link_tag = buffer.create_tag("url", underline: Pango.Underline.SINGLE, foreground: "blue");
        button_release_event.connect(open_url);
        motion_notify_event.connect(change_cursor_over_url);

        update_display_style();
        Util.force_base_background(this, "textview, text:not(:selected)");
        style_updated.connect(update_display_style);
    }

    // Workaround GTK TextView issues
    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width(out minimum_width, out natural_width);
        minimum_width = 0;
    }

    public void add_text(string text_) {
        string text = text_;
        if (text.length > 10000) {
            text = text.slice(0, 10000) + " [" + _("Message too long") + "]";
        }
        TextIter end;
        buffer.get_end_iter(out end);
        buffer.insert(ref end, text, -1);
        format_suffix_urls(text);
    }

    private void update_display_style() {
        LinkButton lnk = new LinkButton("http://example.com");
        RGBA link_color = lnk.get_style_context().get_color(StateFlags.LINK);
        link_tag.foreground_rgba = link_color;
    }

    private void format_suffix_urls(string text) {
        int absolute_start = buffer.text.char_count() - text.char_count();

        Regex url_regex = new Regex("""(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))""");
        MatchInfo match_info;
        url_regex.match(text, 0, out match_info);
        for (; match_info.matches(); match_info.next()) {
            string? url = match_info.fetch(0);
            int start;
            int end;
            match_info.fetch_pos(0, out start, out end);
            start = text[0:start].char_count();
            end = text[0:end].char_count();
            TextIter start_iter;
            TextIter end_iter;
            buffer.get_iter_at_offset(out start_iter, absolute_start + start);
            buffer.get_iter_at_offset(out end_iter, absolute_start + end);
            buffer.apply_tag_by_name("url", start_iter, end_iter);
        }
    }

    private bool open_url(EventButton event_button) {
        int buffer_x, buffer_y;
        window_to_buffer_coords(TextWindowType.TEXT, (int) event_button.x, (int) event_button.y, out buffer_x, out buffer_y);
        TextIter iter;
        get_iter_at_location(out iter, buffer_x, buffer_y);
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
        get_iter_at_location(out iter, (int) event_motion.x, (int) event_motion.y);
        if (iter.has_tag(buffer.tag_table.lookup("url"))) {
            event_motion.window.set_cursor(new Cursor.for_display(get_display(), CursorType.HAND2));
        } else {
            event_motion.window.set_cursor(new Cursor.for_display(get_display(), CursorType.XTERM));
        }
        return false;
    }
}

}
