using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class ChatTextViewController : Object {

    public signal void send_text();

    public OccupantsTabCompletor occupants_tab_completor;

    private ChatTextView widget;

    public ChatTextViewController(ChatTextView widget, StreamInteractor stream_interactor) {
        this.widget = widget;
        occupants_tab_completor = new OccupantsTabCompletor(stream_interactor, widget.text_view);

        widget.send_text.connect(() => {
            send_text();
        });
    }

    public void initialize_for_conversation(Conversation conversation) {
        occupants_tab_completor.initialize_for_conversation(conversation);
    }
}

public class ChatTextView : Box {

    public signal void send_text();
    public signal void cancel_input();

    public ScrolledWindow scrolled_window = new ScrolledWindow() { propagate_natural_height=true, max_content_height=300, hexpand=true };
    public TextView text_view = new TextView() { hexpand=true, wrap_mode=Gtk.WrapMode.WORD_CHAR, valign=Align.CENTER, margin_top=7, margin_bottom=7 };
    private int vscrollbar_min_height;
    private uint wait_queue_resize;
    private SmileyConverter smiley_converter;

    private TextTag italic_tag;
    private TextTag bold_tag;
    private TextTag strikethrough_tag;

    construct {
        valign = Align.CENTER;
        scrolled_window.set_child(text_view);
        this.append(scrolled_window);

        var text_input_key_events = new EventControllerKey() { name = "dino-text-input-view-key-events" };
        text_input_key_events.key_pressed.connect(on_text_input_key_press);
        text_view.add_controller(text_input_key_events);

        italic_tag = text_view.buffer.create_tag("italic");
        italic_tag.style = Pango.Style.ITALIC;

        bold_tag = text_view.buffer.create_tag("bold");
        bold_tag.weight = Pango.Weight.BOLD;

        strikethrough_tag = text_view.buffer.create_tag("strikethrough");
        strikethrough_tag.strikethrough = true;

        smiley_converter = new SmileyConverter(text_view);

        scrolled_window.vadjustment.changed.connect(on_upper_notify);

        text_view.remove_css_class("view");
        text_view.realize.connect(() => {
            var minimum_size = Requisition();
            scrolled_window.get_preferred_size(out minimum_size, null);
            vscrollbar_min_height = minimum_size.height;
        });
    }

    public void set_text(Message message) {
        // Get a copy of the markup spans, such that we can modify them
        var markups = new ArrayList<Xep.MessageMarkup.Span>();
        foreach (var markup in message.get_markups()) {
            markups.add(new Xep.MessageMarkup.Span() { types=markup.types, start_char=markup.start_char, end_char=markup.end_char });
        }

        text_view.buffer.text = Util.remove_fallbacks_adjust_markups(message.body, message.quoted_item_id > 0, message.get_fallbacks(), markups);

        foreach (var markup in markups) {
            foreach (var ty in markup.types) {
                TextTag tag = null;
                switch (ty) {
                    case Xep.MessageMarkup.SpanType.EMPHASIS:
                        tag = italic_tag;
                        break;
                    case Xep.MessageMarkup.SpanType.STRONG_EMPHASIS:
                        tag = bold_tag;
                        break;
                    case Xep.MessageMarkup.SpanType.DELETED:
                        tag = strikethrough_tag;
                        break;
                }
                TextIter start_selection, end_selection;
                text_view.buffer.get_iter_at_offset(out start_selection, markup.start_char);
                text_view.buffer.get_iter_at_offset(out end_selection, markup.end_char);
                text_view.buffer.apply_tag(tag, start_selection, end_selection);
            }
        }
    }

    public override void dispose() {
        base.dispose();
        if (wait_queue_resize != 0) {
            Source.remove(wait_queue_resize);
            wait_queue_resize = 0;
        }
    }

    private void on_upper_notify() {
        // hack. otherwise the textview would only show the last row(s) when entering a new row on some systems.
        scrolled_window.height_request = int.min(scrolled_window.max_content_height, (int) scrolled_window.vadjustment.upper + text_view.margin_top + text_view.margin_bottom);
        scrolled_window.vadjustment.page_size = double.min(scrolled_window.height_request - (text_view.margin_top + text_view.margin_bottom), scrolled_window.vadjustment.upper);

        // hack for vscrollbar not requiring space and making textview higher //TODO doesn't resize immediately
        scrolled_window.get_vscrollbar().visible = (scrolled_window.vadjustment.upper > scrolled_window.max_content_height - 2 * this.vscrollbar_min_height);
        start_queue_resize_if_needed();
    }

