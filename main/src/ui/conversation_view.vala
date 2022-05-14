using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Widget {

//    [GtkChild] public unowned ScrolledWindow conversation_scrolled;
    [GtkChild] public unowned Overlay overlay;
    [GtkChild] public unowned Revealer goto_end_revealer;
    [GtkChild] public unowned Button goto_end_button;
    [GtkChild] public unowned ChatInput.View chat_input;
    [GtkChild] public unowned ConversationSummary.ConversationView conversation_frame;
    [GtkChild] public unowned Revealer white_revealer;

    public ListView list_view = new ListView(null, null);

    public bool at_current_content = true;

    construct {
        this.layout_manager = new BinLayout();
        white_revealer.notify["child-revealed"].connect_after(on_child_revealed_changed);

//        conversation_scrolled.set_child(list_view);
//        list_view.set_factory(get_item_factory());

//        conversation_scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
//        conversation_scrolled.vadjustment.notify["value"].connect(on_value_notify);

    }

    public void add_overlay_dialog(Widget widget) {
        Revealer revealer = new Revealer() { transition_type=RevealerTransitionType.CROSSFADE , transition_duration= 100 };
        revealer.set_child(widget);

        overlay.add_overlay(revealer);

        revealer.reveal_child = true;
        white_revealer.visible = true;
        white_revealer.reveal_child = true;
        widget.destroy.connect(() => {
            overlay.remove_overlay(revealer);
            white_revealer.reveal_child = false;
            chat_input.do_focus();
        });
    }

    private void on_child_revealed_changed() {
        if (!white_revealer.child_revealed) {
            white_revealer.visible = false;
        }
    }

    public override void dispose() {
        // To prevent a warning when closing Dino
        // "Can't set a target list on a widget until you've called gtk_drag_dest_set() to make the widget into a drag destination"
//        Gtk.drag_dest_unset(this);
    }

    private void on_upper_notify() {
        print("on_upper_notify\n");
        if (at_current_content) {
            print("on_upper_notify2\n");
            // scroll down
//            conversation_scrolled.vadjustment.value = conversation_scrolled.vadjustment.upper - conversation_scrolled.vadjustment.page_size;
//            conversation_scrolled.scroll_child(ScrollType.END, false);
        }
    }

    private void on_value_notify() {
        print("on_value_notify\n");
//        at_current_content = false;
    }
}

}
