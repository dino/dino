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

    construct {
        valign = Align.CENTER;
        scrolled_window.set_child(text_view);
        this.append(scrolled_window);

        var text_input_key_events = new EventControllerKey() { name = "dino-text-input-view-key-events" };
        text_input_key_events.key_pressed.connect(on_text_input_key_press);
        text_view.add_controller(text_input_key_events);

        smiley_converter = new SmileyConverter(text_view);

        scrolled_window.vadjustment.changed.connect(on_upper_notify);

        text_view.realize.connect(() => {
            var minimum_size = Requisition();
            scrolled_window.get_preferred_size(out minimum_size, null);
            vscrollbar_min_height = minimum_size.height;
        });
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
        if (keyval in new uint[]{ Key.Return, Key.KP_Enter }) {
            // Allow the text view to process the event. Needed for IME.
            if (text_view.im_context_filter_keypress(controller.get_current_event())) {
                return true;
            }

            if ((state & ModifierType.SHIFT_MASK) > 0) {
                text_view.buffer.insert_at_cursor("\n", 1);
            } else if (text_view.buffer.text.strip() != "") {
                send_text();
            }
            return true;
        }
        if (keyval == Key.Escape) {
            cancel_input();
        }
        return false;
    }
}

}