    private void start_queue_resize_if_needed() {
        if (wait_queue_resize == 0) {
            wait_queue_resize = Timeout.add(100, queue_resize_if_needed);
        }
    }

    private bool queue_resize_if_needed() {
        if (scrolled_window.get_height() == scrolled_window.height_request) {
            wait_queue_resize = 0;
            return false;
        } else {
            queue_resize();
            return true;
        }
    }

    private bool on_text_input_key_press(EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
        // Enter pressed -> Send message (except if it was Shift+Enter)
        if (keyval in new uint[]{ Key.Return, Key.KP_Enter }) {
            // Allow the text view to process the event. Needed for IME.
            if (text_view.im_context_filter_keypress(controller.get_current_event())) {
                return true;
            }

            if ((state & ModifierType.SHIFT_MASK) > 0) {
                // Let the default handler normally insert a newline if shift was hold
                return false;
            } else if (text_view.buffer.text.strip() != "") {
                send_text();
            }
            return true;
        }

        if (keyval == Key.Escape) {
            cancel_input();
        }

        // Style text section bold (CTRL + b) or italic (CTRL + i)
        if ((state & ModifierType.CONTROL_MASK) > 0) {
            if (keyval in new uint[]{ Key.i, Key.b }) {
                TextIter start_selection, end_selection;
                text_view.buffer.get_selection_bounds(out start_selection, out end_selection);

                TextTag tag = null;
                bool already_formatted = false;
                var markup_types = get_markup_types_from_iter(start_selection);
                if (keyval == Key.i) {
                    tag = italic_tag;
                    already_formatted = markup_types.contains(Xep.MessageMarkup.SpanType.EMPHASIS);
                } else if (keyval == Key.b) {
                    tag = bold_tag;
                    already_formatted = markup_types.contains(Xep.MessageMarkup.SpanType.STRONG_EMPHASIS);
                } else if (keyval == Key.s) {
                    tag = strikethrough_tag;
                    already_formatted = markup_types.contains(Xep.MessageMarkup.SpanType.DELETED);
                }
                if (tag != null) {
                    if (already_formatted) {
                        text_view.buffer.remove_tag(tag, start_selection, end_selection);
                    } else {
                        text_view.buffer.apply_tag(tag, start_selection, end_selection);
                    }
                }
            }
        }

        return false;
    }

    public Gee.List<Xep.MessageMarkup.Span> get_markups() {
        var markups = new HashMap<Xep.MessageMarkup.SpanType, Xep.MessageMarkup.SpanType>();
        markups[Xep.MessageMarkup.SpanType.EMPHASIS] = Xep.MessageMarkup.SpanType.EMPHASIS;
        markups[Xep.MessageMarkup.SpanType.STRONG_EMPHASIS] = Xep.MessageMarkup.SpanType.STRONG_EMPHASIS;
        markups[Xep.MessageMarkup.SpanType.DELETED] = Xep.MessageMarkup.SpanType.DELETED;

        var ended_groups = new ArrayList<Xep.MessageMarkup.Span>();
        Xep.MessageMarkup.Span current_span = null;

        TextIter iter;
        text_view.buffer.get_start_iter(out iter);
        int i = 0;
        do {
            var char_markups = get_markup_types_from_iter(iter);

            // Not the same set of markups as last character -> end all spans
            if (current_span != null && (!char_markups.contains_all(current_span.types) || !current_span.types.contains_all(char_markups))) {
                ended_groups.add(current_span);
                current_span = null;
            }

            if (char_markups.size > 0) {
                if (current_span == null) {
                    current_span = new Xep.MessageMarkup.Span() { types=char_markups, start_char=i, end_char=i + 1 };
                } else {
                    current_span.end_char = i + 1;
                }
            }

            i++;
        } while (iter.forward_char());

        if (current_span != null) {
            ended_groups.add(current_span);
        }

        return ended_groups;
    }

    private Gee.List<Xep.MessageMarkup.SpanType> get_markup_types_from_iter(TextIter iter) {
        var ret = new ArrayList<Xep.MessageMarkup.SpanType>();

        foreach (TextTag tag in iter.get_tags()) {
            if (tag.style == Pango.Style.ITALIC) {
                ret.add(Xep.MessageMarkup.SpanType.EMPHASIS);
            } else if (tag.weight == Pango.Weight.BOLD) {
                ret.add(Xep.MessageMarkup.SpanType.STRONG_EMPHASIS);
            } else if (tag.strikethrough) {
                ret.add(Xep.MessageMarkup.SpanType.DELETED);
            }
        }
        return ret;
    }
}

}
