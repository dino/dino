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
        widget.initialize_for_conversation(conversation);
    }
}

public class ChatTextView : Box {

    public signal void send_text();
    public signal void cancel_input();

    public ScrolledWindow scrolled_window = new ScrolledWindow() { propagate_natural_height=true, max_content_height=300 };
    public TextView text_view = new TextView() { hexpand=true, wrap_mode=Gtk.WrapMode.WORD_CHAR, valign=Align.CENTER, margin_top=7, margin_bottom=7 };
    private int vscrollbar_min_height;
    private SmileyConverter smiley_converter;
//    private SpellChecker spell_checker;

    construct {
        scrolled_window.set_child(text_view);
        this.append(scrolled_window);

        smiley_converter = new SmileyConverter(text_view);

//        scrolled_window.get_vscrollbar().get_preferred_size(out vscrollbar_min_size, null);
        scrolled_window.vadjustment.notify["upper"].connect(on_upper_notify);

        var text_input_key_events = new EventControllerKey();
        text_input_key_events.key_pressed.connect(on_text_input_key_press);
        text_view.add_controller(text_input_key_events);

        text_view.realize.connect(() => {
            var minimum_size = new Requisition();
            scrolled_window.get_preferred_size(out minimum_size, null);
            vscrollbar_min_height = minimum_size.height;
        });
//        Gtk.drag_dest_unset(text_view);
    }

    public void initialize_for_conversation(Conversation conversation) {
//        spell_checker.initialize_for_conversation(conversation);
    }

//    public override void get_preferred_size(out Gtk.Requisition minimum_size, out Gtk.Requisition natural_size) {
//        base.get_preferred_height(out min_height, out nat_height);
//        min_height = nat_height;
//    }

    private void on_upper_notify() {
        scrolled_window.vadjustment.value = scrolled_window.vadjustment.upper - scrolled_window.vadjustment.page_size;

        // hack for vscrollbar not requiring space and making textview higher //TODO doesn't resize immediately
        scrolled_window.get_vscrollbar().visible = (scrolled_window.vadjustment.upper > scrolled_window.max_content_height - 2 * this.vscrollbar_min_height);
    }

    private bool on_text_input_key_press(uint keyval, uint keycode, Gdk.ModifierType state) {
        if (keyval in new uint[]{ Key.Return, Key.KP_Enter }) {
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
