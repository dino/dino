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

public class ChatTextView : ScrolledWindow {

    public signal void send_text();
    public signal void cancel_input();

    public TextView text_view = new TextView() { can_focus=true, hexpand=true, wrap_mode=Gtk.WrapMode.WORD_CHAR, valign=Align.CENTER, visible=true };
    // Hack to prevent the ChatTextView from increasing in height after text was entered
    private Label zero_width_label_hack = new Label("​") { hexpand=false, valign=Align.CENTER, opacity=0, visible=true };
    private int vscrollbar_min_height;
    private SmileyConverter smiley_converter;
    public EditHistory edit_history;
    private SpellChecker spell_checker;

    construct {
        max_content_height = 300;
        propagate_natural_height = true;
        Box box = new Box(Orientation.HORIZONTAL, 0) { hexpand=true, margin=8, valign=Align.CENTER, visible=true };
        box.add(text_view);
        box.add(zero_width_label_hack);
        this.add(box);

        smiley_converter = new SmileyConverter(text_view);
        edit_history = new EditHistory(text_view);
        spell_checker = new SpellChecker(text_view);

        this.get_vscrollbar().get_preferred_height(out vscrollbar_min_height, null);
        this.vadjustment.notify["upper"].connect_after(on_upper_notify);
        text_view.key_press_event.connect(on_text_input_key_press);

        Gtk.drag_dest_unset(text_view);
    }

    public void initialize_for_conversation(Conversation conversation) {
        edit_history.initialize_for_conversation(conversation);
        spell_checker.initialize_for_conversation(conversation);
    }

    public override void get_preferred_height(out int min_height, out int nat_height) {
        base.get_preferred_height(out min_height, out nat_height);
        min_height = nat_height;
    }

    private void on_upper_notify() {
        this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;

        // hack for vscrollbar not requiring space and making textview higher //TODO doesn't resize immediately
        this.get_vscrollbar().visible = (this.vadjustment.upper > this.max_content_height - 2 * this.vscrollbar_min_height);
    }

    private bool on_text_input_key_press(EventKey event) {
        if (event.keyval in new uint[]{Key.Return, Key.KP_Enter}) {
            if ((event.state & ModifierType.SHIFT_MASK) > 0) {
                text_view.buffer.insert_at_cursor("\n", 1);
            } else if (text_view.buffer.text.strip() != "") {
                send_text();
                edit_history.reset_history();
            }
            return true;
        }
        if (event.keyval == Key.Escape) {
            cancel_input();
        }
        return false;
    }
}

}
